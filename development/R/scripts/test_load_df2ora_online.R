# Name:
# Purpose: source a R script from repository and run it locally
# Developer
#   03/02/2017 (htu) - initial creation
#
# 1. load the source code

rm(list=ls())
curWorkDir <- getwd()

cfg <- yaml.load_file('https://github.com/phuse-org/phuse-scripts/raw/master/development/R/scripts/test_load_df2ora.yml')
cfg <- yaml.load_file('C:/Users/hanming.h.tu/Documents/R/scripts/test_load_df2ora.yml')

tmpWorkDir <- download_script(cfg)
cfg <- init_cfg(cfg)



source('https://github.com/phuse-org/phuse-scripts/blob/master/development/R/scripts/test_load_df2ora.R')

source('scripts/test_load_df2ora.R')

# End of the program
