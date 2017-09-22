#' Verify work directory
#' @description Verify if the dir is the work directory
#' @param dir a work directory; default to '/Users/{user} for Mac; "c:/tmp" for Windows
#    or getwd() for others
#' @param top_dir a top or root directory; default to '/Users/{user} for Mac
#'   or getwd for other OS
#' @param sub_dir a sub directory
#' @return TRUE or FALSE
#' @export
#' @examples
#'   f1 <- "/Users/htu/myRepo"
#'   r1 <- chk_workdir(f1)
#' @author Hanming Tu
#' @name chk_workdir
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/14/2017 (htu) - initial creation
#
chk_workdir <- function(
  dir,
  top_dir = NULL,
  sub_dir = 'myRepo'
) {
  r <- crt_workdir(top_dir, sub_dir, to_crt_dir = FALSE)
  return (grepl(r, dir, ignore.case = TRUE))
}
