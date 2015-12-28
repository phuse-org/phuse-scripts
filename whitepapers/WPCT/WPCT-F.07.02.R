# HEADER
# Display:     Figure 7.2 Box plot - Measurements by Analysis Timepoint, Visit and Planned Treatment
# White paper: Central Tendency
# Specs:       https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/
# Output:      https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_r/
# Contributors: Jeno Pizarro, Suzie Perigaud

#TO DO List for program:
#*Tested with only 5 visits, functionality to move to next page when there are more, etc
#*annotations, space above table

#TESTING and QUALIFICATION:
#DEVELOP STAGE
#20-DEC-2015 - Developed from 7.1 script

#ggplot2, data.table, gridExtra, Hmisc (for xpt import) required, if not installed, program will error.
library(ggplot2)
library(data.table)
library(gridExtra)
library(Hmisc)

#test or parameter to be analyzed
testname <- "DIABP"
yaxislabel <- "Diastolic Blood Pressure (mmHG)"
#visit numbers to be analyzed
selectedvisits <-c(2,4,6,8,12)
#number of digits in table, standard deviation = dignum +1
dignum <- 1


#set input and output file directories
inputdirectory <- "path"
outputdirectory <- "path"
testfilename <- "advs.xpt"
#Read in DATASET
#testresults <-read.csv(file.path(inputdirectory,testfilename))
testresults<- sasxport.get(file.path(inputdirectory,testfilename))

#SELECT VARIABLES (examples in parenthesis): Results (LBSTRESN, AVAL), TIME (VISITNUM), TREATMENT (ARM, ACTARM, TRT01A), PARAMCD (LBTESTCD)
#colnames(testresults)[names(testresults) == "OLD VARIABLE"] <- "NEW VARIABLE"

colnames(testresults)[names(testresults) == "chg"] <- "RESULTS"
colnames(testresults)[names(testresults) == "avisitn"] <- "TIME"
colnames(testresults)[names(testresults) == "trta"] <- "TREATMENT"
colnames(testresults)[names(testresults) == "paramcd"] <- "PARAMCD"
colnames(testresults)[names(testresults) == "usubjid"] <- "USUBJID"
colnames(testresults)[names(testresults) == "saffl"] <- "POPFLAG" #select population flag to subset on

#Rename Treatment Arms if desired
testresults$TREATMENT <- ifelse(testresults$TREATMENT == "Xanomeline Low Dose","X-low",
                                ifelse(testresults$TREATMENT == "Xanomeline High Dose", "X-high",
                                       ifelse(testresults$TREATMENT == "Placebo", "Placebo", "Unexpected")
                                       )
                                )

#subset on test, visits, population to be analyzed
testresults <- subset(testresults, PARAMCD == testname & TIME %in% selectedvisits & POPFLAG == "Y")
testresults<- data.table(testresults)

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



#setkey for speed gains when summarizing
setkey(testresults, USUBJID, TREATMENT, TIME)

#specify plot
p <- ggplot(testresults, aes(factor(TIME), fill = TREATMENT, RESULTS))
# add notch = TRUE
p1 <- p + geom_boxplot(notch = TRUE) + xlab("Visit Number") + ylab(yaxislabel) + theme(legend.position="bottom", legend.title=element_blank(), text = element_text(size = 14))  
# add mean points
p2 <- p1 + stat_summary(fun.y=mean, colour="dark red", geom="point", position=position_dodge(width=0.75))
# add red horizontal line at 0
p3 <- p2 + geom_hline(yintercept = 0, colour = "red")

#call summary table function
summary <- buildtable(avalue = quote(RESULTS), dfname= quote(testresults), by1 = "TIME", by2 = "TREATMENT", dignum)[order(TIME, TREATMENT)]
table_summary <- data.frame(t(summary))           

t1theme <- ttheme_default(core = list(fg_params = list (fontsize = 12)))
t1 <- tableGrob(table_summary, theme = t1theme, cols = NULL) 

#Output to TIFF
tiff(file.path(outputdirectory,"plot.TIFF"), width = 1200, height = 1000, units = "px", pointsize = 12)
grid.arrange(p3, t1, ncol = 1)
dev.off()

# Optionally, use JPEG
jpeg(file.path(outputdirectory,"plot.JPEG"), , width = 1200, height = 1000, units = "px", pointsize = 12)
grid.arrange(p3, t1, ncol = 1)

dev.off()

