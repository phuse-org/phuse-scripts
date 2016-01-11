# HEADER
# Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Treatment
# White paper: Central Tendency
# Specs:       https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/
# Output:      https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_r/
# Contributors: Jeno Pizarro, Suzie Perigaud


#TESTING and QUALIFICATION:
#DEVELOP STAGE
#12-JUL-2015, Jeno - Initial scripting
#30-AUG-2015, Suzie - add out of limit red dots and horizontal lines
#29-NOV-2015, Jeno  - edited to use ADaM only
#10-JAN-2016, Jeno - allow user to select treatment arm variable, population flag
##turn on or off horizontal lines, red outliers, select TIFF, JPEG, or PNG and choose file size
##rename arms (if they are too long), automatically read in CSV or XPT
##logic to split visits across pages automatically

#ggplot2, data.table, gridExtra, Hmisc (for xpt import) required, if not installed, program will error.
library(ggplot2)
library(data.table)
library(gridExtra)
library(Hmisc)
library(tools)

#Which treatment arm variable?
treatmentname <- "TRTA" #TRTA, TRTP, etc

#Rename Treatment Arms? (if you wish to display shorter names)
useshortnames <-TRUE #TRUE OR FALSE
oldnames <- c("Xanomeline Low Dose","Xanomeline High Dose")
newnames <- c("X-low", "X-High")

#subset on a population flag?
usepopflag <- TRUE #TRUE OR FALSE
popflag <- "SAFFL"

#test or parameter to be analyzed
testname <- "DIABP"
yaxislabel <- "Diastolic Blood Pressure (mmHG)"
#visit numbers to be analyzed
selectedvisits <-c(0,2,4,6,8,12,16,20,24)
#how many visits to display per page?
perpage <- 5
#number of digits in table, standard deviation = dignum +1
dignum <- 1

#Configure Upper and Lower Limits to highlight outliers in red and display horizontal lines
##Highlight outliers above/below limits?
redoutliers <- TRUE #TRUE or FALSE
##Draw horizontal lines>
horizontallines <- TRUE #TRUE or FALSE
##Input lower / upper limits or use ANRLO, ANRHI values in data?
##If using values in data, they should be uniform if displaying horizontal lines
enterlimits <- TRUE #TRUE = enter own limits, FALSE = use ANRLO/ANRHI in data
#Manually enter limits below
#lower limit(s) - ANRLO <- 50
ANRLO <- 50
#upper limit(s) - ANRHI <- 100
ANRHI <- 100

#set input and output file directories
inputdirectory <- "/Users/jeno/Dropbox/Jeno/Professional Development/"
outputdirectory <- "/Users/jeno/Dropbox/Jeno/Professional Development/"
#accepts CSV or XPT files
testfilename <- "advs.xpt" #"advs.xpt"
#output file type - TIFF or JPEG. 
filetype <- "PNG"  #"TIFF", "JPEG", or "PNG"
#choose output file size: pixel width and height
pixelwidth <- 1200
pixelheight <- 1000
#choose output font size
outputfontsize <- 16
#Title for the chart
charttitle <- "Box and Whisker Plot Title" #in quotes

#Read in DATASET
if (file_ext(testfilename) == "csv") {
  testresultsread <- read.csv(file.path(inputdirectory,testfilename))
} else {
  testresultsread <-
    sasxport.get(file.path(inputdirectory,testfilename), lowernames = FALSE)
}

#buildtable function to be called later, summarize data to enable creation of accompanying datatable
buildtable <- function(avalue, dfname, by1, by2, dignum){
  byvarslist <- c(by1,by2)
  summary <- eval(dfname)[,list(
    n = .N,
    mean = round(mean(eval(avalue), na.rm = TRUE), digits=dignum),
    sd = round(sd(eval(avalue), na.rm = TRUE), digits=dignum+1),
    min = round(min(eval(avalue), na.rm = TRUE), digits=dignum),
    q1 = round(quantile(eval(avalue), .25, na.rm = TRUE), digits=dignum),
    mediam = round(median(eval(avalue), na.rm = TRUE), digits=dignum),
    q3 = round(quantile(eval(avalue), .75, na.rm = TRUE), digits = dignum),
    max = round(max(eval(avalue), na.rm = TRUE), digits = dignum)
  ), 
  by = byvarslist]
  
  return(summary)
}

#SELECT VARIABLES (examples in parenthesis): TREATMENT (TRTP, TRTA), PARAMCD (LBTESTCD)
#colnames(testresults)[names(testresults) == "OLD VARIABLE"] <- "NEW VARIABLE"

colnames(testresultsread)[names(testresultsread) == treatmentname] <- "TREATMENT"

colnames(testresultsread)[names(testresultsread) == popflag] <- "FLAG" #select population flag to subset on such as SAFFL or ITTFL

if (useshortnames == TRUE){
for(i in 1:length(oldnames)) {
  testresultsread$TREATMENT <- ifelse(testresultsread$TREATMENT == oldnames[i], as.character(newnames[i]), as.character(testresultsread$TREATMENT))
}
}

#determine number of pages needed
  initial <- 1
  visitsplits <- ceiling((length(selectedvisits)/perpage))
