#' Write and read a flattened rd file
#'
#' @param rd_flat an rd_flattened file returned by `[rd_flatten]`.
#' @param file path to the file.
#'
#' @details
#' `rd_flat_write` writes the result of `[rd_flatten]` into a yaml file that
#' then can be used for translation.
#' `rd_flat_read` reads this file and the result can be used as translation
#' for `[rd_translate]`.
#'
#' @export
rd_flat_write <- function(rd_flat, file) {
  untranslatable <- attr(rd_flat, "untranslatable")

  rd_flat <- rd_flat[!(names(rd_flat) %in% untranslatable)]
  rd_flat[["untranslatable"]] <- untranslatable
  yaml::write_yaml(rd_flat, file)
}
