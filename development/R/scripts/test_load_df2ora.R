# Name:
# Purpose: Read xlsx file and upload it to an Oracle table
# Developer
#   11/14/2016 (htu) - initial creation
#   03/02/2017 (htu) - added YML configuration
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
cfg <- yaml.load_file('C:/Users/hanming.h.tu/Documents/R/scripts/test_load_df2ora.yml')

curWorkDir <- getwd()
if ("work_dir" %in% names(cfg)) { setwd(cfg$work_dir) }
if (is.null(cfg[["files"]])) { stop("Could not find input files.") }
if (is.null(cfg[["table_info"]])) { stop("Could not find table names.") }

fns <- cfg$files

if ("lib_file" %in% names(fns)) { source(fns$lib_file) }

#
# 3. read sheets to data frames
if ("source_file" %in% names(fns)) { ifn <- fns$source_file }
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
tab <- cfg$table_info
tgt_tab <- NULL
if ("tgt_tab" %in% names(tab)) { tgt_tab <- tab$tgt_tab }

if (is.null(tgt_tab)) { stop("Could not find target table name.") }
load.df2ora(con,df,tgt_tab)

setwd(curWorkDir)
# End of the program
