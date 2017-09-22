#' Plot Distribution
#' @description extract folders and file names from a list containing script metadata.
#' @param lst a list containing script metadata
#' @return a data frame (subdir, filename) containing parsed file names
#' @name draw_dist2
#' @export
#' @author Hanming Tu
# Function Name: draw_dist2
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/17/2017 (htu) - initial creation
#

library(phuse)
# 1. get the script name and YML name
script_name <- sys.frame(1)$ofile
str(paste0("D2: ", script_name))
commandArgs()
pm <- get_inputs(script_name)
str(pm)

# we need to remove any R Shiny specification here
dn <- pm[1]
nn <- as.numeric(pm[2])
d <- eval(call(dn, nn))
t <- paste(dn, "(", nn, ")", sep = "")
hist(d, main = t,col="#75AADB", border = "white")

