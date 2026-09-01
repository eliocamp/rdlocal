.translateHelpFile <- function(
  rd,
  pkgname,
  file,
  language = Sys.getenv("LANGUAGE", "en")
) {
  if (is.null(language)) {
    return(rd)
  }

  name <- basename(file)
  translation_modules <- get_translation_modules(pkgname, language = language)
  if (length(translation_modules) == 0) {
    return(rd)
  }

  translations <- get(
    "translations",
    envir = asNamespace(translation_modules[1])
  )[[name]]

  if (is.null(translations)) {
    return(rd)
  }

  rd <- rd_translate(rd, translations)

  return(rd)
}
