#' Get Inputs from Script Metadata File
#' @description Get inputs from script metadata.
#' @param fn a file name or URL pointing to script metadata file
#' @return a list of input values provided for the script
#' @name get_yml_inputs
#' @export
#' @author Hanming Tu
# Function Name: get_yml_inputs
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/17/2017 (htu) - initial creation
#
get_yml_inputs <- function(fn = NULL) {
  r <- list()
  # 1. get the script name
  sfo <- sys.frame(1)$ofile
  if (is.null(fn) && is.null(sfo)) { cat("ERROR: no script name is provided."); return(r) }
  script_name <- ifelse(is.null(fn), sfo, fn)
  # str(script_name)
  if (is.null(script_name) || is.na(script_name)) {
    cat("ERROR: no script name is provided.")
    return(r)
  }
  # 2. get YML name
  yml_name    <- gsub('.([[:alnum:]]+)$','_\\1.yml', script_name)
  # str(yml_name)

  if (! file.exists(yml_name)) {
    cat(paste0("ERROR: ", yml_name, " does not exist"))
    return(r)
  }
  # 3. read YML content
  cfg <- read_yml(yml_name)
  if (! "Inputs" %in% names(cfg)) {
    cat(paste0("ERROR: no Inputs defined in ", yml_name))
    return(r)
  }
  k <- 0
  for (i in 1:20) {
    v <- paste0("p", i)
    if (v %in% names(cfg$Inputs)) { k <- k + 1;
    # we need to remove any R Shiny specification here
    r[k] <- gsub('\\s+-.+','', cfg$Inputs[[v]])
    }
  }
  return(r)
}
