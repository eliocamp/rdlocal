#' Creates templates for translation
#'
#' Grabs .Rd files and creates yaml templates to then translate.
#'
#' @param rd_files character vector of rd files.
#' @param folder folder where to save the templates. Will be created if it
#' doesn't exist.
#' @param macros a set of macros definitions.
#'
#' @examples
#' rd_files <- system.file("extdata", "periodic.Rd", package = "rdlocal")
#' template_folder <- tempdir()
#' i18n_translation_templates(rd_files, template_folder)
#'
#' @export
i18n_translation_templates <- function(rd_files, folder, macros = NULL) {
  invalid_files <- !file.exists(rd_files)
  if (any(invalid_files)) {
    stop("Some files don't exist")
  }

  macros <- macros %||% default_macros()

  dir.create(folder, showWarnings = FALSE, recursive = TRUE)

  base_names <- tools::file_path_sans_ext(basename(rd_files))
  template_files <- file.path(folder, paste0(base_names, ".yaml"))

  mapply(i18n_translation_template, rd_files,  template_files, MoreArgs = list(macros = macros))
}

default_macros <- function() file.path(R.home("share"), "Rd", "macros", "system.Rd")

i18n_translation_template <- function(rd_file, template_file,
                                      macros = default_macros()) {
  rd_parsed <- tools::parse_Rd(rd_file, macros = macros)
  rd_flatten <- rd_flatten(rd_parsed)
  rd_flat_write(rd_flatten, template_file)
  template_file
}

