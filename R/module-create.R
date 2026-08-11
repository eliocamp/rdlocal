#' Create a translation module from a local source package
#'
#' Creates a translation module from a source package. By default
#' (`scaffold = TRUE`) the `original` strings are *scaffolds*: dynamic
#' install/build `\Sexpr` (and `#ifdef`/`#ifndef`) spans are replaced by
#' `{ISEXPR_i}` placeholders, so a human's translation keeps matching the
#' installed help across reinstalls (an install-stage `\Sexpr` bakes a different
#' value each install, which a plain exact-string template can never match). The
#' translator fills in the `translation:` fields and leaves the `{ISEXPR_i}`
#' tokens in place. Each section also carries a `spans:` map showing an example of
#' what each token held at generation time (the real value differs per install),
#' so the translator knows what a `{ISEXPR_i}` stands for.
#'
#' Locating the spans needs both the *source* Rd (dynamic nodes still live) and
#' the *baked* Rd (values resolved). The source is taken from `package_path`; the
#' baked tree is obtained by installing that source into a temporary library and
#' reading its `Rd_db`, then removing the temporary library.
#'
#' With `scaffold = FALSE` the `original` strings are instead the flattened
#' *source* Rd verbatim (no placeholders, and no temporary install) -- the legacy
#' exact-string behaviour. Such a template only matches fully-static help pages at
#' runtime, because an unresolved dynamic `\Sexpr` in the stored string can never
#' equal the installed (baked) help.
#'
#' @param package_path Path to the local source package to translate.
#' @param language Language code, e.g. `"es"`.
#' @param module_name Module package name. Defaults to `<package>.<language>`,
#'   with non-alphanumerics in `language` collapsed to `"."` (so `"en-GB"` gives
#'   `pkg.en.GB`); the real tag is kept in the module's `Language:` field.
#' @param module_path Directory to create the module in.
#' @param scaffold If `TRUE` (default), dynamic spans become `{ISEXPR_i}`
#'   placeholders via a source<->installed diff (which briefly installs the
#'   package into a temporary library). If `FALSE`, emit legacy flat templates
#'   (exact source strings, no placeholders, no temporary install).
#' @param rstudio_project Whether to create an `.Rproj` file.
#'
#' @return (invisibly) the module path.
#' @export
i18n_module_create <- function(package_path, language, module_name = NULL,
                               module_path = file.path(".", module_name),
                               scaffold = TRUE,
                               rstudio_project = TRUE) {
  package <- get_package_name(package_path)
  version <- get_package_version(package_path)

  if (is.null(module_name)) {
    module_name <- paste(package, gsub("[^[:alnum:]]+", ".", language), sep = ".")
  }
  if (!valid_package_name(module_name)) {
    stop(module_name, " is not a valid package name")
  }

  copy_pkg_template(module_path,
                    rstudio_project = if (isTRUE(rstudio_project)) module_name else NULL)
  modify_description(module_path, module_name = module_name, package = package,
                     version = version, language = language)

  macros   <- tools::loadPkgRdMacros(package_path)
  rd_files <- list.files(file.path(package_path, "man"), pattern = "\\.Rd$", full.names = TRUE)
  tdir     <- file.path(module_path, "translations")
  mdir     <- file.path(module_path, "man_original")
  dir.create(tdir, showWarnings = FALSE, recursive = TRUE)
  dir.create(mdir, showWarnings = FALSE, recursive = TRUE)

  if (!isTRUE(scaffold)) {
    # Legacy path: flatten the source Rd to exact strings, no source<->baked diff
    # and no temporary install. Emits one plain template per page + originals.
    i18n_translation_templates(rd_files, tdir, macros = macros)
    for (rd_file in rd_files) {
      file.copy(rd_file, file.path(mdir, basename(rd_file)), overwrite = TRUE)
    }
    return(invisible(module_path))
  }

  # Baked Rd tree: install the local source into a throwaway library so its
  # build/install-stage \Sexpr are resolved, then read its Rd_db.
  baked <- baked_rd_db(package_path, package)

  for (rd_file in rd_files) {
    topic <- basename(rd_file)
    if (is.null(baked[[topic]])) next
    src_rd <- tryCatch(tools::parse_Rd(rd_file, macros = macros), error = function(e) NULL)
    if (is.null(src_rd)) next
    sca <- tryCatch(detect_scaffolds(src_rd, baked[[topic]]), error = function(e) NULL)
    if (is.null(sca) || length(sca) == 0) next
    yaml::write_yaml(scaffold_template(sca),
                     file.path(tdir, paste0(tools::file_path_sans_ext(topic), ".yaml")))
    file.copy(rd_file, file.path(mdir, topic), overwrite = TRUE)
  }

  invisible(module_path)
}

# Install a local source package into a throwaway library (under tempdir(), which
# the session cleans up) and return its Rd_db (build/install \Sexpr resolved).
baked_rd_db <- function(package_path, package) {
  lib <- tempfile("i18nlib")
  dir.create(lib)
  utils::install.packages(package_path, repos = NULL, type = "source",
                          lib = lib, quiet = TRUE)
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
        vapply(node$spans, function(s) as.character(s$i), character(1)))
    }
    ifdef_i <- unlist(lapply(node$spans, function(s)
      if (identical(s$kind, "ifdef")) s$i else NULL))
    if (length(ifdef_i)) {
      entry$ifdef <- stats::setNames(as.list(rep("", length(ifdef_i))),
                                     as.character(ifdef_i))
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
      for (nm in names(x)) items[[nm]] <- conv1(x[[nm]])
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

  skeleton <- system.file("extdata", "translation_skeleton", package = "rhelpi18n") |>
    list.files(full.names = TRUE) |>
    file.copy(path, recursive = TRUE)

  if (is.null(rstudio_project)) {
    file.remove(file.path(path, "skeleton.Rproj"))
  } else {
    file.rename(file.path(path, "skeleton.Rproj"),
                file.path(path, paste0(rstudio_project, ".Rproj")))
  }
  return(path)
}


modify_description <- function(path, module_name, package, version, language) {
  description_file <- file.path(path, "DESCRIPTION")
  description_template <- paste0(readLines(description_file), collapse = "\n")

  description_text <- whisker::whisker.render(description_template, data = list(
    module_name = module_name,
    package_version = paste0(package, " (== ", version, ")"),
    language = language
  ))
  writeLines(description_text, description_file)
}

valid_package_name <- function(x) {
  grepl(paste0("^(", .standard_regexps()$valid_package_name, ")$"), x)
}
