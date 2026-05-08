#' Gets translation modules
#'
#' Lists the package names of modules that translates a particular package
#' to a particular language
#'
#' @param package character string with the name of the package
#' @param language character string with the language
#' @keywords internal
get_translation_modules <- function(package, language = Sys.getenv("LANGUAGE", "en")) {
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
  translations <- translations[resolve_lang(translations[, "Language"], language), , drop = FALSE]

  if (length(translations) == 0) {
    return(NULL)
  }

  # Filter for the package
  modules <- character(0)
  for (i in seq_len(nrow(translations))) {
    translates <- parse_deps(translations[i, "Translates"])[["name"]]
    if (translates == package) {
      modules <- c(modules, translations[i, "Package"])
    }
  }

  return(modules)
}


# from pkgload
parse_deps <- function (string) {
  if (is.null(string)) {
    return()
  }
  stopifnot(is.character(string))
  if (grepl("^\\s*$", string)) {
    return()
  }
  pieces <- strsplit(string, "[[:space:]]*,[[:space:]]*")[[1]]
  names <- gsub("\\s*\\(.*?\\)", "", pieces)
  names <- gsub("^\\s+|\\s+$", "", names)
  versions_str <- pieces
  have_version <- grepl("\\(.*\\)", versions_str)
  versions_str[!have_version] <- NA
  compare <- sub(".*\\((\\S+)\\s+.*\\)", "\\1", versions_str)
  versions <- sub(".*\\(\\S+\\s+(.*)\\)", "\\1", versions_str)
  compare_nna <- compare[!is.na(compare)]
  compare_valid <- compare_nna %in% c(">", ">=", "==", "<=",
                                      "<")
  if (!all(compare_valid)) {
    deps <- paste(compare_nna[!compare_valid], collapse = ", ")
    stop(paste0("Invalid comparison operator in dependency:", deps))
  }
  deps <- data.frame(name = names, compare = compare, version = versions,
                     stringsAsFactors = FALSE)
  deps[names != "R", ]
}
