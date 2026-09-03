#' Create a translation module from a local source package
#'
#' Creates a translation module from a source package. The `original` strings are
#' *scaffolds*: dynamic install/build `\Sexpr` (and `#ifdef`/`#ifndef`) spans are
#' replaced by `{ISEXPR_i}` placeholders, so a human's translation keeps matching
#' the installed help across reinstalls (an install-stage `\Sexpr` bakes a
#' different value each install, which a plain exact-string template can never
#' match). The translator fills in the `translation:` fields and leaves the
#' `{ISEXPR_i}` tokens in place. Each section also carries a `spans:` map showing
#' an example of what each token held at generation time (the real value differs
#' per install), so the translator knows what a `{ISEXPR_i}` stands for.
#'
#' Building the scaffolds needs both the *source* Rd (dynamic nodes still live)
#' and the *baked* Rd (values resolved). The source is taken from `package_path`;
#' the baked tree is obtained by installing that source into a temporary library
#' and reading its `Rd_db`.
#'
#' If a topic cannot be scaffolded because its source and installed help do not
#' align, it falls back to a plain template (the flattened source, no
#' placeholders) marked `needs_review: yes`. Topics missing from the installed
#' help, or whose source cannot be parsed, are omitted. Either way the affected
#' topics are listed in a `warning()`, so the skeleton is never silently left
#' incomplete.
#'
#' @param package_path Path to the local source package to translate.
#' @param language Language code, e.g. `"es"`.
#' @param module_name Module package name. Defaults to `<package>.<language>`,
#'   with non-alphanumerics in `language` collapsed to `"."` (so `"en-GB"` gives
#'   `pkg.en.GB`); the real tag is kept in the module's `Language:` field.
#' @param module_path Directory to create the module in.
#' @param rstudio_project Whether to create an `.Rproj` file.
#'
#' @return (invisibly) the module path.
#' @export
i18n_module_create <- function(
  package_path,
  language,
  module_name = NULL,
  module_path = file.path(".", module_name),
  rstudio_project = TRUE
) {
  package <- get_package_name(package_path)
  version <- get_package_version(package_path)

  if (is.null(module_name)) {
    module_name <- paste(
      package,
      gsub("[^[:alnum:]]+", ".", language),
      sep = "."
    )
  }
  if (!valid_package_name(module_name)) {
    stop(module_name, " is not a valid package name")
  }

  copy_pkg_template(
    module_path,
    rstudio_project = if (isTRUE(rstudio_project)) module_name else NULL
  )
  
  license <- get_package_license(package_path)
  copy_license_file(package_path, module_path)
  
  modify_description(
    module_path,
    module_name = module_name,
    package = package,
    version = version,
    language = language,
    license = license
  )

  macros <- tools::loadPkgRdMacros(package_path)
  rd_files <- list.files(
    file.path(package_path, "man"),
    pattern = "\\.Rd$",
    full.names = TRUE
  )
  tdir <- file.path(module_path, "inst", "translations")
  mdir <- file.path(module_path, "man_original")
  dir.create(tdir, showWarnings = FALSE, recursive = TRUE)
  dir.create(mdir, showWarnings = FALSE, recursive = TRUE)

  # Baked Rd tree: install the local source into a throwaway library so its
  # build/install-stage \Sexpr are resolved, then read its Rd_db.
  baked <- baked_rd_db(package_path, package)

  omitted <- character(0) # topic -> why no template could be written
  review <- character(0) # topics that fell back to a plain template

  for (rd_file in rd_files) {
    topic <- basename(rd_file)
    out_yaml <- file.path(
      tdir,
      paste0(tools::file_path_sans_ext(topic), ".yaml")
    )

    if (is.null(baked[[topic]])) {
      omitted[topic] <- "not present in the installed package"
      next
    }
    src_rd <- tryCatch(
      tools::parse_Rd(rd_file, macros = macros),
      error = function(e) conditionMessage(e)
    )
    if (is.character(src_rd)) {
      omitted[topic] <- paste0("source Rd could not be parsed (", src_rd, ")")
      next
    }
    sca <- tryCatch(
      detect_scaffolds(src_rd, baked[[topic]]),
      error = function(e) conditionMessage(e)
    )

    if (is.character(sca)) {
      # Source and installed help could not be aligned: fall back to a plain
      # template (flattened source, no placeholders) flagged for manual review.
      write_plain_template(rd_file, out_yaml, macros)
      review <- c(review, topic)
    } else if (length(sca) == 0) {
      next # nothing translatable on this page (e.g. metadata-only): skip quietly
    } else {
      yaml::write_yaml(scaffold_template(sca), out_yaml)
    }
    file.copy(rd_file, file.path(mdir, topic), overwrite = TRUE)
  }

  report_incomplete(review, omitted, length(rd_files))
  invisible(module_path)
}

# Plain (non-scaffolded) template for a topic the scaffolder could not align: the
# flattened source verbatim, with a top-level `needs_review` flag. Dynamic \Sexpr
# are left as raw source text, so the translator resolves them by hand. The flag
# is ignored by the runtime (it is not an Rd section).
write_plain_template <- function(rd_file, out_yaml, macros) {
  i18n_translation_template(rd_file, out_yaml, macros = macros)
  content <- yaml::read_yaml(out_yaml)
  yaml::write_yaml(c(list(needs_review = TRUE), content), out_yaml)
}

