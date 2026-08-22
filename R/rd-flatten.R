#' Reformats the Rd structure
#'
#' The Rd structure returned by `tools::parse_Rd` and `utils::.getHelpfile()`
#' can to nested and is not ideal for translation. `rd_flatten` "flattens"
#' that structure into a simpler list and `rd_unflatten` goes back to the original
#' structure.
#'
#' @param Rd a parsed Rd file returned by `tools::parse_Rd` or
#' `utils::.getHelpfile()`.
#' @param untranslatable character vector of fields that should not be translated.
#'
#' @keywords internal
rd_flatten <- function(Rd,
                       untranslatable = c(
                         "alias",
                         "name",
                         "keyword",
                         "concept",
                         "usage"
                       )) {
  # Convert every top-level element to text.
  list <- lapply(Rd, make_text, untranslatable = untranslatable)
  list <- Filter(function(x) !is.null(x), list)
  names(list) <- rd_tags(list)

  list <- list[!(names(list) %in% c("COMMENT", "TEXT"))]
  attr(list, "untranslatable") <- c(untranslatable)

  class(list) <- rd_flat_class
  list
}

rd_remove_untranslatable <- function(rd_flat) {
  untranslatable <- attr(rd_flat, "untranslatable")

  rd_flat[!(names(rd_flat) %in% untranslatable)]
}

rd_flat_class <- "rdlocal_rd_flat"

make_text <- function(x, untranslatable) {
  tag <- attr(x, "Rd_tag")
  not_save <- c("COMMENT", "TEXT", paste0("\\", untranslatable))
  if (tag %in% not_save) {
    text <- vapply(x, to_text, FUN.VALUE = character(1))
    text <- remove_newlines(paste(text, collapse = ""))
    attr(text, "Rd_tag") <- tag
    return(text)
  }

  ## Here I treat the arguments section differently.
  ## Maybe a better way would be to correctly parse \item{}{}
  ## elements
  if (tag != "\\arguments") {
    if (tag == "\\section") {
      text <- vapply(x[[-1]], to_text, FUN.VALUE = character(1))
      tag <- paste0(tag, "{", to_text(x[[1]]), "}")
    } else {
      text <- vapply(x, to_text, FUN.VALUE = character(1))
    }
    text <- remove_newlines(paste(text, collapse = ""))
    list <- list(original = text,
                 translation = NULL)

    attr(list, "Rd_tag") <- tag
    return(list)
  }

  text <- lapply(x, function(y) {
    tag <- attr(y, "Rd_tag")

    if (tag == "\\item") {
      description <- list(original = to_text(y[[2]]),
                          translation = NULL)
      attr(description, "name") <- to_text(y[[1]])
      return(description)
    }
    return(NULL)
  })

  text <- text[!vapply(text, is.null, FUN.VALUE = logical(1))]

  names <- vapply(text, function(x) attr(x, "name"), FUN.VALUE = character(1))
  names(text) <- names
  attr(text, "Rd_tag") <- tag
  return(text)
}

remove_newlines <- function(x) {
  gsub("^\\n*", "", x)
}

to_text <- function(x) {
  tag <- attr(x, "Rd_tag")
  if (length(x) == 0) {
    return("")
  }
  # A USERMACRO node is a provenance marker that holds a copy of the macro's
  # (unsubstituted) body; the actual expansion follows as sibling nodes. Emitting
  # the marker too would duplicate the expansion (e.g. "GSoCGSoC") and leak raw
  # "#1" args, so skip it.
  if (identical(tag, "USERMACRO")) {
    return("")
  }
  # #ifdef / #ifndef are two-argument list nodes; deparse them (like markup
  # macros) instead of returning x[[1]], which is a list and errored.
  is_ifdef <- !is.null(tag) && tag %in% c("#ifdef", "#ifndef")
  if (!is_ifdef && (is.character(x) || !is.null(tag) && !startsWith(tag, "\\"))) {
    return(x[[1]])
  }
  text <- as.character(setRd(x), deparse = TRUE)
  paste(text, collapse = "")
}

rd_tags <- function(help_db) {
  tags <- vapply(help_db, function(x) attr(x, "Rd_tag"), FUN.VALUE = character(1))
  gsub("\\\\", "", tags)
}

setRd <- function(x) {
  class(x) <- "Rd"
  x
}
