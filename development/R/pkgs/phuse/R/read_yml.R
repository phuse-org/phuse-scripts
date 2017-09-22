#' Read YML file into a list
#' @description read script metadata file in the repository or in a local folder.
#' @param fn a URL or file name containing script metadata
#' @return a list containing the parsed metadata tags
#' @export
#' @importFrom yaml yaml.load
#' @importFrom yaml yaml.load_file
#' @importFrom RCurl url.exists
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist2_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   r1 <- get_inputs(f1)
#' @author Hanming Tu
#' @name read_yml
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  08/31/2017 (htu) - initial creation
#
# library('yaml')
read_yml <- function(fn) {
  r <- list()
  if(is.null(fn) || length(fn) == 0) { return(r) }
  if (url.exists(fn)) {
    r <- yaml.load(readChar(fn,nchars=1e6))
  } else if (file.exists(fn)) {
    r <- yaml.load_file(fn)
  }
  return(r)
}
