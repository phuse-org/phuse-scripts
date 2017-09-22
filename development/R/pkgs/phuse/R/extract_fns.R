#' Extract File Names from Script Metadata
#' @description extract folders and file names from a list containing script metadata.
#' @param lst a list containing script metadata
#' @return a data frame (subdir, filename) containing parsed file names
#' @export
#' @importFrom RCurl url.exists
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist2_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   f2 <- read_yml(f1)
#'   f3 <- extract_fns(f2)
#' @author Hanming Tu
#' @name extract_fns
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  08/31/2017 (htu) - initial creation
#  09/13/2017 (htu) - added v list to capture tag name
#
# library(RCurl)

extract_fns <- function(lst) {
  d <- list(); f <- list(); u <- list(); v <- list(); i <- 0
  # get repo info
  p_url <- ifelse(is.null(lst$Repo$base_dir), '', lst$Repo$base_dir);
  p_url <- ifelse(is.null(lst$Repo$prog_dir), p_url, paste(p_url,lst$Repo$prog_dir,sep='/'))
  # get directories
  data_dir   <- ifelse(is.null(lst$Repo$data_dir),  'data',   lst$Repo$data_dir);
  lib_dir    <- ifelse(is.null(lst$Repo$lib_dir),   'libs',   lst$Repo$lib_dir);
  script_dir <- ifelse(is.null(lst$Repo$script_dir),'scripts',lst$Repo$script_dir);
  # get script name
  if (!is.null(lst$Script$name)) {
    i <- i + 1; d[i] <- script_dir; f[i] <- lst$Script$name; v[i] <- 'script_name'
    u[i] <- paste(p_url,script_dir,lst$Script$name,sep='/')
    yml_fn <- paste0(gsub('[.](\\w+)$','_\\1', f[i], perl=TRUE), '.yml')
    i <- i + 1; d[i] <- script_dir; f[i] <- yml_fn; v[i] <- 'yml_name'
    u[i] <- paste(p_url,script_dir,yml_fn,sep='/')
  }
  # get dataset names
  if (!is.null(lst$Inputs$datasets)) {
    ds <- lst$Inputs$datasets;
    cc <- strsplit(ds, ',');
    j <- 0
    for (x in cc[[1]]) {
      i <- i + 1; d[i] <- data_dir; f[i] <- trimws(x);
      u[i] <- paste(p_url,data_dir,f[i],sep='/')
      j <- j + 1; v[i] <- paste0('dataset_', j)
    }
  }
  # get lib files
  if (!is.null(lst$Repo$lib_files)) {
    ds <- lst$Repo$lib_files;
    j <- 0;
    for (x in strsplit(ds, ',')[[1]]) {
      i <- i + 1; d[i] <- lib_dir; f[i] <- trimws(x);
      u[i] <- paste(p_url,lib_dir,f[i],sep='/')
      j <- j + 1; v[i] <- paste0('lib_file_', j)
    }
  }
  r <- setNames(data.frame(matrix(ncol=5, nrow=i)), c("subdir", "tag", "filename","status", "urlpath"))
  if (i>0) {
    for (j in 1:i) {
      u1            <- gsub('\r','',u[j], perl=TRUE);
      r$subdir[j]   <- gsub('\r','',d[j], perl=TRUE);
      r$filename[j] <- gsub('\r','',f[j], perl=TRUE);
      r$status[j]   <- ifelse(url.exists(u1),'OK','Invalid URL');
      r$urlpath[j]  <- u1;
      r$tag[j]      <- v[j]
    }
  }
  return(r)
}
