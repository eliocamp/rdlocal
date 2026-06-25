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
      filled <- if (!is.null(trans)) match_and_fill(live, stored, trans) else NULL

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
# (install/build-Sexpr) spans; each becomes a capture group, and the captured live
# value is substituted into the matching {ISEXPR_i} in the translation.
# Returns the filled translation, or NULL if it does not match.
match_and_fill <- function(live, stored, translation) {
  if (is.null(stored) || is.null(translation)) {
    return(NULL)
  }
  tok_re <- "\\{ISEXPR_([0-9]+)\\}"

  # No placeholders -> plain exact-match (backward compatible).
  if (!grepl(tok_re, stored)) {
    if (identical(live, stored)) {
      return(translation)
    }
    return(NULL)
  }

  esc <- function(x) gsub("([][{}()*+?.\\\\^$|])", "\\\\\\1", x, perl = TRUE)
  toks <- regmatches(stored, gregexpr(tok_re, stored))[[1]]
  idx  <- as.integer(sub(tok_re, "\\1", toks))
  lits <- strsplit(stored, tok_re, perl = TRUE)[[1]]
  if (length(lits) < length(toks) + 1) {
    lits <- c(lits, rep("", length(toks) + 1 - length(lits)))
  }
  re <- paste0("^", paste0(vapply(lits, esc, character(1)), collapse = "(.*?)"), "$")

  caps <- regmatches(live, regexec(re, live, perl = TRUE))[[1]]
  if (length(caps) == 0) {
    return(NULL)  # scaffold did not match (genuine version drift)
  }
  values <- caps[-1]

  out <- translation
  for (k in seq_along(idx)) {
    out <- gsub(paste0("{ISEXPR_", idx[k], "}"), values[k], out, fixed = TRUE)
  }
  out
}

