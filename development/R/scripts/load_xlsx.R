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
setwd("C:/Users/hanming.h.tu/Google Drive/ACN/Codes/R")


library('openxlsx')
library(ROracle)
source("libs/Func_comm.R")
#
# 2. read sheets to data frames

sdir <- 'C:/Users/hanming.h.tu/Google Drive/ACN/C/A/QMDR5_3/Mapping'
ifn <- paste0(sdir,"/", "DefineMapping v1.5.xlsx")
c3 <- c("ELEM_MAP_ID", "ELEMENT_ID", "PARENT_ELEMENT_NAME","ELEMENT_NAME","MAP_GROUP", "MAP_TYPE", 
        "SRC_TYPE", "SRC_VALUETYPE", "SRC_TABLE", "SRC_COLUMN", "SRC_VALUE", "SRC_DATATYPE", 
        "SRC_CONDITION", "MAPPING_INSTRUCTION", 
        "TGT_TYPE", "TGT_VALUETYPE", "TGT_TABLE", "TGT_COLUMN", "TGT_VALUE", "TGT_DATATYPE",
        "TGT_CONDITION") 
c4 <- c("ATTR_MAP_ID","ATTRIBUTE_ID", "ELEMENT_NAME","ATTRIBUTE_NAME","MAP_GROUP", "MAP_TYPE", 
        "SRC_TYPE", "SRC_VALUETYPE", "SRC_TABLE", "SRC_COLUMN", "SRC_VALUE", "SRC_DATATYPE", 
        "SRC_CONDITION", "MAPPING_INSTRUCTION", 
        "TGT_TYPE", "TGT_VALUETYPE", "TGT_TABLE", "TGT_COLUMN", "TGT_VALUE", "TGT_DATATYPE",
        "TGT_CONDITION") 

df1 <- read.xlsx(ifn, sheet = 1)[1:20]
df2 <- read.xlsx(ifn, sheet = 2)[1:16]
df3 <- read.xlsx(ifn, sheet = 3)[c3]
df4 <- read.xlsx(ifn, sheet = 4)[c4]
# sapply(df2, class)
# df2$ColB <- convertToDate(df2$ColB)
# sapply(df2, class)

#
# 3. connect to Oracle database
#
con <- get_conn("std_mdr", "std_mdr", "adevscan.adevgns.orst.com",service_name="adevpdb")
# d <- dbReadTable(con, "QT_CLASSES")
# dbDisconnect(con)

#
# 4. create temporary tables
#
Sys.setenv(TZ = "EST")
Sys.setenv(ORA_SDTZ = "EST")
tb<-list(xe="QT_XML_ELEMENTS", xa="QT_XML_ATTRIBUTES", em="QT_ELEM_MAPPINGS",am="QT_ATTR_MAPPINGS")
tt<-list(xe="T_XML_ELEMENTS", xa="T_XML_ATTRIBUTES", em="T_ELEM_MAPPINGS",am="T_ATTR_MAPPINGS")


if (dbExistsTable(con, tt$xe, schema = NULL)) {
  rs1 <- dbSendQuery(con, paste("drop table ", tt$xe))
} 
dbWriteTable(con,tt$xe,df1)

if (dbExistsTable(con, tt$xa, schema = NULL)) {
  rs2 <- dbSendQuery(con, paste("drop table ", tt$xa))
}
dbWriteTable(con,tt$xa,df2)

if (dbExistsTable(con, tt$em, schema = NULL)) {
  rs3 <- dbSendQuery(con, paste("drop table ", tt$em))
}
dbWriteTable(con,tt$em,df3)

if (dbExistsTable(con, tt$am, schema = NULL)) {
  rs4 <- dbSendQuery(con, paste("drop table ", tt$am))
}
dbWriteTable(con,tt$am,df4)


#
# 5. insert the records to target tables
#
cmd1 <- paste("insert into ", tb$xe, "select * from ", tt$xe)
cmd2 <- paste("insert into ", tb$xa, "select * from ", tt$xa)
cmd3 <- paste("insert into ", tb$em, "select * from ", tt$em)
cmd4 <- paste("insert into ", tb$am, "select * from ", tt$am)

c1 <- paste("alter table ", tb$xa, " disable constraint qt_xml_element_attribute_r1")
c2 <- paste("alter table ", tb$em, " disable constraint qt_xml_element_mapping_r1")
c3 <- paste("alter table ", tb$am, " disable constraint qt_xml_attr_mapping_r1")
r1.c1 <- dbSendQuery(con, c1)
r1.c2 <- dbSendQuery(con, c2)
r1.c3 <- dbSendQuery(con, c3)

r1.tru <- dbSendQuery(con, paste("truncate table", tb$xe))
r1.ins <- dbSendQuery(con, cmd1)
if (dbHasCompleted(r1.ins)) {
  r1.cmt <- dbSendQuery(con, "commit")  
}

r2.tru <- dbSendQuery(con, paste("truncate table", tb$xa))
r2.ins <- dbSendQuery(con, cmd2)
if (dbHasCompleted(r2.ins)) {
  r2.cmt <- dbSendQuery(con, "commit")  
}

r3.tru <- dbSendQuery(con, paste("truncate table", tb$em))
r3.ins <- dbSendQuery(con, cmd3)
if (dbHasCompleted(r3.ins)) {
  r3.cmt <- dbSendQuery(con, "commit")  
}

r4.tru <- dbSendQuery(con, paste("truncate table", tb$am))
r4.ins <- dbSendQuery(con, cmd4)
if (dbHasCompleted(r4.ins)) {
  r4.cmt <- dbSendQuery(con, "commit")  
}


c1 <- paste("alter table ", tb$xa, " enable constraint qt_xml_element_attribute_r1")
c2 <- paste("alter table ", tb$em, " enable constraint qt_xml_element_mapping_r1")
c3 <- paste("alter table ", tb$am, " enable constraint qt_xml_attr_mapping_r1")
r1.c1 <- dbSendQuery(con, c1)
r1.c2 <- dbSendQuery(con, c2)
r1.c3 <- dbSendQuery(con, c3)



# End of the program 




