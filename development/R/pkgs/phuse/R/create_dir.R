#' Create a directory
#' @description create a directory
#' @param r_dir root directory
#' @param s_dir sub directory
#' @return directory name
#' @export
#' @examples
#'   s1 <- "/Users/htu"
#'   s2 <- "myRepo"
#'   # create dir /Users/htu/myRepo if it does not exist
#'   d1 <- create_dir(s1, s2)
#' @author Hanming Tu
#' @name create_dir
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  03/06/2017 (htu) - initial creation
#  04/25/2017 (htu) - renamed from create.dir to create_dir
#
create_dir <- function(r_dir, s_dir = NULL) {
  if (is.null(s_dir)) {
      f_dir <- r_dir
  } else {
      f_dir <- paste(r_dir, s_dir, sep = "/", collapse = "/")
  }
  if (file.exists(file.path(f_dir,'/'))) {
    cat(paste("Dir - ", f_dir, " exists."))
  } else if (file.exists(f_dir)) {
    cat(paste(f_dir, " exists but is a file"))
  } else {
    cat(paste(f_dir, " does not exist - creating"))
    dir.create(f_dir, recursive = TRUE)
  }
  return(f_dir)
}

