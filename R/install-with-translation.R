# One call to stand up a translation module for a CRAN package's help, given only
# the installed binary: fetch the matching source tarball, diff source<->installed
# to build per-topic scaffolds (dynamic \Sexpr replaced by {ISEXPR_i} tokens),
# translate the static text, and build + install the module. See detect_scaffolds().

# Fetch a CRAN package's source tarball matching an *installed* version. The URL is
# deterministic; the current-version path is tried first, the Archive path second
# (for versions superseded on CRAN). Returns the untarred source dir, or NULL.
.fetch_cran_source <- function(pkg, ver, dest_dir = tempfile("i18nsrc")) {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  tb <- file.path(dest_dir, sprintf("%s_%s.tar.gz", pkg, ver))
  ok <- FALSE
  for (u in c(sprintf("https://cran.r-project.org/src/contrib/%s_%s.tar.gz", pkg, ver),
              sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s_%s.tar.gz", pkg, pkg, ver))) {
    ok <- tryCatch({ utils::download.file(u, tb, quiet = TRUE, mode = "wb"); file.size(tb) > 2000 },
                   error = function(e) FALSE)
    if (isTRUE(ok)) break
  }
  if (!isTRUE(ok)) return(NULL)
  utils::untar(tb, exdir = dest_dir)
  file.path(dest_dir, pkg)
}

# Translate a scaffold while preserving {ISEXPR_i} tokens verbatim: `translate` only
# ever sees the literal text *between* tokens, so it cannot corrupt a placeholder
# (or a render \Sexpr's code, which lives inside the static anchors). NULL translate
# leaves the entry untranslated (a fill-in template).
.translate_scaffold <- function(scaffold, translate) {
  if (is.null(translate)) return(NULL)
  tok_re <- "\\{ISEXPR_[0-9]+\\}"
  toks  <- regmatches(scaffold, gregexpr(tok_re, scaffold))[[1]]
  parts <- strsplit(scaffold, tok_re)[[1]]
  if (length(parts) < length(toks) + 1L) parts <- c(parts, rep("", length(toks) + 1L - length(parts)))
  tp <- vapply(parts, function(p) if (nzchar(trimws(p))) translate(p) else p, character(1))
  out <- tp[1]
  for (k in seq_along(toks)) out <- paste0(out, toks[k], tp[k + 1L])
  out
}

# detect_scaffolds() output -> the module's translations[[topic]] structure:
# section -> {original = scaffold, translation}, recursing for \arguments items.
.scaffolds_to_module <- function(sca, translate) {
  conv1 <- function(node) list(original = node$scaffold,
                               translation = .translate_scaffold(node$scaffold, translate))
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

#' Build and install a translation module for a CRAN package's help
#'
#' Given an installed CRAN package, fetch its matching source tarball, diff the
#' source Rd (dynamic \\Sexpr live) against the installed \code{Rd_db} (values
#' baked) to build per-topic scaffolds, translate the static text with
#' \code{translate}, and install the resulting \code{pkg.language} module. With
#' \code{translate = NULL} the module is a ready-to-fill template (every
#' translation left \code{NULL}). \code{translate} must be a
#' \code{function(text) -> text}; it only sees literal text between placeholders,
#' so it need not know about \code{{ISEXPR_i}} tokens.
#'
#' @param pkg       package name (installed, or installable from CRAN)
#' @param language  language code, e.g. "es"
#' @param translate optional \code{function(text)} returning the translation
#' @param lib       library to install the module into
#' @param quiet     suppress progress messages
#' @return (invisibly) the installed module name, \code{paste0(pkg, ".", language)}
#' @export
install_with_translation <- function(pkg, language, translate = NULL,
                                     lib = .libPaths()[1], quiet = FALSE) {
  say <- function(...) if (!quiet) message(...)
  if (!requireNamespace(pkg, quietly = TRUE)) utils::install.packages(pkg, lib = lib)
  ver <- utils::packageDescription(pkg)$Version

  say("fetching CRAN source for ", pkg, " ", ver, " ...")
  srcdir <- .fetch_cran_source(pkg, ver)
  if (is.null(srcdir)) stop("could not fetch CRAN source for ", pkg, " ", ver)

  macros <- tools::loadPkgRdMacros(srcdir)
  db     <- tools::Rd_db(pkg)
  topics <- list.files(file.path(srcdir, "man"), pattern = "\\.Rd$")
  translations <- list(); skipped <- character(0)
  for (topic in topics) {
    if (is.null(db[[topic]])) next
    src_rd <- tryCatch(tools::parse_Rd(file.path(srcdir, "man", topic), macros = macros),
                       error = function(e) NULL)
    if (is.null(src_rd)) { skipped <- c(skipped, topic); next }
    sca <- tryCatch(detect_scaffolds(src_rd, db[[topic]]), error = function(e) NULL)
    if (is.null(sca) || length(sca) == 0) { skipped <- c(skipped, topic); next }
    translations[[tools::file_path_sans_ext(topic)]] <- .scaffolds_to_module(sca, translate)
  }
  say("built scaffolds for ", length(translations), " / ", length(topics), " topics",
      if (length(skipped)) paste0(" (skipped ", length(skipped), ")") else "")

  module <- paste0(pkg, ".", language)
  moddir <- file.path(tempfile("i18nmod"), module)
  dir.create(file.path(moddir, "R"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(moddir, "inst", "translations"), recursive = TRUE, showWarnings = FALSE)
  writeLines(c(
    paste0("Package: ", module),
    "Type: Translation-module",
    paste0("Title: ", language, " translation for ", pkg),
    "Version: 0.0.1",
    paste0("Description: Auto-generated ", language, " help translation module for ", pkg, "."),
    "License: GPL-3",
    paste0("Language: ", language),
    sprintf("Translates: %s (== %s)", pkg, ver),
    "Imports: yaml",
    "Encoding: UTF-8"), file.path(moddir, "DESCRIPTION"))
  writeLines("export(translations)", file.path(moddir, "NAMESPACE"))
  writeLines(c(
    "translations <- local({",
    sprintf('  dir <- system.file("translations", package = "%s")', module),
    '  files <- list.files(dir, pattern = "\\\\.yaml$", full.names = TRUE)',
    "  tr <- lapply(files, yaml::read_yaml)",
    "  names(tr) <- tools::file_path_sans_ext(basename(files))",
    "  tr",
    "})"), file.path(moddir, "R", "translation.R"))
  for (nm in names(translations))
    yaml::write_yaml(translations[[nm]], file.path(moddir, "inst", "translations", paste0(nm, ".yaml")))

  say("installing module ", module, " ...")
  utils::install.packages(moddir, repos = NULL, type = "source", lib = lib, quiet = quiet)
  invisible(module)
}
