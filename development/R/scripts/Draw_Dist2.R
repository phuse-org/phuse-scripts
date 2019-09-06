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
# the fn() is from phuse web frame work to provide selected YML file full path and name 
yml_fn <- fn(); 
inYML <- get_inputs(yml_fn)
cfgYML <- read_yml(yml_fn)

# we need to remove any R Shiny specification here
dn <- ifelse(is.null(input$p1), cfgYML$Inputs$p1, input$p1);
nn <- ifelse(is.null(input$p2), cfgYML$Inputs$p2, input$p2);
d <- eval(call(dn, nn))
t <- paste(dn, "(", nn, ")", sep = "")
hist(d, main = t,col="#75AADB", border = "white")

