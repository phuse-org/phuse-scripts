# HEADER
# Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Planned Treatment
# White paper: Central Tendency
# Specs:       https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/    !YML needed!
# Output:      https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_r/
# Contributors: Jeno Pizarro, Suzie Perigaud

#TO DO List for program:
#*Tested with only 5 visits, functionality to move to next page when there are more, etc
#*clean up ymax warnings (plot making)
#*annotations, space above table

#TESTING and QUALIFICATION:
#DEVELOP STAGE
#12-JUL-2015, ran without errors using STATIN TEST DATA v0 - DM, LB csvs 
#29-NOV-2015, edited to be more flexible, allows user to specify Column names rather than assign based on SDTM vs ADaM

#ggplot2, data.table, gridExtra required, if not installed, program will error.
library(ggplot2)
library(data.table)
library(gridExtra)

#test or parameter to be analyzed
testname <- "CHOL"
yaxislabel <- "Cholesterol (mg/dL)"
#number of digits in table, sd = dignum +1
dignum <- 1
###limits configuration
#lower limit(s) - ANRLO <- c(l1, l2, ...) -
ANRLO <- c(200)
#upper limit(s) - ANRHI <- c(l1, l2, ...) -
ANRHI <- c(240)

#set input and output file directories
inputdirectory <- "path"
outputdirectory <- "path"
testfilename <- "lb.csv"
#Read in DATASET
testresults <-read.csv(file.path(inputdirectory,testfilename))
#RUN THIS BLOCK IF USING TABULATION (SDTM) DATA, merges DM characteristics on test dataset
demofilename <- "dm.csv"
dm_read <-read.csv(file.path(inputdirectory,demofilename))
dm <- subset(dm_read, ACTARM != "Screen Failure")
testresults<- merge(x=testresults, y=dm, by = "USUBJID")
#END SDTM ONLY BLOCK

#SELECT VARIABLES (examples in parenthesis): Results (LBSTRESN, AVAL), TIME (VISITNUM), TREATMENT (ARM, ACTARM, TRT01A), PARAMCD (LBTESTCD)
#colnames(testresults)[names(testresults) == "OLD VARIABLE"] <- "NEW VARIABLE"
colnames(testresults)[names(testresults) == "LBSTRESN"] <- "RESULTS"
colnames(testresults)[names(testresults) == "VISITNUM"] <- "TIME"
colnames(testresults)[names(testresults) == "ACTARM"] <- "TREATMENT"
colnames(testresults)[names(testresults) == "LBTESTCD"] <- "PARAMCD"


testresults <- subset(testresults, PARAMCD == testname)
testresults<- data.table(testresults)



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



#setkey for speed gains when summarizing
setkey(testresults, USUBJID, TREATMENT, TIME)

#create a variable for the out of limits data
testresults$OUT <- ifelse(testresults$RESULTS < ANRLO | testresults$RESULTS > ANRHI, testresults$RESULTS, NA)

#specify plot
p <- ggplot(testresults, aes(factor(TIME), fill = TREATMENT, RESULTS))
# add notch = TRUE
p1 <- p + geom_boxplot(notch = TRUE) + xlab("Visit Number") + ylab(yaxislabel) + theme(legend.position="bottom", legend.title=element_blank(), text = element_text(size = 14))  
# add mean points
p2 <- p1 + stat_summary(fun.y=mean, colour="dark red", geom="point", position=position_dodge(width=0.75))
# add normal range limits
p3 <- p2 + geom_hline(yintercept = c(ANRLO,ANRHI), colour = "red")
#out of limits jittered points
p4 <- p3 + geom_jitter(data = testresults, aes(factor(TIME), testresults$OUT), colour = "dark red", position = position_dodge(width=0.75))

#call summary table function
summary <- buildtable(avalue = quote(RESULTS), dfname= quote(testresults), by1 = "TIME", by2 = "TREATMENT", dignum)[order(TIME, TREATMENT)]
table_summary <- data.frame(t(summary))           


t1 <- tableGrob(table_summary, gpar.coretext = gpar(fontsize = 12), show.colnames = FALSE)
#Output to TIFF
tiff(file.path(outputdirectory,"plot.TIFF"), width = 1200, height = 1000, units = "px", pointsize = 12)
grid.arrange(p4, t1, ncol = 1)
dev.off()

# Optionally, use JPEG
jpeg(file.path(outputdirectory,"plot.JPEG"), , width = 1200, height = 1000, units = "px", pointsize = 12)
grid.arrange(p4, t1, ncol = 1)

dev.off()