# Warn once about topics that fell back or were omitted, so an incomplete
# skeleton is never silent.
report_incomplete <- function(review, omitted, total) {
  parts <- character(0)
  if (length(review)) {
    parts <- c(
      parts,
      sprintf(
        "%d of %d topic(s) could not be scaffolded; a plain template (needs_review) was written for: %s",
        length(review),
        total,
        paste(review, collapse = ", ")
      )
    )
  }
  if (length(omitted)) {
    parts <- c(
      parts,
      sprintf("%d topic(s) omitted:", length(omitted)),
      paste0("  - ", names(omitted), ": ", omitted)
    )
  }
  if (length(parts)) warning(paste(parts, collapse = "\n"), call. = FALSE)
}

# Install a local source package into a throwaway library (under tempdir(), which
# the session cleans up) and return its Rd_db (build/install \Sexpr resolved).
baked_rd_db <- function(package_path, package) {
  # this is not great for packages with lots of dependencies
  lib <- tempfile("i18nlib")
  dir.create(lib)

  old_libpaths <- .libPaths()
  .libPaths(c(lib, old_libpaths), include.site = FALSE)

  on.exit(
    .libPaths(old_libpaths, include.site = FALSE)
  )

  remotes::install_local(
    path = package_path,
    force = TRUE,
    lib = lib,
    upgrade = "never"
  )
  tools::Rd_db(package, lib.loc = lib)
}

# detect_scaffolds() output -> the per-topic template structure:
#   section -> { original = <scaffold>, translation = ~,
#                spans = { i: <example baked value> } [, ifdef = { i: "" } ] }
# recursing into \arguments (a named list of per-item entries). `spans` shows the
# translator what each {ISEXPR_i} held at generation time; a blank `ifdef`
# side-table is emitted for any section that has #ifdef spans, to fill per branch.
scaffold_template <- function(sca) {
  conv1 <- function(node) {
    entry <- list(original = node$scaffold, translation = NULL)
    # Show translators what each {ISEXPR_i} stands for: an example of the value
    # baked at generation time (the real value differs per install). Keyed by
    # token index, mirroring the ifdef side-table below.
    if (length(node$spans)) {
      entry$spans <- stats::setNames(
        lapply(node$spans, function(s) s$baked_value),
        vapply(node$spans, function(s) as.character(s$i), character(1))
      )
    }
    ifdef_i <- unlist(lapply(node$spans, function(s) {
      if (identical(s$kind, "ifdef")) s$i else NULL
    }))
    if (length(ifdef_i)) {
      entry$ifdef <- stats::setNames(
        as.list(rep("", length(ifdef_i))),
        as.character(ifdef_i)
      )
    }
    entry
  }
  out <- list()
  for (sec in names(sca)) {
    x <- sca[[sec]]
    if (!is.null(x$scaffold)) {
      out[[sec]] <- conv1(x)
    } else {
      items <- list()
      for (nm in names(x)) {
        items[[nm]] <- conv1(x[[nm]])
      }
      out[[sec]] <- items
    }
  }
  out
}

get_package_name <- function(package_path) {
  description_file <- file.path(package_path, "DESCRIPTION")
  read.dcf(description_file, fields = "Package")[[1]]
}

get_package_version <- function(package_path) {
  description_file <- file.path(package_path, "DESCRIPTION")
  read.dcf(description_file, fields = "Version")[[1]]
}

copy_pkg_template <- function(path, rstudio_project = TRUE) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  empty <- length(list.files(path)) == 0
  if (!empty) {
    stop("Path to module exists and it's not empty.")
  }

  skeleton <- system.file(
    "extdata",
    "translation_skeleton",
    package = "rdlocal"
  ) |>
    list.files(full.names = TRUE) |>
    file.copy(path, recursive = TRUE)

  if (is.null(rstudio_project)) {
    file.remove(file.path(path, "skeleton.Rproj"))
  } else {
    file.rename(
      file.path(path, "skeleton.Rproj"),
      file.path(path, paste0(rstudio_project, ".Rproj"))
    )
  }
  file.rename(file.path(path, "Rbuildignore"), file.path(path, ".Rbuildignore"))
  return(path)
}


modify_description <- function(path, module_name, package, version, language,
                              license = NULL) {
  description_file <- file.path(path, "DESCRIPTION")
  description_template <- paste0(readLines(description_file), collapse = "\n")

  description_text <- whisker::whisker.render(
    description_template,
    data = list(
      module_name = module_name,
      package_version = paste0(package, " (== ", version, ")"),
      language = language,
      license = license
    )
  )
  writeLines(description_text, description_file)
}

get_package_license <- function(package_path) {
  description_file <- file.path(package_path, "DESCRIPTION")
  tryCatch(
    read.dcf(description_file, fields = "License")[[1]],
    error = function(e) NULL
  )
}

copy_license_file <- function(package_path, module_path) {
  license_files <- c("LICENSE", "LICENSE.md", "LICENSE.txt", "LICENCE", "LICENCE.md")
  
  for (file in license_files) {
    src_file <- file.path(package_path, file)
    if (file.exists(src_file)) {
      dest_file <- file.path(module_path, file)
      file.copy(src_file, dest_file, overwrite = TRUE)
      return(invisible(TRUE))
    }
  }
  invisible(FALSE)
}

valid_package_name <- function(x) {
  grepl(paste0("^(", .standard_regexps()$valid_package_name, ")$"), x)
}
