# Name:
# Purpose: Read xml and load into an Oracle table
# Developer
#   12/19/2016 (htu) - initial creation
#
# 1. load the required libraries
# Clear All
rm(list=ls())

# check if packages installed and then install if necessary
packages <- c('XML','ROracle','plyr','RCurl')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))
}
library("XML")      # Load the package required to read XML files.
library("methods")  # Also load the other required package.
library(ROracle)
library(plyr)
library(RCurl)
setwd("C:/Users/hanming.h.tu/Google Drive/ACN/Codes/R")
source("libs/Func_comm.R")

# 2. read the xml file
# Give the input file name to the function.
# xfn <- 'C:/Users/hanming.h.tu/Google Drive/ACN/C/A/QMDR5_3/define_xml_2_0_releasepackage20140424/sdtm/define2-0-0-example-sdtm.xml'
# url <- 'https://drive.google.com/open?id=0B6yBXwWAdpcTWTFJWlRWWVItc1k'
# x1 <- getURL(url)
xfn <- 'data/define2_sdtm.xml'

#rst <- xmlTreeParse(file = xfn, addAttributeNamespaces = TRUE, useInternalNode=TRUE)
# rst <- xmlParse(file = xfn, addAttributeNamespaces = TRUE, useInternalNode=TRUE)
# rst <- xmlParse(file = url)
rst <- xmlParse(file = xfn)
top <- xmlRoot(rst)
ta <- xmlAttrs(top)
t1 <- top[which(names(top) != "comment")]

#Root Node's children
xmlSize(t1[[1]]) #number of nodes in each child
xmlSApply(t1[[1]], xmlName) #name(s)
xmlSApply(t1[[1]], xmlAttrs) #attribute(s)
xmlSApply(t1[[1]], xmlSize) #size

xpathSApply(top, "//ODM", xmlGetAttr, 'ODMVersion')
v1 <- xpathSApply(t1, "//ODM/Study/GlobalVariables/StudyName", xmlValue)

# https://hopstat.wordpress.com/2014/01/14/faster-xml-conversion-to-data-frames/
xmlToDF(t1, xpath='/Study/GlobalVariables')

ldply(xmlToList(url), function(x) { data.frame(x[!names(x)=="comment"]) } )


for (n in names.XMLNode(top)) {
  if (n == "comment") { next }
  print(n)
}


pl <- xmlSApply(top[which(names(top) != "comment")], function(x) xmlSApply(x[which(names(x) != "comment")], xmlValue))
pl <- xmlSApply(top, function(x) xmlSApply(x, xmlAttrs))

top[c("comment")]



xpathSApply(rst, "/ODM/Study/GlobalVariables/StudyName" , xmlValue)

ns <- getNodeSet(rst, '/ODM/Study')

element_cnt <-length(ns)

strings<-paste(sapply(ns, function(x) { xmlValue(x) }),collapse="|"))


# 3. create the data frame
df1 <- data.frame( XML_ID = 1,
                  XML_TYPE = 'Define',
                  XML_DOC = rst,
                  CREATED = '12/19/2016',
                  RUN_ID = 1,

                  JOB_ID = 1
)

#
# 3. connect to Oracle database
#
con <- get_conn("std_mdr", "std_mdr", "adevscan.adevgns.orst.com",service_name="adevpdb")

#
# 4. create temporary tables
#
Sys.setenv(TZ = "EST")
Sys.setenv(ORA_SDTZ = "EST")
tb1 <- "T_XMLS"
tb2 <- "QT_XMLS"

if (dbExistsTable(con, tb1, schema = NULL)) {
  rs1 <- dbSendQuery(con, paste("drop table ", tb1))
}
dbWriteTable(con,tb1,df1)

#
# 5. insert the records to target tables
#
cmd1 <- paste("insert into ", tb2, "select * from ", tb1)


r1.tru <- dbSendQuery(con, paste("truncate table", tb2))
r1.ins <- dbSendQuery(con, cmd1)
if (dbHasCompleted(r1.ins)) {
  r1.cmt <- dbSendQuery(con, "commit")
}


# End of the program

