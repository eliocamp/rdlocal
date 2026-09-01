rd_flat_read <- function(file) {
  rd_flat <- yaml::read_yaml(file)
  attr(rd_flat, "untranslatable") <- rd_flat[["untranslatable"]]
  rd_flat[["untranslatable"]] <- NULL
  rd_flat
}


#' @export
translations <- NULL

# Loaded from inst/translations/*.yaml -- a standard, install-safe location, so
# every field (including `fuzzy` flags) survives installation. A top-level
# translations/ directory would be stripped as non-standard on install.
.onLoad <- function(libname, pkgname) {
  dir <- system.file("translations", package = pkgname)
  if (!nzchar(dir)) {
    return(invisible())
  }
  files <- list.files(dir, pattern = "\\.yaml$", full.names = TRUE)
  tr <- lapply(files, rd_flat_read)
  names(tr) <- tools::file_path_sans_ext(basename(files))
  utils::assignInMyNamespace("translations", tr)
}
