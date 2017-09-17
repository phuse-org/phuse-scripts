#' Get Inputs from Input Sources
#' @description Get inputs from interactive session (shiny webpage), command line or script metadata.
#' @param fn a file name or URL pointing to script metadata file
#' @return a list of input values provided for the script
#' @name get_inputs
#' @export
#' @author Hanming Tu
# Function Name: get_inputs
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/17/2017 (htu) - initial creation
#
get_inputs <- function(fn = NULL) {

  # 1. check input parameters
  if (! is.null(fn)) { return(get_yml_inputs(fn)) }

  r <- list()
  # 2. get inputs from interactive session first
  k <- 0
  if (exists("input")) {
    for (i in 1:20) {
      v <- paste0("p", i)
      if (v %in% names("input")) { k <- k + 1; r[k] <- input[[v]] }
    }
    return(r)
  }

  # 3. check inputs from command line
  #
  cmd <- commandArgs()
  if ("script_name" %in% names(cmd)) {
    yml_name    <- gsub('.([[:alnum:]]+)$','_\\1.yml', cmd[["script_name"]])
    r <- get_yml_inputs(yml_name)
    return()
  }
  if (grepl('phuse', cmd[[1]],  ignore.case = TRUE)) {
    return(cmd[-1])
  }

  # 4. get inputs from script metadata
  sfo <- sys.frame(1)$ofile
  if (is.null(sfo)) {
    cat("ERROR: no script name is provided."); return(r)
  }
  r <- get_yml_inputs(sfo)
  return(r)
}

