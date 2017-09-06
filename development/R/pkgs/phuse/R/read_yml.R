#' Read YML file into a list
#' @description read script metadata file in the repository or in a local folder.
#' @param fn a URL or file name containing script metadata
#' @return a list containing the parsed metadata tags
#' @name read_yml
#' @export
#' @importFrom yaml yaml.load
#' @importFrom yaml yaml.load_file
#' @importFrom RCurl url.exists
#' @author Hanming Tu
# Function Name: read_yml
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  08/31/2017 (htu) - initial creation
#
# library('yaml')
read_yml <- function(fn) {
  r <- list()
  if (url.exists(fn)) {
    r <- yaml.load(readChar(fn,nchars=1e6))
  } else if (file.exists(fn)) {
    r <- yaml.load_file(fn)
  }
  return(r)
}
