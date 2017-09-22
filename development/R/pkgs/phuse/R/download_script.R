#' Download files defined in script metadata
#' @description download scripts, data or any file defined in the script metadata.
#' @param cfg a list containing script metadata
#' @param wkDir work directory where the files will be downloaded to
#' @param source_lib whether to source the library defined for the scrpt in the metadata
#' @return target directory name
#' @export
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist2_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   f2 <- read_yml(f1)
#'   f3 <- download_script(f2)
#' @author Hanming Tu
#' @name download_script
# ---------------------------------------------------------------------------
# Purpose: download all the files defined in the script metadata file
# HISTORY   MM/DD/YYYY (developer) - explanation
#   03/10/2017 (htu) - initial creation
#   04/25/2017 (htu) - imported to the R package
#   09/20/2017 (htu) -
#     1. changed curWorkDir from getwd() to crt_workdir
#     2. changed stop to cat and return.
#
download_script <- function(
    cfg
  , wkDir = "workdir"
  , source_lib = TRUE
) {
  prg <- "download_script"
  curWorkDir <- crt_workdir(to_crt_dir = FALSE)
  if (is.null(cfg[["files"]])) {
    cat(paste(prg, ": Could not find input files.")); return() }
  if (is.null(cfg[["dirs"]]))  {
    cat(paste(prg, ": Could not find dir names.")); return() }
  f <- cfg$files;   d <- cfg$dirs

  # create the local target workdir
  ymd_dir <- format(Sys.time(), "%Y/%m/%d/%H%M%S")
  tgtDir <- paste(curWorkDir,wkDir, ymd_dir, sep = '/')
  dir.create(tgtDir, recursive = TRUE)
  # download files for running the script
  cat(paste("Downloading files to ", tgtDir, "..."))
  if ("files" %in% names(cfg) && "dirs" %in% names(cfg) ) {
    if (is.null(d[["baseDir"]]) && is.null(d[["scriptDir"]])) {
      download_script_files(f, tgtDir)
    } else if (is.null(d[["baseDir"]])) {
      download_script_files(f, tgtDir, scriptDir = d$scriptDir)
    } else if (is.null(d[["scriptDir"]])) {
      download_script_files(f, tgtDir, baseDir = d$baseDir)
    } else {
      download_script_files(f, tgtDir, baseDir = d$baseDir, scriptDir = d$scriptDir)
    }
  }
  if (source_lib) {
    if ("lib_file" %in% names(f)) { source(paste(tgtDir, f$lib_file, sep = '/')) }
  }
  return(tgtDir);
}

