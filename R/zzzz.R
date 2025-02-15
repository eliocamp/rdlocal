.onLoad <- function(libname, pkgname){
  utils <- loadNamespace('utils')
  getHelpFile <- get('.getHelpFile', envir = utils)
  body(getHelpFile)[[2]] <- substitute({
    on.exit(return(rhelpi18n:::.translateHelpFile(returnValue(), pkgname, file)))
    step1
  }, list(step1 = body(getHelpFile)[[2]]))
  unlockBinding('.getHelpFile', utils)
  assign('.getHelpFile', getHelpFile, envir = utils)
  lockBinding('.getHelpFile', utils)

  # pkgdown <- loadNamespace('pkgdown')
  # rd_text <- get('rd_text', envir = pkgdown)
  # body(rd_text)[[2]] <- substitute({
  #   on.exit(return(rhelpi18n:::.translateHelpFile(returnValue(), pkgname, file)))
  #   step1
  # }, list(step1 = body(rd_text)[[2]]))
  # unlockBinding('rd_text', pkgdown)
  # assign('rd_text', rd_text, envir = pkgdown)
  # lockBinding('rd_text', pkgdown)
  #
  tools <- loadNamespace('tools')
  parse_Rd <- get('parse_Rd', envir = tools)
  body(parse_Rd)[[2]] <- substitute({
    on.exit(return(rhelpi18n:::.translateHelpFile(returnValue(), pkgname, file)))
    step1
  }, list(step1 = body(parse_Rd)[[2]]))
  unlockBinding('parse_Rd', tools)
  assign('parse_Rd', parse_Rd, envir = tools)
  lockBinding('parse_Rd', tools)
}
