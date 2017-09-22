#' Create work directory
#' @description define and create a work directory.
#' @param top_dir a top or root directory; default to '/Users/{user} for Mac
#'   or getwd for other OS
#' @param sub_dir a sub directory
#' @param to_crt_dir whether to create the dir; default to TRUE.
#'   If FALSE, just return the dir name
#' @return the created directory
#' @export
#' @examples
#'   f1 <- "/Users/htu"
#'   r1 <- crt_workdir(f1)
#' @author Hanming Tu
#' @name crt_workdir
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/12/2017 (htu) - initial creation
#  09/14/2017 (htu) - added to_crt_dir = FALSE to just return dir name
#    and Linux, Windows options
#
crt_workdir <- function(
  top_dir = NULL,
  sub_dir = 'myRepo',
  to_crt_dir = TRUE
) {
  if (is.null(top_dir))     {
    sys_name <- Sys.info()[["sysname"]]
    usr_name <- Sys.info()[["user"]]
    if (grepl("^(Darwin|Linux)", sys_name, ignore.case = TRUE)) {
      r <- paste('/Users', usr_name, sub_dir, sep = '/');
    } else if (grepl("^Windows", sys_name, ignore.case = TRUE)) {
      r <- paste('c:/tmp', usr_name, sub_dir, sep = '/');
    } else {
      r <- paste(getwd(), usr_name, sub_dir, sep = '/');
    }
  } else {
    r <- paste(top_dir, sub_dir, sep = '/')
  }
  if (!to_crt_dir) { return(r) }
  if (!dir.exists(r) && to_crt_dir) { dir.create(r, recursive = TRUE); }
  return(r)
}
