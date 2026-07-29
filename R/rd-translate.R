#' Translates an Rd object
#'
#' Takes an object returned by `[tools::parse_Rd]` and `utils::.getHelpfile()`
#' and translates the strings.
#'
#' @param Rd Rd object
#' @param translation a flattened rd object returned by `[rd_flatten]` or,
#' more likely, by `[rd_flat_read]`.
#'
#' @returns an Rd object with translated strings.
#' @keywords internal
rd_translate <- function(Rd, translation) {
  Rd <- rd_flatten(Rd)

  translated <- translate(Rd, translation)

  rd_unflatten(translated)
}



translate <- function(original, translation) {
  sections <- names(translation)
  for (section in sections)  {

    if (is.character(original[[section]]$original)) {
      live   <- original[[section]]$original
      stored <- translation[[section]]$original
      trans  <- translation[[section]]$translation

      # Token-aware match: stored `original`/`translation` may contain {ISEXPR_i}
      # placeholders standing in for install/build-Sexpr-baked spans (whose value
      # changes every install). match_and_fill() matches the live `original`
      # against the stored scaffold as a template, captures the live values, and
      # substitutes them into the translation. With no tokens it is an exact match,
      # so existing modules behave exactly as before. When no translation applies
      # (missing, or an out-of-date scaffold) it returns `live` unchanged.
      filled <- match_and_fill(live, stored, trans, translation[[section]]$ifdef)$text

      # examples/title that were actually translated show the original collapsed
      # behind a disclosure; an untranslated section is just `live`.
      if (!identical(filled, live) && section %in% c("examples", "title")) {
        filled <- paste0(
          filled,
          "\\if{html}{\\out{<details style='display:inline'> <summary>} \U0001f310 \\out{</summary>} ",
          live,
          "\\out{</details>}}")
      }
      original[[section]] <- filled
    }

    if (is.list(original[[section]])) {
      original[[section]] <- translate(original[[section]], translation[[section]])

    }

  }
  return(original)
}

# Match a live (baked) section string against a stored scaffold template and fill
# the translation. The scaffold may contain {ISEXPR_i} placeholders for dynamic
# (install/build-Sexpr) spans. The literal text between tokens is matched against
# `live` by fixed-string search (no regex escaping, and it spans newlines, so
# multi-line baked output works); the gaps are the captured live values, which are
# substituted into the matching {ISEXPR_i} in the translation.
# Returns the filled translation, or `live` unchanged if the scaffold does not
# match (missing translation, or genuine version drift) — so the caller can use
# the result directly with no NULL check.
#
# A *literal* placeholder-shaped string (which reaches the flattened help only via
# Rd-escaped braces, `\{ISEXPR_n\}`) is authored in the stored strings with doubled
# braces, `{{ISEXPR_n}}`. Such literals are hidden behind sentinels before any token
# work (so only real, single-brace placeholders are matched) and restored as a
# single-brace literal in the output.
match_and_fill <- function(live, stored, translation, ifdef = NULL) {
  tok_re  <- "\\{ISEXPR_[0-9]+\\}"
  stored0 <- stored   # original scaffold, kept for the status metadata

  # Always returns list(text, reason, distance). Callers currently read only
  # `text`; reason/distance are non-read metadata for a future soft-fallback / tool.
  #   reason   "valid"        scaffold matched, translation applied
  #            "stale"        a translation exists but `live` drifted from it
  #            "untranslated" no translation to apply
  #   distance 0 for "valid"; a coarse Levenshtein drift of `live` from the
  #            scaffold skeleton for "stale"; Inf when there is no translation
  #            (so 0 / finite / Inf all compare numerically).
  finish <- function(text, reason) {
    skeleton <- if (is.null(stored0)) "" else gsub(tok_re, "", stored0)
    distance <- switch(reason,
                       valid = 0,
                       stale = as.numeric(utils::adist(live, skeleton)[1, 1]),
                       Inf)
    list(text = text, reason = reason, distance = distance)
  }

  if (is.null(stored) || is.null(translation)) {
    return(finish(live, "untranslated"))
  }

  hide   <- function(s) gsub("\\{\\{(ISEXPR_[0-9]+)\\}\\}", "\x01\\1\x02", s)
  reveal <- function(s) gsub("\x02", "}", gsub("\x01", "{", s, fixed = TRUE), fixed = TRUE)
  stored      <- hide(stored)
  translation <- hide(translation)

  # No placeholders -> plain exact-match (backward compatible).
  if (!grepl(tok_re, stored)) {
    if (identical(live, reveal(stored))) {
      return(finish(reveal(translation), "valid"))
    }
    return(finish(live, "stale"))
  }

  toks <- regmatches(stored, gregexpr(tok_re, stored))[[1]]
  idx  <- as.integer(sub("\\{ISEXPR_([0-9]+)\\}", "\\1", toks))
  n    <- length(toks)
  anchors <- strsplit(stored, tok_re)[[1]]            # n+1 literal anchors
  if (length(anchors) < n + 1L) {
    anchors <- c(anchors, rep("", n + 1L - length(anchors)))  # strsplit drops trailing ""
  }
  anchors <- reveal(anchors)   # a literal {ISEXPR_n} in an anchor matches the live text

  # Boundary anchors are pinned to the ends; interior anchors split sequentially.
  if (!startsWith(live, anchors[1])) {
    return(finish(live, "stale"))
  }
  rem <- substr(live, nchar(anchors[1]) + 1L, nchar(live))
  values <- character(n)
  if (n >= 2L) {
    for (k in 1:(n - 1L)) {
      a <- anchors[k + 1L]
      if (nchar(a) == 0) { values[k] <- ""; next }    # adjacent tokens, no separator
      p <- regexpr(a, rem, fixed = TRUE)
      if (p == -1) return(finish(live, "stale"))
      values[k] <- substr(rem, 1, p - 1)
      rem <- substr(rem, p + nchar(a), nchar(rem))
    }
  }
  if (!endsWith(rem, anchors[n + 1L])) {
    return(finish(live, "stale"))  # scaffold did not match (genuine version drift)
  }
  values[n] <- substr(rem, 1, nchar(rem) - nchar(anchors[n + 1L]))

  out <- translation
  for (k in seq_along(idx)) {
    val <- values[k]
    key <- as.character(idx[k])
    # An #ifdef token whose live value is the active branch (not R's
    # "#ifdef <cond> not active" marker) is replaced by its stored branch
    # translation; an inactive branch keeps the (invisible) marker, and a plain
    # install/build span keeps its captured value (passthrough).
    if (!is.null(ifdef) && key %in% names(ifdef) &&
        !grepl("^#if(n?)def .* not active", val)) {
      val <- ifdef[[key]]
    }
    out <- gsub(paste0("{ISEXPR_", idx[k], "}"), val, out, fixed = TRUE)
  }
  finish(reveal(out), "valid")
}

