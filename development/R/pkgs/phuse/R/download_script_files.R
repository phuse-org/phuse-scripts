#' Download files from a repository
#' @description download files defined in the input list from a repository.
#' @param fns a list containing file names
#' @param tgtDir target directory for storing the files
#' @param baseDir base directory in the repository including the repo URL.
#'   Default to "https://github.com/phuse-org/phuse-scripts/raw/master"
#' @param scriptDir script directory in the repository
#' @importFrom utils download.file
#' @export
#' @examples
#'   fns <- c("dm.xpt","ex.xpt")
#'   dir <- "/Users/htu/myRepo/data"
#'   # a <- download_script_files(fns, dir)
#' @author Hanming Tu
#' @name download_script_files
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  03/02/2017 (htu) - initial creation
#  04/25/2017 (htu) - renamed from download.script.files to download_script_files
#
download_script_files <- function(
    fns, tgtDir
  , baseDir="https://github.com/phuse-org/phuse-scripts/raw/master"
  , scriptDir="data/send/PDS/Xpt"
  # , repoDir="phuse-org/phuse-scripts"
  # , repoURL='https://api.github.com/repos'
) {
  for (i in seq(fns)) {
    ifn <- paste(baseDir,scriptDir,fns[[i]],sep = '/')
    ofn <- paste(tgtDir,fns[[i]], sep = '/')
    create_dir(tgtDir,dirname(fns[[i]]))
    download.file(ifn,ofn,mode = 'wb')
  }
}
