#' Initialize configuration for phuse
#' @description read script metadata file in the repository and merged it
#'   with a local script metadata file if it exists.
#' @param cfg a list containing script metadata information
#' @return a list containing the merged configuration
#' @export
#' @importFrom yaml yaml.load_file
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist2_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   f2 <- read_yml(f1)
#'   r1 <- init_cfg(f2)
#' @author Hanming Tu
#' @name init_cfg
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  03/10/2017 (htu) - initial creation
#  04/25/2017 (htu) - added required packages
#
# library('yaml')
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
