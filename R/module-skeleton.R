#' Create a scaffolded translation-module skeleton from a local source package
#'
#' Like [i18n_module_create()], but the `original` strings are *scaffolds*:
#' dynamic install/build `\Sexpr` (and `#ifdef`/`#ifndef`) spans are replaced by
#' `{ISEXPR_i}` placeholders, so a human's translation keeps matching the
#' installed help across reinstalls (an install-stage `\Sexpr` bakes a different
#' value each install, which the plain [i18n_module_create()] template can never
#' match). The translator fills in the `translation:` fields and leaves the
#' `{ISEXPR_i}` tokens in place. Each section also carries a `spans:` map showing
#' an example of what each token held at generation time (the real value differs
#' per install), so the translator knows what a `{ISEXPR_i}` stands for.
#'
#' Locating the spans needs both the *source* Rd (dynamic nodes still live) and
#' the *baked* Rd (values resolved). The source is taken from `package_path`; the
#' baked tree is obtained by installing that source into a temporary library and
#' reading its `Rd_db`, then removing the temporary library.
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
#' @seealso [i18n_module_create()]
#' @export
i18n_module_skeleton <- function(package_path, language, module_name = NULL,
                                 module_path = file.path(".", module_name),
                                 rstudio_project = TRUE) {
  package <- get_package_name(package_path)
  version <- get_package_version(package_path)

  if (is.null(module_name)) {
    module_name <- paste(package, gsub("[^[:alnum:]]+", ".", language), sep = ".")
  }
  if (!valid_package_name(module_name)) {
    stop(module_name, " is not a valid package name")
  }

  # Baked Rd tree: install the local source into a throwaway library so its
  # build/install-stage \Sexpr are resolved, read Rd_db, then remove the library.
  baked <- baked_rd_db(package_path, package)
  on.exit(unlink(attr(baked, "lib"), recursive = TRUE), add = TRUE)

  # Module shell: reuse the existing template + DESCRIPTION machinery.
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

# Install a local source package into a throwaway library and return its Rd_db
# (build/install \Sexpr resolved). The library path is stashed on attr "lib" for
# the caller to unlink.
baked_rd_db <- function(package_path, package) {
  lib <- tempfile("i18nlib")
  dir.create(lib)
  utils::install.packages(package_path, repos = NULL, type = "source",
                          lib = lib, quiet = TRUE)
  db <- tools::Rd_db(package, lib.loc = lib)
  attr(db, "lib") <- lib
  db
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
