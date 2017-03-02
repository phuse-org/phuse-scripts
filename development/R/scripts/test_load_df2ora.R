# Name:
# Purpose: Read xlsx
# Developer
#   11/14/2016 (htu) - initial creation
#
# 1. load the required libraries
# Clear All
rm(list=ls())

# check if packages installed and then install if necessary
packages <- c('openxlsx','ROracle','yaml')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))
}
library('openxlsx')
library(ROracle)
library(yaml)

# 2. read configuration file and set environment
cfg <- yaml.load_file('scripts/test_load_df2ora.yml')

setwd(cfg$work_dir)
source(cfg$lib_file)


#
# 3. read sheets to data frames
ifn <- cfg$source_file
tgt_tab <- cfg$table_info$tgt_tab
df <- read.xlsx(ifn, sheet = 1)

#
# 4. connect to Oracle database
#
usr <- cfg$oracle_cs$usr
pwd <- cfg$oracle_cs$pwd
hn  <- cfg$oracle_cs$host
sn  <- cfg$oracle_cs$service_name
con <- get_conn(usr, pwd, hn, service_name = sn)

#
# 5. load the dataframe to Oracle table
#
tgt_tab <- cfg$table_info$tgt_tab

load.df2ora(con,df,tgt_tab)

# End of the program
