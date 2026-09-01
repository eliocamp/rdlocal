#' Pretty printing for flattened Rd files
#'
#' @param x an flattened rd object.
#' @param ... ignored.
#'
#' @export
print.Rd_flat <- function(x, ...) {
  title <- deparse(substitute(x))
  cat(list2char(x, title, n = 1))
}


list2char <- function(x, title = NULL, n = 1) {
  if (is.null(title)) {
    if (n == 1) {
      title <- deparse(substitute(x))
    } else {
      title <- ""
    }
  }
  if (!is.list(x)) {
    x <- gsub("\\n", "\\\\n", x)
    return(paste0("$", title, ": ", '"', x, '"'))
  }
  sep <- paste0("\n", strrep("  ", n), "\\u2514\\u2500")
  elements <- vapply(
    seq_along(x),
    function(i) {
      paste0(
        sep,
        "[",
        i,
        "]",
        list2char(x[[i]], title = names(x)[i], n = n + 2)
      )
    },
    FUN.VALUE = character(1)
  )

  elements <- paste0(elements, collapse = "")

  out <- paste0("$", title, ": ", elements)

  return(out)
}
