#' Build Inputs from Script Metadata for Phuse Web Framework
#' @description Build R shiny code for Phuse Web Apps
#' @param fn a file name or URL pointing to script metadata file
#' @return R shiny code for providing inputs to the script
#' @export
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist2_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   r1 <- build_inputs(f1)
#' @author Hanming Tu
#' @name buiuld_inputs
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/13/2017 (htu) - initial creation
#
build_inputs <- function(fn = NULL) {
  # 1. check inputs
  if (is.null(fn)) { return(NULL) }
  cfg         <- read_yml(fn)
  if (is.null(cfg$Inputs)) {return(NULL) }

  # 2. extract input parameters
  #  p1: rnorm - radioButtons(...)
  #  p2: 50 - sliderInput(...)
  ps <- cfg$Inputs;
  r <- ''
  for (i in 1:length(ps)) {
    k <- names(ps[i])
    if (substr(k,1,1) != "p") { next; }
    v <- gsub('\\w+\\s+-','', ps[i])
    r <- ifelse(r=='', v, paste0(r, ",\n", v))
  }
  # r <- gsub("[\\]",'',r)
  return(r)
}

