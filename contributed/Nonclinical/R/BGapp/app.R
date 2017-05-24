################ Setup Application ########################################################
# Prerequisites include:
#   Install shiny
#   Install Java, set Java_home
#   Java must be set correctly on the path, and must be Java 1.7 or later,
#   for example, set environment variable for this run:
#      set path=c:\progra~1\java\jdk1.7.0_131\bin
#
#####################################################
# Completed Tasks
# 1) Add grouping variable -- Bob 
#  Also placed read into a data function, so as to validate data and replace error message on startup
#  Also, remember last directory to a file
#  And added group filter
# 2) Add body weight gain with selected interval -- Kevin
# 3) Adding means and buttons for connecting dots -- Kevin
#####################################################
# Tasks
# 1) Add percent difference from day 1 -- Tony/Bill
# 2) Check if instem dataset should have control water tk as supplier group 2? -- Bob emailed about this
# 3) Add button toggle between BWDY and VISITDY -- Bob (create BWDY if missing from BW:BWDTC and DM:RFSTDTC)
# 5) Filter groups by categories -- Kevin (in progress)
# 6) Resolve issue of different units
#####################################################
# Hints
#      If the directory selection dialog does not appear when clicking on the "..." button, then
# the Java path is not correct. 
# Test with this R command:   system("java -version");
#####################################################
# Check for Required Packages, Install if Necessary, and Load
list.of.packages <- c("shiny","SASxport","rChoiceDialogs","ggplot2","ini",'tools')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
library(SASxport)
library(rChoiceDialogs)
library(ggplot2)
library(ini)

# Source Required Functions
source('directoryInput.R')
# source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')
source('C:/Users/Kevin.Snyder/Documents/PhUSE/Repo/trunk/contributed/Nonclinical/R/Functions/Functions.R')

# Settings file
SettingsFile <- file.path(path.expand('~'),"BWappSettings.ini")
# Initial group list is empty
groupList <<- ""

# Function to get setting from file
getDefaultStudyFolder <- function() {
  # Create a file name for saving last used directory
  if(file.exists(SettingsFile)){
    checkIni = read.ini(SettingsFile)
    aPath <- checkIni$'Directories'$Path
  } else {
    # if no file found, set to home location
    aPath <- path.expand('~')
  }  
  aPath
}  
# Function to set study in folder 
setDefaultStudyFolder <- function(aPath) {
  # only if a valid path
  if (dir.exists(aPath)) {
    newini <- list() 
    newini[[ "Directories" ]] <- list(Path = aPath)
    write.ini(newini,SettingsFile)
  }
}  

# set default study folder
defaultStudyFolder <- getDefaultStudyFolder() 
############################################################################################


################# Define Functional Response to GUI Input ##################################

