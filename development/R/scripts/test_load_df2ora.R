# Name:
# Purpose: Read xlsx
# Developer
#   11/14/2016 (htu) - initial creation
#
# 1. load the required libraries
# Clear All
rm(list=ls())

# check if packages installed and then install if necessary
packages <- c('openxlsx','ROracle')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))
}
setwd("./Codes/R")


library('openxlsx')
library(ROracle)
source("libs/Func_comm.R")
#
# 2. read sheets to data frames

sdir <- 'data'
ifn <- paste0(sdir,"/", "testfile.xlsx")

df <- read.xlsx(ifn, sheet = 1)

#
# 3. connect to Oracle database
#
con <- get_conn("std_mdr", "std_mdr", "test.orst.com",service_name="adevpdb")

#
# 4. create temporary tables
#
tgt_tab <- 'XXX_TEST'
load.df2ora(con,df,tgt_tab)


# End of the program