#for each needed page, subset selected visits by number per page
for(i in 1:visitsplits) {

#subset on test, visits, population to be analyzed
if (usepopflag == TRUE){
testresults <- subset(testresultsread, PARAMCD == testname & AVISITN %in% selectedvisits[(initial):
                      (ifelse(perpage*i>length(selectedvisits),length(selectedvisits),perpage*i))] 
                      & FLAG == "Y")

} else {
testresults <- subset(testresultsread, PARAMCD == testname & AVISITN %in% selectedvisits[(initial):(perpage*i)])  
}
initial <- initial + perpage
testresults<- data.table(testresults)

#setkey for speed gains when summarizing
setkey(testresults, USUBJID, TREATMENT, AVISITN)

#create a variable for the out of limits data
if (enterlimits == TRUE){
testresults$OUT <- ifelse(testresults$AVAL < ANRLO | testresults$AVAL > ANRHI, testresults$AVAL, NA)
} else if (enterlimits == FALSE){
testresults$OUT <- ifelse(testresults$AVAL < testresults$ANRLO | testresults$AVAL > testresults$ANRHI, testresults$AVAL, NA)
} else {print("WARNING - Manual entry of limits or automatic usage of limits in data not defined")}
#specify plot
p <- ggplot(testresults, aes(factor(AVISITN), fill = TREATMENT, AVAL))
# add notch, axis labels, legend, text size
p1 <- p + geom_boxplot(notch = TRUE) + xlab("Visit Number") + ylab(yaxislabel) + theme(legend.position="bottom", legend.title=element_blank(), 
                                                                                       text = element_text(size = outputfontsize),
                                                                                       axis.text.x  = element_text(size=outputfontsize),
                                                                                       axis.text.y = element_text(size=outputfontsize)) +ggtitle(charttitle)
# add mean points
p2 <- p1 + stat_summary(fun.y=mean, colour="dark red", geom="point", position=position_dodge(width=0.75))
# out of limits jittered red points
p3 <- p2 + geom_jitter(data = testresults, aes(factor(AVISITN), testresults$OUT), colour = "dark red", position = position_dodge(width=0.75))
# horizontal limit lines
if(enterlimits == TRUE){
p4 <- p2 + geom_hline(yintercept = c(ANRLO,ANRHI), colour = "red")
pall <- p3 + geom_hline(yintercept = c(ANRLO,ANRHI), colour = "red")
} else if (enterlimits == FALSE) {
p4 <- p2 + geom_hline(yintercept = c(testresults$ANRLO,testresults$ANRHI), colour = "red")
pall <- p3 + geom_hline(yintercept = c(testresults$ANRLO,testresults$ANRHI), colour = "red") 
}
#call summary table function
summary <- buildtable(avalue = quote(AVAL), dfname= quote(testresults), by1 = "AVISITN", by2 = "TREATMENT", dignum)[order(AVISITN, TREATMENT)]
table_summary <- data.frame(t(summary))           

t1theme <- ttheme_default(core = list(fg_params = list (fontsize = outputfontsize)))
t1 <- tableGrob(table_summary, theme = t1theme, cols = NULL) 

if (filetype == "TIFF"){
#Output to TIFF
tiff(file.path(outputdirectory,paste("plot",i,".TIFF",sep = "" )), width = pixelwidth, height = pixelheight, units = "px", pointsize = 12)
if (redoutliers == TRUE & horizontallines == TRUE) { 
  grid.arrange(pall, t1, ncol = 1)
} else if (redoutliers == TRUE & horizontallines == FALSE) {
  grid.arrange(p3, t1, ncol = 1)
} else if (redoutliers == FALSE & horizontallines == TRUE) {
  grid.arrange(p4, t1, ncol = 1)
} else {
  grid.arrange(p2, t1, ncol = 1)
  }
dev.off()
}
if (filetype == "JPEG") { 
# Optionally, use JPEG
jpeg(file.path(outputdirectory,paste("plot",i,".JPEG",sep = "" )), width = pixelwidth, height = pixelheight, units = "px", pointsize = 12)
if (redoutliers == TRUE & horizontallines == TRUE) { 
  grid.arrange(pall, t1, ncol = 1)
} else if (redoutliers == TRUE & horizontallines == FALSE) {
  grid.arrange(p3, t1, ncol = 1)
} else if (redoutliers == FALSE & horizontallines == TRUE) {
  grid.arrange(p4, t1, ncol = 1)
} else {
  grid.arrange(p2, t1, ncol = 1)
}
dev.off()
}
if (filetype == "PNG") { 
  # Optionally, use PNG
  png(file.path(outputdirectory,paste("plot",i,".PNG",sep = "" )), width = pixelwidth, height = pixelheight, units = "px", pointsize = 12)
  if (redoutliers == TRUE & horizontallines == TRUE) { 
    grid.arrange(pall, t1, ncol = 1)
  } else if (redoutliers == TRUE & horizontallines == FALSE) {
    grid.arrange(p3, t1, ncol = 1)
  } else if (redoutliers == FALSE & horizontallines == TRUE) {
    grid.arrange(p4, t1, ncol = 1)
  } else {
    grid.arrange(p2, t1, ncol = 1)
  }
  dev.off()
}
}