server <- function(input, output,session) {
  
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory
    },
    handlerExpr = {
      if (input$directory >= 1) {
        path <- rchoose.dir(default = defaultStudyFolder)
        updateDirectoryInput(session, 'directory', value = path)
        # Show selection in console
        print(path)
        # and save for next run if good one selected
        if (dir.exists(path)) {
          print("Valid directory selected")
          setDefaultStudyFolder(path) 
        }
      }
    }
  )
  
  data <- reactive({
    print(" Now checking new directory")
    path <- readDirectoryInput(session,'directory')
    print(path)
    defaultStudyFolder=path
    # print(file.path(defaultStudyFolder,"bw.xpt"))
    validate(
      need(dir.exists(defaultStudyFolder),label="Select a valid directory with a SEND dataset")
    )
#     validate(
#       need(file.exists(file.path(defaultStudyFolder,"bw.xpt")),label="A directory with a dataset containing body weight data (bw.xpt)")
#     )
    setwd(path)
    if (length(list.files(pattern='*.xpt'))>0) {
      Dataset <- load.xpt.files()
    } else if (length(list.files(pattern='*.csv'))>0) {
      Dataset <- load.csv.files()
    } else {
      stop('No .xpt or .csv files to load!')
    }
    # merge in other demographic variables then other set variables
    print(head(Dataset$bw))
    print(head(Dataset$dm))
    bwdm <<- merge(Dataset$bw,Dataset$dm,by="USUBJID")
    # filter TX for one row per ARMCD parameter
    txSetArm <- Dataset$tx[Dataset$tx$TXPARMCD == "ARMCD", ] 
    print("tx: ")
    print(Dataset$tx)
    print("txSetArm: ")
    print(txSetArm)
    # add in column for set name
    bwdmtx <<- merge(bwdm,txSetArm[ , c("SETCD", "SET")],by="SETCD")
    # add in a column for sponsor group code, if available
    # filter TX for one row per ARMCD parameter
    txSPGRPCD <- Dataset$tx[Dataset$tx$TXPARMCD == "SPGRPCD", ] 
    print("txSPGRPCD: ")
    print(txSPGRPCD)
    print(head(bwdmtx))
    if (nrow(txSPGRPCD)>0) {
      # add in column for SPGRPCD
      names(txSPGRPCD)[names(txSPGRPCD)=="TXVAL"] <- "SPGRPCD"
      bwdmtx <<- merge(bwdmtx,txSPGRPCD[ , c("SETCD","SPGRPCD")],by="SETCD")
    }
    print(head(bwdmtx))
    # add a compound group/set for graph labeling
    # if sponsor defined group label exists, combine with set name
    if ("SPGRPCD" %in% colnames(bwdmtx)) {
      bwdmtx <<- within(bwdmtx, Group <- as.factor(paste(SPGRPCD,SET,sep=":")))
    } else {
      bwdmtx <<- within(bwdmtx, Group <- SET)
    }
    #
    dm <<- Dataset$dm
    
    # Filter by Sex
    if ('Male' %in% input$sex) {
      maleIndex <- which(bwdmtx$SEX=='M')
    } else {
      maleIndex <- NULL
    }
    if ('Female' %in% input$sex) {
      femaleIndex <- which(bwdmtx$SEX=='F')
    } else {
      femaleIndex <- NULL
    }
    sexIndex <- union(maleIndex,femaleIndex)
    bwdmtx <<- bwdmtx[sexIndex,]
    
    # Filtery by TK
    if (input$tk==FALSE) {
      TKsubjects <- NULL
      noTKsubjects <- NULL
      TKcount <- 1
      noTKcount <- 1
      for (subject in unique(bwdmtx$USUBJID)) {
        if (subject %in% Dataset$pc$USUBJID) {
          TKsubjects[TKcount] <- subject
          TKcount <- TKcount + 1
        } else {
          noTKsubjects[noTKcount] <- subject
          noTKcount <- noTKcount + 1
        }
      }
      noTKindex <- which(bwdmtx$USUBJID %in% noTKsubjects)
      bwdmtx <<- bwdmtx[noTKindex,]
    }
    
    bwdmtx$Group <<- factor(bwdmtx$Group)
    
    validate(
      need(!is.null(bwdmtx), label = "Could not read body weight data from dataset")
    )
    
    # Add group list choices for selection
    groupList <<- levels(bwdmtx$Group)
    print("Now update set of groups:")
    print(groupList)
    updateCheckboxGroupInput(session,"Groups", choices = groupList, selected = groupList)
    
    print(head(bwdmtx))
  })  
  
  # Plot Body Weights
  output$BWplot <- renderPlot({
    data()
    # filter now based on group selection
    if (is.null(input$Groups) ) { 
      bwdmtxFilt <- bwdmtx
    }
    else if ( length(input$Groups) == 0 ) { 
      bwdmtxFilt <- bwdmtx
    } 
    else {
      bwdmtxFilt <- bwdmtx[bwdmtx$Group  %in% input$Groups, ]  
    }
    print(head(bwdmtxFilt))
    
    if (input$printMeans==TRUE) {
      bwdmtxFiltMeans <- createMeansTable(bwdmtxFilt,'BWSTRESN',c('Group','BWDY'))
      p <- ggplot(bwdmtxFiltMeans,aes(x=BWDY,y=BWSTRESN_mean,colour=Group)) +
        geom_point() + ggtitle('Body Weight Plot')
      if (input$printSE == TRUE) {
        p <- p + geom_errorbar(aes(ymin=BWSTRESN_mean-BWSTRESN_se,ymax=BWSTRESN_mean+BWSTRESN_se),width=0.8)
      }
    } else {
      # plot with color by group and lines connecting subjects
      p <- ggplot(bwdmtxFilt,aes(x=BWDY,y=BWSTRESN,group=USUBJID,colour=Group)) +
        geom_point() + ggtitle('Body Weight Plot')
    }
    if (input$printLines==TRUE) {
      p <- p + geom_line()
    }
    print(p)
  })
  
  # Plot Body Weight Gains (using user-defined interval)
  output$BGplot <- renderPlot({
    data()
    # filter now based on group selection
    if (is.null(input$Groups) ) { 
      bwdmtxFilt <- bwdmtx
    }
    else if ( length(input$Groups) == 0 ) { 
      bwdmtxFilt <- bwdmtx
    } 
    else {
      bwdmtxFilt <- bwdmtx[bwdmtx$Group  %in% input$Groups, ]  
    }
    
    # Order Dataset by Subject and then by Day
    bgdmtxFilt <- bwdmtxFilt[order(bwdmtxFilt$USUBJID,bwdmtxFilt$BWDY),]
    
    # Calculate Body Weight Gains and Filter by Interval Length
    bgdmtxFilt$BGSTRESN <- bgdmtxFilt$BWSTRESN
    for (subject in unique(bgdmtxFilt$USUBJID)) {
      index <- which(bgdmtxFilt$USUBJID==subject)
      subjectData <- bgdmtxFilt[index,]
      for (i in seq(length(index))) {
        if (i == 1) {
          # Set initial datapoint at zero
          bgDataTmp <- 0
          interval <- 1
        } else {
          # Check if next datapoint is at or past user-defined interval or Day 1
          ## NOTE: maybe we also add a contigency for the last day of dosing or start of recovery period
          if ((subjectData$BWDY[i]-subjectData$BWDY[i-interval]>=input$n)|(subjectData$BWDY[i]==1)) {
            # if it is, then record body weight gain across interval
            bgDataTmp[i] <- subjectData$BWSTRESN[i] - subjectData$BWSTRESN[i-interval]
            interval <- 1
          } else {
            # if it is not, record datapoint as NA
            bgDataTmp[i] <- NA
            interval <- interval + 1
          }
        }
      }
      bgdmtxFilt$BGSTRESN[index] <- bgDataTmp
    }
    
    # Remove NA values from dataset
    bgdmtxFilt <- bgdmtxFilt[which(is.finite(bgdmtxFilt$BGSTRESN)),]

    if (input$printMeans == TRUE) {
      bgdmtxFiltMeans <- createMeansTable(bgdmtxFilt,'BGSTRESN',c('Group','BWDY'))
      p <- ggplot(bgdmtxFiltMeans,aes(x=BWDY,y=BGSTRESN_mean,colour=Group)) +
        geom_point() + ggtitle('Body Weight Gain Plot')
      if (input$printSE == TRUE) {
        p <- p + geom_errorbar(aes(ymin=BGSTRESN_mean-BGSTRESN_se,ymax=BGSTRESN_mean+BGSTRESN_se),width=0.8)
      }
    } else {
      # plot with color by group and lines connecting subjects
      p <- ggplot(bgdmtxFilt,aes(x=BWDY,y=BGSTRESN,group=USUBJID,colour=Group)) +
        geom_point() + ggtitle('Body Weight Gain Plot')
    }
    if (input$printLines == TRUE) {
      p <- p + geom_line()
    }
    print(p) 
  })
  
}

############################################################################################

############################### Define GUI for Application #################################

ui <- fluidPage(
  
  titlePanel("Body Weight Gains Plot"),
  
  sidebarLayout(
    
    sidebarPanel(
      h3('Select Study'),
      directoryInput('directory',label = 'Directory:',value=defaultStudyFolder),
      numericInput('n','Interval of at Least n Days:',min=1,max=100,value=1),
      checkboxInput('printLines','Display Lines',value=1),
      checkboxInput('printMeans','Display Means',value=1),
      conditionalPanel(
        condition = "input.printMeans==1",
        checkboxInput('printSE','Display Error Bars',value=0)
      ),
      checkboxGroupInput('sex','Filter by Sex:',choices=c('Male','Female'),selected=c('Male','Female')),
      strong('Filter by TK:'),
      checkboxInput('tk','Include TK Groups',value=FALSE),
      checkboxGroupInput("Groups", "Filter by Group:", choices = groupList)
    ),
    
    mainPanel(
      plotOutput("BWplot"),
      br(),
      plotOutput("BGplot")
    ) 
  )
)

############################################################################################

# Run Shiny App
shinyApp(ui = ui, server = server)