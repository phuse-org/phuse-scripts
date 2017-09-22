#' Resolve absolute path
#' @description Resolve absolute directory
#' @param dir directory
#' @param relpath relative path
#' @export
#' @examples
#'   resolve("/Users/htu/myRepo", "scripts")
#'   # get "/Users/htu/myRepo/scripts"
#' @author Hanming Tu
#' @name resolve
# ---------------------------------------------------------------------------
resolve <- function (dir, relpath)
{
  abs.path <- file.path(dir, relpath)
  if (!file.exists(abs.path))
    return(NULL)
  abs.path <- normalizePath(abs.path, winslash = "/", mustWork = TRUE)
  dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)
  if (.Platform$OS.type == "windows")
    dir <- sub("/$", "", dir)
  if (nchar(abs.path) <= nchar(dir) + 1)
    return(NULL)
  if (substr(abs.path, 1, nchar(dir)) != dir ||
      substr(abs.path, nchar(dir) + 1, nchar(dir) + 1) != "/") {
    return(NULL)
  }
  return(abs.path)
}
