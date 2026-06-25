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
      # so existing modules behave exactly as before.
      filled <- if (!is.null(trans)) match_and_fill(live, stored, trans,
                                                    translation[[section]]$ifdef) else NULL

      if (!is.null(filled)) {
        if (section %in% c("examples", "title")) {
          original[[section]] <- paste0(
            filled,
            "\\if{html}{\\out{<details style='display:inline'> <summary>} \U0001f310 \\out{</summary>} ",
            live,
            "\\out{</details>}}")
        } else {
          original[[section]] <- filled
        }

      } else {
        # Translation missing or out of date: keep the original
        original[[section]] <- live
      }
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
# Returns the filled translation, or NULL if the scaffold does not match.
match_and_fill <- function(live, stored, translation, ifdef = NULL) {
  if (is.null(stored) || is.null(translation)) {
    return(NULL)
  }
  tok_re <- "\\{ISEXPR_[0-9]+\\}"

  # No placeholders -> plain exact-match (backward compatible).
  if (!grepl(tok_re, stored)) {
    if (identical(live, stored)) {
      return(translation)
    }
    return(NULL)
  }

  toks <- regmatches(stored, gregexpr(tok_re, stored))[[1]]
  idx  <- as.integer(sub("\\{ISEXPR_([0-9]+)\\}", "\\1", toks))
  n    <- length(toks)
  anchors <- strsplit(stored, tok_re)[[1]]            # n+1 literal anchors
  if (length(anchors) < n + 1L) {
    anchors <- c(anchors, rep("", n + 1L - length(anchors)))  # strsplit drops trailing ""
  }

  # Boundary anchors are pinned to the ends; interior anchors split sequentially.
  if (!startsWith(live, anchors[1])) {
    return(NULL)
  }
  rem <- substr(live, nchar(anchors[1]) + 1L, nchar(live))
  values <- character(n)
  if (n >= 2L) {
    for (k in 1:(n - 1L)) {
      a <- anchors[k + 1L]
      if (nchar(a) == 0) { values[k] <- ""; next }    # adjacent tokens, no separator
      p <- regexpr(a, rem, fixed = TRUE)
      if (p == -1) return(NULL)
      values[k] <- substr(rem, 1, p - 1)
      rem <- substr(rem, p + nchar(a), nchar(rem))
    }
  }
  if (!endsWith(rem, anchors[n + 1L])) {
    return(NULL)  # scaffold did not match (genuine version drift)
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
  out
}

