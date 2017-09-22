#' Run example
#' @description run examples stored in the example folder.
#' @param example Example name
#' @param pkg  package name
#' @param port Port number
#' @param launch.browser define the browser- shiny.launch.browser
#' @param host define the host or ip address
#' @param display.mode modes are auto, normal or showcase
#' @export
#' @examples
#'   library(phuse)
#'   # I have to comment it out so it can pass "R CMD check --as-cran"
#'   # run_example("02_display")
#' @author Hanming Tu
#' @name run_example
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  08/28/2017 (htu) - initial creation
#  09/22/2017 (htu) - added pkg parameter
#
run_example <- function (example = NA, pkg = "phuse", port = NULL,
    launch.browser = getOption("shiny.launch.browser",interactive()),
    host = getOption("shiny.host", "127.0.0.1"),
    display.mode = c("auto", "normal", "showcase")
)
{
  examplesDir <- system.file("examples", package = pkg )
  # dir <- shiny:::resolve(examplesDir, example)
  dir <- resolve(examplesDir, example)
  if (is.null(dir)) {
    if (is.na(example)) {
      errFun <- message
      errMsg <- ""
    }
    else {
      errFun <- stop
      errMsg <- paste("Example", example, "does not exist. ")
    }
    errFun(errMsg, "Valid examples are \"", paste(list.files(examplesDir),
                                                  collapse = "\", \""), "\"")
  }
  else {
    shiny::runApp(dir, port = port, host = host, launch.browser = launch.browser,
           display.mode = display.mode)
  }
}
