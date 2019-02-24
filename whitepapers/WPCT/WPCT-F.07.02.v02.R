#' Box plot for Figure 7.2 
#' @description Read advs.xpt and plot box plots
#' @param treatmentname Which treatment arm variable? e.g. "TRTA"
#' @param useshortnames TRUE OR FALSE
#' @param oldnames Treatment Arms old names e.g. "Xanomeline Low Dose","Xanomeline High Dose"
#' @param newnames Treatment Arms new names e.g. "X-low", "X-High"
#' @param usepopflag subset on a population flatg. TRUE or FALSE
#' @param popflag
#' @param testname
#' @param yaxislabel
#' @param selectedvisits
#' @param perpage
#' @param dignum
#' @param inputdiretory set input file directory
#' @param outputdirectory set output file directory
#' @param testfilename accepts CSV or XPT files
#' @param filetype output file type - TIFF or JPEG or PNG
#' @param pixelwidth choose output file size: pixel width
#' @param pixelheight choose output file size: pixel height
#' @param outputfontsize choose output font size
#' @param charttitle Title for the chart
#' @return PhUSE Figure 7.2 Box plot - Change in XXX Over Time
#' @import ggplot2
#' @import data.table
#' @import gridExtra
#' @import Hmisc
#' @import tools
#' @export boxplotfunc<-function(data, treatmentname, useshortnames = c(TRUE,FALSE),
#'  oldnames, newnames,usepopflag = c(TRUE,FALSE), popflag, testname, yaxislabel,
#'   selectedvisits, perpage, dignum, redoutliers = c(TRUE, FALSE), 
#'   horizontallines = c(TRUE,FALSE), enterlimits= c(TRUE,FALSE), ANRLO, ANRHI, 
#'   inputdirectory, outputdirectory, testfilename, filetype = c("PNG","TIFF","JPEG"), 
#'   pixelwidth, pixelheight, outputfontsize, charttitle){
#' @author Hanming Tu
#' @name get_inputs
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  01/10/2016 (jp)  - adapted from WPCT 7.01.R script
#  06/21/2017 (kb)  - converted to an R package
#  02/22/2018 (htu) - added script metadata usage
#  07/04/2018 (bjf) - create for input selection from YML
#  1/17/2019 (bjf) -  skip plot save to a local directory if the directory is not available
# HEADER
# Display:     Figure 7.2 Box plot - Change from Baseline by Analysis Timepoint, Visit and Treatment
# White paper: Central Tendency
# Specs:       https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/
# Contributors: Jeno Pizarro, Kirsten Burdett


#TESTING and QUALIFICATION:
#DEVELOP STAGE
#10-JAN-2016, adapted from WPCT 7.01.R script
#needs ANCOVA p values in table...

### updated 21-June-2017, Kirsten - converted to an R package


#ggplot2, data.table, gridExtra, Hmisc (for xpt import) required, if not installed, program will error.
library(ggplot2)
library(data.table)
library(gridExtra)
library(Hmisc)
library(tools)
library(phuse)
library(httr)

#============================================================================================#
#=================================  Making 7.2 package  =====================================#
#' @data data frame
print(append(date(),"WPCT-F.07.02.v02R Execution of source starting"))
inYML <- get_inputs(fn())
cfgYML <- read_yml(fn())
if (!exists("lastRead")) { 
	lastRead <<-"Not read yet"
	print(append("Last intput data file read: ",lastRead))
	} 

# Below are the choices to be shown and convert into YML location
#Which treatment arm variable?
treatmentname <- input$trn 

#Rename Treatment Arms? (if you wish to display shorter names)
useshortnames <- input$usn

oldnames <- c("Xanomeline Low Dose","Xanomeline High Dose")
newnames <- c("X-low", "X-High")

#subset on a population flag?
usepopflag <- input$upf
popflag <- "SAFFL"

#test or parameter to be analyzed
testname <- "DIABP"
yaxislabel <- "BP (mmHG)"  #changed from 7.1
#visit numbers to be analyzed
selectedvisits <-c(0,2,4,6,8,12,16,20,24)
#how many visits to display per page?
perpage <- input$perpage
#number of digits in table, standard deviation = dignum +1
dignum <- input$dignum

#set input and output file directories

outputdirectory <- cfgYML$Outputs$output_dir
saveToFile <- TRUE
# skip plot save to a local directory if the directory is not available
 if (!dir.exists(outputdirectory)) {
    saveToFile <- FALSE
 }
validate(
  need(saveToFile, "Output directory is not available")
)
#accepts CSV or XPT files
testfilename <- cfgYML$Inputs$datasets
# special code to read from repository
GitHubRepo="phuse-org/phuse-scripts"
baseDirGitHub=cfgYML$Repo$base_dir
studyDir=cfgYML$Repo$data_dir
req <- GET(paste(cfgYML$Repo$repo_url,GitHubRepo,'contents',studyDir,sep='/'))
contents <- content(req,as='parsed')
files <- NULL
for (i in seq(length(contents))) {
  files[i] <- paste(baseDirGitHub,contents[[i]]$path,sep='/')
}
xptFiles <- files[grep(testfilename,files)]
count <- 0
for (xptFile in xptFiles) {
  count <- count + 1
  print(xptFile)
}

