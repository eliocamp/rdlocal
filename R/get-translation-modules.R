#' Gets translation modules
#'
#' Lists the package names of modules that translates a particular package
#' to a particular language
#'
#' @param package character string with the name of the package
#' @param language character string with the language
#' @keywords internal
get_translation_modules <- function(package, language) {
  stopifnot(!missing(package))
  stopifnot(length(language) == 1)
  stopifnot(length(package) == 1)

  # Get all translation modules
  installed <- utils::installed.packages(fields = c("Translates", "Language"))

  translations <- installed[!is.na(installed[, "Translates"]), , drop = FALSE]

  if (length(translations) == 0) {
    return(NULL)
  }

  # Filter for the language
  translations <- translations[
    resolve_lang(translations[, "Language"], language),
    ,
    drop = FALSE
  ]

  if (length(translations) == 0) {
    return(NULL)
  }

  # Filter for the package
  modules <- character(0)
  for (i in seq_len(nrow(translations))) {
    translates <- pkgload::parse_deps(translations[i, "Translates"])[["name"]]
    if (translates == package) {
      modules <- c(modules, translations[i, "Package"])
    }
  }

  return(modules)
}
