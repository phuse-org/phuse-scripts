#' Plot Distribution
#' @description extract folders and file names from a list containing script metadata.
#' @param lst a list containing script metadata
#' @return a data frame (subdir, filename) containing parsed file names
#' @name extract_fns
#' @export
#' @author Hanming Tu
# Function Name: extract_fns
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/13/2017 (htu) - initial creation
#

library(phuse)
# 1. get the script name and YML name
script_name <- sys.frame(1)$ofile
str(sys.frame(1)$ofile)
yml_name    <- gsub('.([[:alnum:]]+)$','_\\1.yml', script_name)
if (length(yml_name) < 1) {
  if (exists("input") && !is.null(input$yml_name)) {
    yml_name <- input$yml_name
  } else {
    yml_name <- commandArgs()[2]
  }
}
if (length(yml_name) < 1) {
  cat("ERROR: could not find YML file name")
  return()
}

# 2. read the YML content to cfg list
cfg         <- read_yml(yml_name)

# 3. extract input parameters
#  p1: rnorm - radioButtons(...)
#  p2: 50 - sliderInput(...)
p1 <- cfg$Inputs$p1
p2 <- cfg$Inputs$p2
# we need to remove any R Shiny specification here
dn <- gsub('\\s+-.+','', p1)
nn <- as.numeric(gsub('\\s+-.+','', p2))
# 4. check if you have inputs from interactive session
if (exists("input")) {
  dn <- ifelse(is.null(input$dn), dn, input$dn)
  nn <- ifelse(is.null(input$nn), nn, input$nn)
}
# str(commandArgs())
d <- eval(call(dn, nn))
hist(d, main = paste(dn, "(", n, ")", sep = ""),col="#75AADB", border = "white")
