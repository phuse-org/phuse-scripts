#' Initialize configuration for phuse
#' @description read script metadata file in the repository and merged it
#'   with a local script metadata file if it exists.
#' @param cfg a list containing script metadata information
#' @return a list containing the merged configuration
#' @name init_cfg
#' @export
#' @author Hanming Tu
# Function Name: init_cfg
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  03/10/2017 (htu) - initial creation
#  04/25/2017 (htu) - added required packages
#
init_cfg <- function(cfg) {
  curWorkDir <- getwd()
  yml_file <- cfg$files$yml_file;
  if (is.null(yml_file)) { return(cfg)}
  lfn <- paste(curWorkDir,yml_file, sep = '/')
  if (!file.exists(lfn)) {return(cfg)}
  a <- cfg
  b <- yaml.load_file(lfn)
  c <- merge_lists(a,b)

  return(c)
}
