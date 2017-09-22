#' Download files from a repository
#' @description download files defined in the input data frame.
#' @param df a data frame containing file names produced from extract_fns
#' @param tgtDir target directory for storing the files
#' @param baseDir base directory in the repository including the repo URL.
#'   Default to "https://github.com/phuse-org/phuse-scripts/raw/master"
#' @importFrom utils download.file
#' @importFrom utils url.show
#' @export
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist2_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   f2 <- read_yml(f1)
#'   f3 <- extract_fns(f2)
#'   f4 <- download_fns(f3)
#' @author Hanming Tu
#' @name download_fns
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/01/2017 (htu) - initial creation
#  09/12/2017 (htu) - used crt_workdir()
#
download_fns <- function(
  df, tgtDir = NULL
  , baseDir="https://github.com/phuse-org/phuse-scripts/raw/master"
) {
  # get target dir
  if (is.null(tgtDir)) {
    workdir <- crt_workdir()
    ymd_dir <- format(Sys.time(), "%Y/%m/%d/%H%M%S")
    tgt_dir <- paste(workdir, ymd_dir, sep = '/')
  } else {
    tgt_dir <- tgtDir
  }
  if (!dir.exists(tgt_dir)) { dir.create(tgt_dir, recursive = TRUE) }

  msg <- list(); f1 <- list(); f2 <- list()
  for(i in 1:nrow(df)) {
    sdr <- gsub('\r','', df[i,"subdir"],   perl=TRUE);
    fn  <- gsub('\r','', df[i,"filename"], perl=TRUE);
    up  <- gsub('\r','', df[i,"urlpath"],  perl=TRUE)
    ifn <- ifelse(is.null(up), paste(baseDir,sdr, sep='/'), up)
    out_dir <- paste(tgt_dir,sdr, sep = '/')
    if (!dir.exists(out_dir)) { dir.create(out_dir, recursive = TRUE) }
    ofn <- paste(out_dir, fn, sep = '/')
    f1[i] <- ifn; f2[i] <- ofn
    if (url.exists(ifn)) {
      msg[i] <- "Downloading"
      download.file(ifn,ofn,mode = 'wb')
      # download.file(ifn,ofn, method="libcurl")
      # url.show(ifn, destfile = ofn)
    } else {
      msg[i] <- "Invalid URL"
    }
  }

  r <- setNames(data.frame(matrix(ncol=4, nrow=i)), c("tag", "filename","file_url", "file_path"))
  if (i>0) {
    for (j in 1:i) {
      r$tag[j]       <- df[j, "tag"];
      r$filename[j]  <- df[j,"filename"];
      r$file_url[j]  <- f1[j]
      r$file_path[j] <- f2[j]
    }
  }
  return(r)
}

