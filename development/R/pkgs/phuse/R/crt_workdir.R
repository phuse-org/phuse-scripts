#' Create work directory
#' @description define and create a work directory.
#' @param top_dir a top or root directory; default to '/Users/{user} for Mac
#'   or getwd for other OS
#' @param sub_dir a sub directory
#' @param to_crt_dir whether to create the dir; default to TRUE
#' @return the created directory
#' @name crt_workdir
#' @export
#' @author Hanming Tu
# Function Name: crt_workdir
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/12/2017 (htu) - initial creation
#
crt_workdir <- function(
  top_dir = NULL,
  sub_dir = 'myRepo',
  to_crt_dir = TRUE
) {
  if (is.null(top_dir))     {
    sys_name <- Sys.info()[["sysname"]]
    usr_name <- Sys.info()[["user"]]
    if (sys_name == "Darwin") {
      r <- paste('/Users', usr_name, sub_dir, sep = '/');
    } else {
      r <- paste(getwd(), usr_name, sub_dir, sep = '/');
    }
  } else {
    r <- paste(top_dir, sub_dir, sep = '/')
  }
  if (!dir.exists(r) && to_crt_dir) { dir.create(r, recursive = TRUE); }
  return(r)
}
