# This script transforms the selected *.xpt file into a *.txt file suitable to be opened in Excel.
# The "txt" extention is used instead of "csv" to avoid Excel's automatic conversion of what it thinks are dates into its date format.
# 
# 1. Open Excel, File, Open, select the file *.txt file.  Text Import wizard opens.
# 2. Select Delimited
# 3. Start import at row 1
# 4. click the check-box to indicate "My data has headers."
# 5. Click Next to get to Step 2 of 3 in the Wizard.
# 6. Click the check-box to indicate Tab is the delimiter.
# 7. Click Next to get to Step 3 of 3 in the Wizard.
# 8. Use the scroll bar and Shift-Click to Select all the columns, Choose "Text" as the column format, Click Finish.
#
# Do the following to keep the column headers on the screen when scrolling through the data
# 1. Scroll down so you see the headers you want to see 
# 2. Select the cell that is in the first row of data and in the first column you want to scroll left or right.
# 3. Select View from the menu, Window section from the ribon, Freeze Panes
#
# When you are done editing the file
# 1. Select the File menu in Excel, Export, Change File Type, in the Other File Types choose "Text (Tab delimited)"
# 2. Click "Save As" and specify a file location and name.

library(SASxport)
library(plyr)
sepchar <- "\t";
myInFile <- choose.files(caption = "Select XLS file",multi=F,filters=cbind('.xpt files','*.xpt'))
p <- dirname(myInFile)
# lookup.xport("c:/sas-play/dm.xpt") #prints a subset of the domain attributes in an easy to read format
f <- basename(myInFile)
DomainA <-read.xport(paste( c(p,f), collapse="/")) #reads the domain data
HeaderA <- lookup.xport(paste( c(p,f), collapse="/")) #read the dataset metadata
# HeaderA[1] #shows the contests of the header fields
domain_name=attr(HeaderA,"names") #This is the domain name like DM
domain_label=attr(HeaderA[[domain_name]],"label") #This is the domain label like DEMOGRAPHICS
variable_labels=HeaderA[[domain_name]]$label #This is a list of the variable labels (up to 40 characters each)
variable_types=HeaderA[[domain_name]]$type #This is a list of the variable types like "character" "character" "numeric" "character" ...
variable_names=HeaderA[[domain_name]]$name #This is a list of the variable names (up to 8 characters each)
# Ready to write the results
f2 <- sub("\\.xpt","\\.txt",f, ignore.case = TRUE)
myOutFile <- file(paste(c(p,f2),collapse="/"),"w")
writeLines(domain_name,myOutFile)
writeLines(domain_label,myOutFile)
writeLines(paste(variable_labels,sep="",collapse=sepchar),myOutFile)
writeLines(paste(variable_types,sep="",collapse=sepchar),myOutFile)
writeLines(paste(variable_names,sep="",collapse=sepchar),myOutFile)
write.table(DomainA,myOutFile,append = TRUE, sep =sepchar, row.names=FALSE, col.names=FALSE)
close(myOutFile)
#write.table(DomainA,paste(c(p,f2),collapse="/"),append = TRUE, sep = sepchar, row.names=FALSE, col.names=TRUE)
