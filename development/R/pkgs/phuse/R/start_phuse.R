#' Start Phuse Web Application
#' @description start phuse web appllication framework.
#' @param n Example number
#' @export
#' @examples
#'   library(phuse)
#'   # comment out the interactive sessions
#'   # start_phusee()  # default to "02_display"
#'   # start_phuse(1)  # start "01_html"
#' @author Hanming Tu
#' @name start_phuse
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/21/2017 (htu) - initial creation
#
start_phuse <- function (n = 2)
{
  app_name <- paste0(sprintf("%02d", n), "_display")
  run_example(app_name)
}
