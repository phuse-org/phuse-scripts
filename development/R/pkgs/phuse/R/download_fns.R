#' Download files from a repository
#' @description download files defined in the input data frame.
#' @param df a data frame containing file names produced from extract_fns
#' @param tgtDir target directory for storing the files
#' @param baseDir base directory in the repository including the repo URL.
#'   Default to "https://github.com/phuse-org/phuse-scripts/raw/master"
#' @importFrom utils download.file
#' @importFrom utils url.show
#' @name download_fns
#' @export
#' @author Hanming Tu
#
# Function Name: download_fns
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/01/2017 (htu) - initial creation
#
download_fns <- function(
  df, tgtDir = NULL
  , baseDir="https://github.com/phuse-org/phuse-scripts/raw/master"
) {
  # get target dir
  if (is.null(tgtDir)) {
    curWorkDir <- getwd()
    ymd_dir <- format(Sys.time(), "%Y/%m/%d/%H%M%S")
    tgt_dir <- paste(curWorkDir,'workdir', ymd_dir, sep = '/')
  } else {
    tgt_dir <- tgtDir
  }
  if (!dir.exists(tgt_dir)) { dir.create(tgt_dir, recursive = TRUE) }

  for(i in 1:nrow(df)) {
    sdr <- gsub('\r','', df[i,1], perl=TRUE);
    fn  <- gsub('\r','', df[i,2], perl=TRUE);
    up  <- gsub('\r','', df[i,3], perl=TRUE)
    ifn <- ifelse(is.null(up), paste(baseDir,sdr, sep='/'), up)
    out_dir <- paste(tgt_dir,sdr, sep = '/')
    if (!dir.exists(out_dir)) { dir.create(out_dir, recursive = TRUE) }
    ofn <- paste(out_dir, fn, sep = '/')
    if (url.exists(ifn)) {
      # print(paste0("Downloading ", ifn, " to ", ofn))
      download.file(ifn,ofn,mode = 'wb')
      # download.file(ifn,ofn, method="libcurl")
      # url.show(ifn, destfile = ofn)
    } else {
      print(paste0("Invalid URL ", ifn))
    }
  }
}

