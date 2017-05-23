#' Initialize configuration for phuse
#' @description read script metadata file in the repository and merged it
#'   with a local script metadata file if it exists.
#' @param cfg a list containing script metadata information
#' @return a list containing the merged configuration
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

  for (k1 in names(a)) {
    if (!is.list(a[[k1]])) {
      if (k1 %in% names(b)) {a[[k1]] <- b[[k1]]}
      next();
    }
    for (k2 in names(a[[k1]])) {
      if (!is.list(a[[k1]][[k2]])) {
        if (k2 %in% names(b[[k1]])) {a[[k1]][[k2]] <- b[[k1]][[k2]]}
        next();
      }
      for (k3 in names(a[[k1]][[k2]])) {
        if (!is.list(a[[k1]][[k2]][[k3]])) {
          if (k3 %in% names(b[[k1]][[k2]])) {
            a[[k1]][[k2]][[k3]] <- b[[k1]][[k2]][[k3]]
          }
          next();
        }
        for (k4 in names(a[[k1]][[k2]][[k3]])) {
          if (k4 %in% names(b[[k1]][[k2]][[k3]])) {
            a[[k1]][[k2]][[k3]][[k4]] <- b[[k1]][[k2]][[k3]][[k4]]
          }
        }
      }
    }
  }
  # merge the two lists
  cfg <- mapply(c, a, b, SIMPLIFY = FALSE)
  return(cfg)
}
