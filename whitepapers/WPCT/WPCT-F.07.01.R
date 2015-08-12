# HEADER
# Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Planned Treatment
# White paper: Central Tendency
# Specs:       https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/    !YML needed!
# Output:      https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_r/
# Contributors: Jeno Pizarro, Suzie Perigaud

#TO DO List for program:
#*Test using ADaM, TRT01A / AVAL instead of ACTARM / LBSTRESN
#*SDTM based off LB, make more generic for use in any results domain
#*Tested with only 5 visits, functionality to move to next page when there are more, etc
#*red plots for outside normal range 
#*plot means?
#*move table closer below plot?
#*annotations

#TESTING and QUALIFICATION:
#DEVELOP STAGE
#12-JUL-2015, ran without errors using STATIN TEST DATA v0 - DM, LB csvs 

#ggplot2, data.table, gridExtra required, if not installed, program will quit.
library(ggplot2)
library(data.table)
library(gridExtra)

#SDTM or ADaM?
datastandard <- "SDTM"

#set input and output file directories
inputdirectory <- "path/"
outputdirectory <- "path/"
testfilename <- "lb.csv"
#demofilename only needed if datastandard = SDTM
demofilename <- "dm.csv"
#test or parameter to be analyzed
testname <- "CHOL"
yaxislabel <- "Cholesterol (mg/dL)"
#number of digits in table, sd = dignum +1
dignum <- 1
#normal range limits
limits <- c(200,240)

#functions to be called
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

testresults_read <-read.csv(file.path(inputdirectory,testfilename))


if(datastandard == "SDTM") {
dm_read <-read.csv(file.path(inputdirectory,demofilename))
dm <- subset(dm_read, ACTARM != "Screen Failure")
testresults <- subset(testresults_read, LBTESTCD == testname)
testresults_dm <- merge(x=testresults, y=dm, by = "USUBJID")
testresults_dm <- data.table(testresults_dm)
#setkey for speed gains when summarizing
setkey(testresults_dm, USUBJID, ACTARM, VISITNUM)
#specify plot
p <- ggplot(testresults_dm, aes(factor(VISITNUM), LBSTRESN))
# add notch = TRUE
p1 <- p + geom_boxplot(notch = TRUE) + xlab("Visit Number") + ylab(yaxislabel) + theme(legend.position="bottom", legend.title=element_blank(), text = element_text(size = 14)) 
# add mean points
p2 <- p1 + stat_summary(fun.y=mean, colour="dark red", geom="point", position=position_dodge(width=0.75))
# add normal range limits
p3 <- p2 + geom_hline(yintercept = limits, colour = "red")
#call summary table function
summary <- buildtable(avalue = quote(LBSTRESN), dfname= quote(testresults_dm), by1 = "VISITNUM", by2 = "ACTARM", dignum)[order(VISITNUM, ACTARM)]
table_summary <- data.frame(t(summary))           
} else {
testresults <- subset(testresults_read, PARAMCD == testname & TRT01A != "Screen Failure")

#setkey for speed gains when summarizing
testresults <- data.table(testresults)
setkey(testresults, USUBJID, TRT01A, VISITNUM)
#specify plot
p <- ggplot(testresults, aes(factor(VISITNUM), AVAL))
# add notch = TRUE
p1 <- p + geom_boxplot(aes(fill = TRT01A), notch = TRUE) + xlab("Visit Number") + ylab(yaxislabel) + theme(legend.position="bottom", legend.title=element_blank(), text = element_text(size = 14))
# add mean points
p2 <- p1 + stat_summary(fun.y=mean, colour="dark red", geom="point", position=position_dodge(width=0.75))
# add normal range limits
p3 <- p2 + geom_hline(yintercept = limits, colour = "red")
#call summary table function
summary <- buildtable(avalue = quote(AVAL), dfname= quote(testresults), by1 = "VISITNUM", by2 = "TRT01A", dignum)[order(VISITNUM, TRT01A)]
table_summary <- data.frame(t(summary))  
}


t1 <- tableGrob(table_summary, gpar.coretext = gpar(fontsize = 12), show.colnames = FALSE)
#Output to TIFF
tiff(file.path(outputdirectory,"plot.TIFF"), width = 1200, height = 1000, units = "px", pointsize = 12)
grid.arrange(p3, t1, ncol = 1)
dev.off()

# Optionally, use JPEG
jpeg(file.path(outputdirectory,"plot.JPEG"), , width = 1200, height = 1000, units = "px", pointsize = 12)
grid.arrange(p3, t1, ncol = 1)
dev.off()
 