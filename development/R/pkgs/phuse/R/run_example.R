#' Run example
#' @description run examples stored in the example folder.
#' @param example Example name
#' @param port Port number
#' @param launch.browser define the browser- shiny.launch.browser
#' @param host define the host or ip address
#' @param display.mode modes are auto, normal or showcase
#' @name run_example
#' @export
#' @author Hanming Tu
# Function Name: run_example
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  08/28/2017 (htu) - initial creation
#
run_example <- function (example = NA, port = NULL,
    launch.browser = getOption("shiny.launch.browser",interactive()),
    host = getOption("shiny.host", "127.0.0.1"),
    display.mode = c("auto", "normal", "showcase")
)
{
  examplesDir <- system.file("examples", package = "phuse")
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
