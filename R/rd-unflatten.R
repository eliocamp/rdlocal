#' @param rd_flat a flattened Rd file.
#' @rdname rd_flatten
#' @keywords internal
rd_unflatten <- function(rd_flat) {
  text <- list2rdtext(rd_flat)
  file <- tempfile(fileext = ".rd")
  writeLines(text, file)
  tools::parse_Rd(file)
}


list2rdtext <- function(x) {
  texts <- vapply(x, section2char, FUN.VALUE = character(1))

  paste(paste0("\\", names(x), "{", texts, "}"), collapse = "\n")
}

section2char <- function(x) {
  if (is.character(x)) {
    return(x)
  }

  paste(paste0("\\item{", names(x), "}{", unlist(x), "}"), collapse = "")
}