#output file type - TIFF or JPEG or PNG
filetype <- input$ft
#choose output file size: pixel width and height
pixelwidth <- 1200
pixelheight <- 1000
#choose output font size
outputfontsize <- 16
#Title for the chart
charttitle <- "Change in Diastolic Blood Pressure" #in quotes


#Read in DATASET if not yet read
if (lastRead!=xptFile || !exists("testresultsread")) {
	print(paste("Reading file: ",xptFile))
	if (file_ext(testfilename) == "csv") {
  		testresultsread <<- read.csv(xptFile)
	} else {
	  testresultsread <<-
	    sasxport.get(xptFile, lowernames = FALSE)
	}
	lastRead <<- xptFile
} else {
	print(paste("Using results previously read: ",xptFile))   
}
# buildtable function to be called later, summarize data to enable 
# creation of accompanying datatable
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
plot_list <- list()
#for each needed page, subset selected visits by number per page
for(i in 1:visitsplits) {
  
  #subset on test, visits, population to be analyzed
  if (usepopflag == TRUE){
    testresults <- subset(testresultsread, 
                          PARAMCD == testname & 
                            AVISITN %in% selectedvisits[(initial):
                                                          (ifelse(perpage*i>length(selectedvisits),
                                                                  length(selectedvisits),perpage*i))] 
                          & FLAG == "Y")
  } else {
    testresults <- subset(testresultsread, PARAMCD == testname & 
                            AVISITN %in% selectedvisits[(initial):(perpage*i)])  
  }
  initial <- initial + perpage
  testresults<- data.table(testresults)
  
  #setkey for speed gains when summarizing
  setkey(testresults, USUBJID, TREATMENT, AVISITN)
  
  #specify plot
  p <- ggplot(testresults, aes(factor(AVISITN), fill = TREATMENT, CHG))
  # add notch, axis labels, legend, text size
  p1 <- p + geom_boxplot(notch = TRUE) + xlab("Visit Number") + ylab(yaxislabel) + 
  	  theme(legend.position="bottom", legend.title=element_blank(),
          text = element_text(size = outputfontsize),
          axis.text.x  = element_text(size=outputfontsize),
          axis.text.y = element_text(size=outputfontsize)) +ggtitle(charttitle) 
  # add mean points
  p2 <- p1 + stat_summary(fun.y=mean, colour="dark red", geom="point", 
                          position=position_dodge(width=0.75))
  
  # horizontal line at 0
  p3 <- p2 + geom_hline(yintercept = 0, colour = "red")

  #call summary table function
  summary <- buildtable(avalue = quote(CHG), dfname= 
                          quote(testresults), by1 = "AVISITN", by2 = "TREATMENT", 
                        dignum)[order(AVISITN, TREATMENT)]
  table_summary <- data.frame(t(summary))           
  
  t1theme <- ttheme_default(core = list(fg_params = list (fontsize = outputfontsize)))
  t1 <- tableGrob(table_summary, theme = t1theme, cols = NULL,rows=NULL)
  if (saveToFile) {
  	fileName <- file.path(outputdirectory,paste("plot",i,".",filetype,sep = "" ))
  	#
  	if (filetype == "TIFF"){
    	#Output to TIFF
    	tiff(fileName, 
         width = pixelwidth, height = pixelheight, units = "px", pointsize = 12)
    	grid.arrange(p3, t1, ncol = 1)
    	dev.off()
  	}
  	if (filetype == "JPEG") { 
  	  # Optionally, use JPEG for output
  	  jpeg(fileName, 
  	  width = pixelwidth, height = pixelheight, units = "px", pointsize = 12)
  	  grid.arrange(p3, t1, ncol = 1)
  	  dev.off()
  	}
  	if (filetype == "PNG") { 
  	  # Optionally, use PNG for output
  	  png(fileName, 
  	   width = pixelwidth, height = pixelheight, units = "px", pointsize = 12)
	  grid.arrange(p3, t1, ncol = 1)
  	  dev.off()
  	}
  	  print(paste("File created", fileName))
   }
    #
    #
    #
    # Save for display on the screen including file name
    #
    chartTitleShow <- charttitle
    if (saveToFile) {
    	chartTitleShow <- paste(charttitle,"File saved as: ",fileName) 
    	}
    p4 <- p3 + ggtitle(chartTitleShow) 
    plot_list[[i]] = p4 
    # plot_list[[i*2]] = t1 
}
    # Now show graphs only on the execution page
    grid.arrange(grobs = c(plot_list),ncol=1,nrow=i)
