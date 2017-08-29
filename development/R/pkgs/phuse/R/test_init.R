#' Test init file
#' @description Test the init_cfg
#' @name test_init
#' @export
#' @importFrom utils install.packages
#' @importFrom utils installed.packages
#' @importFrom utils str
#' @importFrom yaml yaml.load_file
#
# You can learn more about package authoring with RStudio at:
#   http://r-pkgs.had.co.nz/
# Some useful keyboard shortcuts for package authoring:
#   Build and Reload Package:  'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'
#
# Purpose: source a R script from repository and run it locally
# Developer
#   03/02/2017 (htu) - initial creation
#
# 1. load the source code
# library('yaml')
test_init <- function() {
  rm(list=ls())
  p <- c('yaml')
  if (length(setdiff(p, rownames(installed.packages()))) > 0) { install.packages(setdiff(p, rownames(installed.packages()))) }
  # library(yaml)
  curWorkDir <- getwd()

  c1 <- yaml.load_file('https://github.com/phuse-org/phuse-scripts/raw/master/development/R/scripts/test_load_df2ora_rep.yml')
  str(c1)
  c2 <- yaml.load_file('/Users/htu/Repos/github/phuse-scripts/trunk/development/R/scripts/test_load_df2ora_loc.yml')
  str(c2)
  c3 <- merge_lists(c1,c2)
  str(c3)

# tmpWorkDir <- download_script(cfg)
# cfg <- init_cfg(cfg)


# source('https://github.com/phuse-org/phuse-scripts/blob/master/development/R/scripts/test_load_df2ora.R')

# source('scripts/test_load_df2ora.R')

# End of the program
}
