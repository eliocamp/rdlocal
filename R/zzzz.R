.onLoad <- function(libname, pkgname){
  base <- asNamespace('base')
  find.package <- get('find.package', envir = base)

  body(find.package)[[2]] <- substitute({
    package <- rhelpi18n:::add_translation_modues(package)

    step1
  }, list(step1 = body(find.package)[[2]]))

  unlockBinding('find.package', base)
  assign('find.package', find.package, envir = base)
  lockBinding('find.package', base)
}
