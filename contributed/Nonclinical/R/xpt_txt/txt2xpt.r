# Script to convert SEND data from txt format to *.xpt
#
# The txt file is assumed to be in the format produced by the companion script xpt2txt.r after it has been
# read into Excel and written as a *.txt file with tab as the field seperater character. However, only columns 
# with a variable name are produced in the *.xpt file.  This feature enables you to include additional columns to
# help you prepare the contents of columns you want included in the xml output by leaving the variable name blank for these columns
#
#
# Use the sas command like this to see the names, variables, and variable types in the resulting dataset: 
#     proc contents data=work.bw;
#     run;
#
# SASxport documentation here:
# https://cran.r-project.org/web/packages/SASxport/SASxport.pdf
####################################################################################
# You may need next two lines first time
# install.packages("SASxport")
####################################################################################
library(SASxport)
require(utils)
library(plyr)
library(stringr)
sepchar <- "\t"
source("https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/CreatingXPT/write.xport2.R")
#scat <- function(message) #this can print out diagnostic steps within write.xport2.R
if(packageVersion("SASxport") < "1.5.7") {
  stop("You need version 1.5.7 or later of SASxport")
}
myInFile <- choose.files(caption = "Select XLS file",multi=F,filters=cbind('.txt files','*.txt'))
p <- dirname(myInFile)
f <- basename(myInFile)
myInLine <- readLines(myInFile)
domain_name  <- str_trim(myInLine[1])  #read the domain name trimming off the tabs at the end introduced by Excel
domain_label <- str_trim(myInLine[2])  #read the domain label trimming off the tabs at the end introduced by Excel
# identify the columns that have a non-blank value in the variable names row.
keep <- c()
row <- strsplit(myInLine[5],sepchar)
for (i in 1:length(row[[1]]))
{
    if (row[[1]][i]!="")
    {
      keep <- c(keep,i)
    }
}

#read the variable labels
row <- strsplit(myInLine[3],sepchar)
variable_labels <- row[[1]][keep]
#give error if any lable is more than 40 characters
for (i in 1:length(variable_labels))
{
    if (nchar(variable_labels[i])>40)
    {
      print(paste( c("Warning: varialbe label '",variable_labels[i], "' is longer than 40 characters."), collapse=""))
    }
}

#read the variable types
row <- strsplit(myInLine[4],sepchar)
column_types_all <- row[[1]];
variable_types <- row[[1]][keep]
#give error if any lable is anythng other than "character" or "numeric"
for (i in 1:length(variable_types))
{
  if ((variable_types[i] == "character") || (variable_types[i] == "numeric"))
  {
  }
  else
  {
    print(paste( c("Warning: varialbe label '",variable_labels[i], "' has a type that is neither 'character' nor 'numeric'."), collapse=""))
  }
}

#read the variable names
row <- strsplit(myInLine[5],sepchar)
variable_names <- row[[1]][keep]
#give error if any name is more than 8 characters
for (i in 1:length(variable_labels))
{
  if (nchar(variable_names[i])>8)
  {
    print(paste( c("Warning: varialbe name '",variable_labels[i], "' is longer than 8 characters."), collapse=""))
    # I should improve this to prevent errors later.
  }
}

df1 <- read.table(paste(p,f,sep="/"), sep = sepchar, colClasses=column_types_all, skip = 4, header=TRUE, comment.char = "", flush=TRUE, stringsAsFactors = FALSE)
# check the variable types:
# for (i in colnames(df1)){print(class(df1[[i]]))}

#Prepare the data to be written to the *.xpt file
# Remove the columns that aren't to be kept.
studyData <- df1[,keep]
# give the dataset a label
label(studyData) <- domain_label
# give each variable a label
for (i in 1:length(variable_labels))
{
  label(studyData[[i]]) <- variable_labels[i]
}

# Set length for character fields: Not needed when tested Dec 2018
# SASformat(studyData$DOMAIN) <-"$2."	

# place this dataset into a list with a name
aList = list(studyData)
# assign the dataset name to it
names(aList)[1]<- domain_name
# write out dataframe
aLine <- paste("Creating file:  ", p, "/",sub("txt","xpt",f),sep = "")
print(aLine)
write.xport(
  list=aList,
  file = paste(p, "/",sub("txt","xpt",f),sep = ""),
  verbose=FALSE,
  sasVer="7.00",
  osType = str_match(R.version.string,"[0-9]+.[0-9]+.[0-9]+"),
  cDate = Sys.time(),
  formats=NULL,
  autogen.formats=FALSE
)
# known issues:
#  * I would like the script to be able to process an entier study at a time.