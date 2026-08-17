#' Read translations from a directory
#'
#' Reads a translation module's `.yaml` files into the same list structure the
#' runtime uses.
#'
#' @param dir Directory of translation `.yaml` files (a module's
#'   `inst/translations`).
#' @return A named list of translations, one element per help topic.
#' @export
read_translations <- function(dir = "inst/translations") {
  files <- list.files(dir, pattern = "\\.yaml$", full.names = TRUE)
  translations <- lapply(files, rd_flat_read)
  names(translations) <- tools::file_path_sans_ext(basename(files))
  translations
}

# Read one flattened-Rd translation file, moving the list of untranslatable
# section names into an attribute (mirrors the module template's own loader).
rd_flat_read <- function(file) {
  rd_flat <- yaml::read_yaml(file)
  attr(rd_flat, "untranslatable") <- rd_flat[["untranslatable"]]
  rd_flat[["untranslatable"]] <- NULL
  rd_flat
}
