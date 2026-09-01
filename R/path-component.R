#' Extract component of a path
#'
#' @param path a vector of paths
#' @param depth positive integer indicating the component to extract.
#' 0 means the last component, 1 means its parent and so on.
#'
#' @details
#' This was used in a previous implementation of the package and left here just
#' in case. Probably can delete, but since it's not exported and is a simple
#' function, it doesn't hurt.
#'
#' @examples
#' \dontrun{
#' path_component("/home/user/Documents/file.txt")
#' path_component("/home/user/Documents/file.txt", depth = 2)
#' }
#' @keywords internal
path_component <- function(path, depth = 0) {
  if (depth[1] == 0) {
    return(basename(path))
  } else {
    return(path_component(dirname(path), depth = depth[1] - 1))
  }
}
