#' Build Script Index Dataset
#' @description Grep all the YML files, parse the metadata and build
#'   a data frame containing key metadata tags.
#' @param repo_url a URL for a remote repository and default to
#'   'https://github.com/phuse-org/phuse-scripts.git'
#' @param repo_base a URL for repository base folder; default to
#'   "https://github.com/phuse-org/phuse-scripts/raw/master"
#' @param repo_dir a local directory to host the repository;
#'   default to current work directory if not specified
#' @param work_dir a local directory to host the files containing
#'   a list of YML files; default to {getwd}/myRepo
#' @param output_fn a CSV file name for outputing a list of YML files;
#'   default to "{repo_name}_yml.csv
#' @param days_to_update number of days before the output_fn is updated;
#'   default to 7 days.
#'   Set it to a negative number make it to update immediately.
#' @param fn_only return file name only; default to FALSE
#' @param upd_opt update option: File|Repo|Both
#' @return a data frame containing a list of script metadata
#' @export
#' @importFrom utils download.file
#' @importFrom utils url.show
#' @importFrom utils read.csv
#' @importFrom utils write.csv
#' @importFrom utils str
#' @importFrom yaml yaml.load
#' @importFrom yaml yaml.load_file
#' @importFrom RCurl url.exists
#' @importFrom git2r clone
#' @importFrom git2r init
#' @importFrom git2r is_empty
#' @importFrom stats setNames
#' @examples
#'   r1 <- build_script_df()
#'   r2 <- build_script_df(upd_opt = "file")
#'   r3 <- build_script_df(upd_opt = "repo")
#'   r4 <- build_script_df(upd_opt = "both")
#' @author Hanming Tu
#' @name build_script_df
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/08/2017 (htu) - initial creation
#  09/09/2017 (htu) - added work_dir, days_to_update, output_fn and
#                     output to a CSV file
#  09/12/2017 (htu) - used crt_workdir for work_dir and repo_dir
#  09/14/2017 (htu) - added upd_opt variable when fn_only is FALSE
#  09/19/2017 (htu) - added read.csv and write.csv to import form
#
build_script_df <- function(
  repo_url = 'https://github.com/phuse-org/phuse-scripts.git',
  repo_base ="https://github.com/phuse-org/phuse-scripts/raw/master",
  repo_dir = NULL,
  work_dir = NULL,
  output_fn = NULL,
  days_to_update = 7,
  fn_only = FALSE,
  upd_opt = NULL
) {
  # rm(list=ls())
  if (is.null(repo_url))     { sprintf("%s","repo is null"); return(); }
  if (!url.exists(repo_url)) { sprintf("%s",paste(repo_url, " does not exist!")); return(); }

  # path <- tempfile(pattern="git2r-")
  # cur_dir  <- getwd()
  # tmp_dir  <- tempdir()
  rp_name  <- gsub('.*\\/([\\-\\w]+).git$', '\\1', repo_url, perl=TRUE)
  # define output file name
  work_dir <- crt_workdir()
  if (is.null(output_fn))    { output_fn <- paste0(rp_name, '_yml.csv'); }
  wk_fn <- paste(work_dir, output_fn, sep = '/');
  # Only return the workdir
  if (is.null(upd_opt) && fn_only && file.exists(wk_fn)) { return(wk_fn); }

  if ( !is.null(upd_opt) && grepl("^(File|Both)", upd_opt, ignore.case = TRUE) ) {
    if (file.exists(wk_fn)) {file.remove(wk_fn)}
  }
  if (is.null(repo_dir)) { repo_dir <- paste(work_dir, rp_name, sep = '/'); }
  if (!is.null(upd_opt) && grepl("^(Repo|Both)", upd_opt, ignore.case = TRUE)) {
    if (dir.exists(repo_dir)) {
      if (chk_workdir(repo_dir)) {
        # only remove the dir if it is in the default workdir
        unlink(repo_dir, recursive = TRUE)
      }
    }
  }
  if (file.exists(wk_fn)) {
    f_inf <- file.info(wk_fn)
    to_update <- ifelse(f_inf[,5]>(Sys.time()-days_to_update*24*60*60),FALSE,TRUE);
  } else {
    to_update <- TRUE
  }
  if (!to_update) {
    if (fn_only && file.exists(wk_fn)) { return(wk_fn); }
    # read the file and return it
    str(paste("Reading CSV from ", wk_fn))
    r <- read.csv(file=wk_fn, header=TRUE, sep=",")
    return(r)
  }
  # we need to get it from the repository
  # if (is.null(repo_dir)) { repo_dir <- paste(tmp_dir, 'repo', rp_name, sep = '/'); }
  if (!dir.exists(repo_dir)) {
      dir.create(repo_dir, recursive = TRUE);
      str(paste("Clone to ", repo_dir))
      rp <- clone(repo_url,repo_dir)
  } else {
      str(paste("Reading Repo from ", repo_dir))
      rp <- init(repo_dir)
  }
  # git fetch origin && git reset --hard origin/master && git clean -f -d

  # fns <- list.files(repo_dir, recursive = TRUE, pattern = '.yml$', full.names = TRUE)
  fns <- list.files(repo_dir, recursive = TRUE, pattern = '.yml$')
  f1 <- vector(); f2 <- vector(); f3 <- vector()
  for (i in 1:length(fns)) {
      f1[i]  <- basename(fns[i])
      f2[i]  <- fns[i]
      f3[i]  <- paste(repo_dir,fns[i], sep = '/')
      # y <- yaml.load_file(fn)
  }
  r <- setNames(data.frame(matrix(ncol=5, nrow=length(f1))),
                c("fn_id", "file", "rel_path","file_url", "file_path"))
  for (i in 1:length(f1)) {
    r$fn_id[i] <- i; r$file[i] <- f1[i]; r$rel_path[i] <- f2[i];
    r$file_url[i]  <- paste(repo_base, f2[i], sep="/");
    r$file_path[i] <- f3[i]
  }
  str(paste("Writing CSV to ", wk_fn))
  write.csv(r, file = wk_fn, row.names=FALSE, na="")

  if (fn_only && file.exists(wk_fn)) { return(wk_fn); }
  return(r)
}
