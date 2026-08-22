#' Returns matching languages
#'
#' @param languages a character vector of languages.
#' @param target_language a single character string with the desired language.
#'
#' @returns a logical vector of the same length as `languages` indicating which
#' language is a match for the target_language
#'
#' @details
#' This should take into account the ISO hierarchy.
#' i.e.: if target_language is "es_AR", then "es" is good, but "es_AR" is better.
#' if target language is "es", then "es_AR" is also good.
#'
#' Right now it returns `TRUE` for exact matches only and if there are no matches,
#' it returns `TRUE` for elements in `language` that have the same root language
#' as `target_language`. So if `target_language` is `"es_AR"`, then `"es_UY"`,
#' `"es_ES"` and `"es"` will all return `TRUE`.
#'
## Issue: https://github.com/eliocamp/rdlocal/issues/9
#' @keywords internal
resolve_lang <- function(languages, target_language) {

  # Apparently sometimes LANGUAGE has many languages divided by : (for example,
  # mine says "en_AU:en"). Just keep the first one.
  target_language <- strsplit(target_language, ":")[[1]][[1]]
  languages <- vapply(strsplit(languages, split = ":"),
                      FUN = function(x) x[[1]],
                      FUN.VALUE = character(1))


  exact_match <- languages == target_language

  if (any(exact_match)) {
    return(exact_match)
  }

  # Keep only the top-level language specification ("en" in "en_US")
  # for both available and target languages
  languages <- vapply(strsplit(languages, "_"), function(x) x[[1]], character(1))
  target_language <- strsplit(target_language, "_")[[1]][[1]]

  languages == target_language
}
