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
# 4) Add percent difference from day 1 -- Tony/Bill
# 5) Get the percent difference from day 1 to (optionally) not replace the bodyweight graph - Bob
# 6) Add button toggle between BWDY and VISITDY (call this xaxis) -- Bob (create BWDY if missing from BW:BWDTC and DM:RFSTDTC)
# 7) To add an option to construct groups by Filtering and Splitting: -- Kevin
#       a) Dose Level  
#       b) Test Article   
#       c) Males/Females   
#       d) TK/non-TK
# 8) Display box/whisker plots -- Kevin
#####################################################
# Notes
# 1) Check if instem dataset should have control water tk as supplier group 2? -- Bob emailed instem and was told that this was an old study.
#####################################################
# Tasks
# 4) To add an option to construct groups by Filtering and Splitting: -- Kevin
#       e) Recovery/non-recovery (use EPOCH in TA)
# 5) Resolve issue of different units (display an error if the units aren't consistent, else the units of the first record) -- Hanming
# 6) Calculate days based upon subject epoch (use EPOCH in TA and elements in TE) 
# 7) Add a filter to (optionally) remove the Terminal Body Weights. - Bill Varady.
# 8) Implement alternative Day 1 normalization method - Tony
# 9) Output BG.xpt file
#10) Statistical Analysis (Dunnet's test; repeated-measures ANOVA) -- Kevin
#11) Add tests of dataset assumptions
#####################################################
# Hints
#      If the directory selection dialog does not appear when clicking on the "..." button, then
# the Java path is not correct. 
# Test with this R command:   system("java -version");
#####################################################
# Check for Required Packages, Install if Necessary, and Load
list.of.packages <- c("shiny","SASxport","ggplot2","ini",'tools')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
library(SASxport)
library(ggplot2)
library(ini)
library(tools)

# Source Required Functions
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/groupSEND.R')

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
setwd(defaultStudyFolder)

values <- reactiveValues()
values$path <- defaultStudyFolder
############################################################################################


################# Define Functional Response to GUI Input ##################################

server <- function(input, output,session) {
  
  # Handle Study Selection
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$chooseBWfile
    },
    handlerExpr = {
      if (input$chooseBWfile >= 1) {
        File <- choose.files(default=values$path,caption = "Select a BW Domain",multi=F,filters=cbind('.xpt or .csv files','*.xpt;*.csv'))
        
        # If file was chosen, update 
        if (length(File>0)) {
          path <- dirname(File)

          # save for next run if good one selected
          if (dir.exists(path)) {
            setDefaultStudyFolder(path) 
            values$path <- path
          }
        }
      }
    }
  )
  
  # Print Current Study Folder Location
  output$bwFilePath <- renderText({
    if (!is.null(values$path)) {
      values$path
    }
  })
  
  # Create Checkboxes if Multiple Test Articles Present
  output$selectTestArticle <- renderUI({
    path <- values$path
    setwd(path)
    if (length(list.files(pattern='*.xpt'))>0) {
      Dataset <- load.xpt.files()
    } else if (length(list.files(pattern='*.csv'))>0) {
      Dataset <- load.csv.files()
    } else {
      stop('No .xpt or .csv files to load!')
    }
    groupedData <- groupSEND(Dataset,'bw')
    testArticleNames <- unique(groupedData$Treatment)
    testArticles <- as.list(testArticleNames)
    checkboxGroupInput('testArticle',label='Test Article:',choices = testArticles,selected=testArticleNames)
  })
  
  # Load and Process Dataset
  data <- reactive({
    path <- values$path
    defaultStudyFolder <- path
    validate(
      need(dir.exists(defaultStudyFolder),label="Select a valid directory with a SEND dataset")
    )
    setwd(path)
    if (length(list.files(pattern='*.xpt'))>0) {
      Dataset <- load.xpt.files()
    } else if (length(list.files(pattern='*.csv'))>0) {
      Dataset <- load.csv.files()
    } else {
      stop('No .xpt or .csv files to load!')
    }
    
    groupedData <- groupSEND(Dataset,'bw')
    
    bwdmtx <- groupedData
    
    if (input$groupMethod == 'attributes') {
      
      # Get Dose Levels
      bwdmtx$Group <- groupedData$Dose
      
      # Filter by Test Article
      testArticleIndex <- NULL
      for (testArticle in input$testArticle) {
        tmpIndex <- which(bwdmtx$EXTRT==testArticle)
        testArticleIndex <- c(testArticleIndex,tmpIndex)
      }
      bwdmtx <- bwdmtx[testArticleIndex,]
      
      # Filter by Sex
      if (input$sex == 'Male') {
        bwdmtx$Group <- paste(bwdmtx$Group,bwdmtx$SEX)
        sexIndex <- which(bwdmtx$SEX=='M')
        bwdmtx <- bwdmtx[sexIndex,]
      } else if (input$sex == 'Female') {
        bwdmtx$Group <- paste(bwdmtx$Group,bwdmtx$SEX)
        sexIndex <- which(bwdmtx$SEX=='F')
        bwdmtx <- bwdmtx[sexIndex,]
      } else if (input$sex == 'Both (split)') {
        bwdmtx$Group <- paste(bwdmtx$Group,bwdmtx$SEX)
      }
      
      # Filter by Time of Sacrifice
      noRecoveryIndex <- which(bwdmtx$RecoveryStatus==FALSE)
      recoveryIndex <- which(bwdmtx$RecoveryStatus==TRUE)
      if (input$recovery == 'Main Study Group') {
        bwdmtx <- bwdmtx[noRecoveryIndex,]
      } else if (input$recovery == 'Recovery Group') {
        bwdmtx <- bwdmtx[recoveryIndex,]
      } else if (input$recovery == 'Both (split)') {
        bwdmtx$Group[recoveryIndex] <- paste(bwdmtx$Group[recoveryIndex],'Recovery')
      }
      
      # Filter by TK
      noTKindex <- which(bwdmtx$TKstatus==F)
      TKindex <- which(bwdmtx$TKstatus==T)
      bwdmtx$TK <- ''
      bwdmtx$TK[noTKindex] <- 'No TK'
      bwdmtx$TK[TKindex] <- 'TK'
      if (input$includeTK=='No TK') {
        bwdmtx <<- bwdmtx[noTKindex,]
      } else if (input$includeTK=='TK only') {
        bwdmtx <<- bwdmtx[TKindex,]
      }  else if (input$includeTK=='Both (pooled)') {
        bwdmtx <<- bwdmtx
      } else if (input$includeTK=='Both (split)') {
        bwdmtx$Group <- paste(bwdmtx$Group,bwdmtx$TK)
        bwdmtx <<- bwdmtx
      }
      bwdmtx$Group <- factor(bwdmtx$Group)
      # bwdmtx$Group <- factor(bwdmtx$Group,levels=sort(levels(bwdmtx$Group)))
    } else if (input$groupMethod=='sets') {
      if ("SPGRPCD" %in% colnames(bwdmtx)) {
        bwdmtx$Group <- as.factor(paste(bwdmtx$SPGRPCD,bwdmtx$SET,sep=":"))
      } else {
        bwdmtx$Group <- bwdmtx$SET
      }
    }
    
    validate(
      need(!is.null(bwdmtx), label = "Could not read body weight data from dataset")
    )
    
    # Add group list choices for selection
    groupList <<- levels(bwdmtx$Group)
    print(groupList)
    updateCheckboxGroupInput(session,"Groups", choices = groupList, selected = groupList)
    
    return(bwdmtx)
  })  
  
  # Plot Body Weights
  output$BWplot <- renderPlot({
    data()
    # retrieve xaxis choice
    xaxis <- input$xaxis
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
    
    if (input$plotType == 'Mean Data Points') {
      bwdmtxFiltMeans <- createMeansTable(bwdmtxFilt,'BWSTRESN',c('Group',xaxis))
      bwdmtxFiltMeans$Group <- factor(bwdmtxFiltMeans$Group,levels=sort(levels(bwdmtxFiltMeans$Group)))
      p <- ggplot(bwdmtxFiltMeans,aes(x=bwdmtxFiltMeans[,xaxis],y=BWSTRESN_mean,colour=Group)) +
        geom_point()
      if (input$printSE == TRUE) {
        p <- p + geom_errorbar(aes(ymin=BWSTRESN_mean-BWSTRESN_se,ymax=BWSTRESN_mean+BWSTRESN_se),width=0.8)
      }
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    } else if (input$plotType == 'Boxplots') {
      xaxis_levels <- as.character(sort(as.numeric(unique(bwdmtxFilt[,xaxis]))))
      bwdmtxFilt[,xaxis] <- factor(bwdmtxFilt[,xaxis],levels=xaxis_levels)
      p <- ggplot(bwdmtxFilt,aes(x=bwdmtxFilt[,xaxis],y=BWSTRESN,fill=Group))+
        geom_boxplot()
    } else {
      # plot with color by group
      p <- ggplot(bwdmtxFilt,aes(x=bwdmtxFilt[,xaxis],y=BWSTRESN,group=USUBJID,colour=Group)) +
        geom_point() + ggtitle('Body Weight Plot')+ labs(x=xaxis)
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    }
    p <- p + ggtitle('Body Weight Plot')+ labs(x=xaxis)
    print(p) 
  })
  
  # Plot Body Weights Percent Difference from Day 1
  output$BWDiffplot <- renderPlot({
    data()
    # retrieve xaxis choice
    xaxis <- input$xaxis
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

    bwdmtxFilt$BWPDIFF <- NA # create a new column with nothing in it.
    
    for (i in 1:nrow(bwdmtxFilt)) 
    {
      DayOneWeight <- bwdmtxFilt$BWSTRESN[which((bwdmtxFilt[,xaxis]==1) & (bwdmtxFilt$USUBJID==bwdmtxFilt$USUBJID[i]))]
      if (length(DayOneWeight)>1)
      {
        DayOneWeight=DayOneWeight[1] #if more than one day one weight is reported, just select the first one.
      } 
      else
      {
        if (length(DayOneWeight)<1)
        {
          DayOneWeight = NA  #ensure that DayOneWeight has an NA for the subsequent calculations if no weights were found for day 1
        }
      }
      bwdmtxFilt$BWPDIFF[i] <- 100*((bwdmtxFilt$BWSTRESN[i]-DayOneWeight) / DayOneWeight)
    }
    
    if (input$plotType == 'Mean Data Points') {
      bwdmtxFiltMeans <- createMeansTable(bwdmtxFilt,'BWPDIFF',c('Group',xaxis))
      bwdmtxFiltMeans$Group <- factor(bwdmtxFiltMeans$Group,levels=sort(levels(bwdmtxFiltMeans$Group)))
      p <- ggplot(bwdmtxFiltMeans,aes(x=bwdmtxFiltMeans[,xaxis],y=BWPDIFF_mean,colour=Group)) +
        geom_point()
      if (input$printSE == TRUE) {
        p <- p + geom_errorbar(aes(ymin=BWPDIFF_mean-BWPDIFF_se,ymax=BWPDIFF_mean+BWPDIFF_se),width=0.8)
      }
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    } else if (input$plotType == 'Boxplots') {
      xaxis_levels <- as.character(sort(as.numeric(unique(bwdmtxFilt[,xaxis]))))
      bwdmtxFilt[,xaxis] <- factor(bwdmtxFilt[,xaxis],levels=xaxis_levels)
      p <- ggplot(bwdmtxFilt,aes(x=bwdmtxFilt[,xaxis],y=BWPDIFF,fill=Group))+
        geom_boxplot()
    } else {
      # plot with color by group
      p <- ggplot(bwdmtxFilt,aes(x=bwdmtxFilt[,xaxis],y=BWPDIFF,group=USUBJID,colour=Group)) +
        geom_point() + ggtitle('Body Weight Percent Difference from Day 1 Plot')+ labs(x=xaxis)
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    }
    p <- p + ggtitle('Body Weight Percent Difference from day 1 Plot')+ labs(x=xaxis)
    print(p) 
  })
  
  # Plot Body Weight Gains (using user-defined interval)
  output$BGplot <- renderPlot({
    data()
    # retrieve xaxis choice
    xaxis <- input$xaxis
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
    bgdmtxFilt <- bwdmtxFilt[order(bwdmtxFilt$USUBJID,bwdmtxFilt[,xaxis]),]
    
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
          if ((subjectData[,xaxis][i]-subjectData[,xaxis][i-interval]>=input$n)|(subjectData[,xaxis][i]==1)) {
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

    if (input$plotType == 'Mean Data Points') {
      bgdmtxFiltMeans <- createMeansTable(bgdmtxFilt,'BGSTRESN',c('Group',xaxis))
      bgdmtxFiltMeans$Group <- factor(bgdmtxFiltMeans$Group,levels=sort(levels(bgdmtxFiltMeans$Group)))
      p <- ggplot(bgdmtxFiltMeans,aes(x=bgdmtxFiltMeans[,xaxis],y=BGSTRESN_mean,colour=Group)) +
        geom_point()
      if (input$printSE == TRUE) {
        p <- p + geom_errorbar(aes(ymin=BGSTRESN_mean-BGSTRESN_se,ymax=BGSTRESN_mean+BGSTRESN_se),width=0.8)
      }
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    } else if (input$plotType == 'Boxplots') {
      xaxis_levels <- as.character(sort(as.numeric(unique(bgdmtxFilt[,xaxis]))))
      bgdmtxFilt[,xaxis] <- factor(bgdmtxFilt[,xaxis],levels=xaxis_levels)
      p <- ggplot(bgdmtxFilt,aes(x=bgdmtxFilt[,xaxis],y=BGSTRESN,fill=Group))+ 
        geom_boxplot()
    } else {
      # plot with color by group
      p <- ggplot(bgdmtxFilt,aes(x=bgdmtxFilt[,xaxis],y=BGSTRESN,group=USUBJID,colour=Group)) +
        geom_point() + ggtitle('Body Weight Gain Plot')+ labs(x=xaxis)
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    }
    p <- p + ggtitle('Body Weight Gain Plot')+ labs(x=xaxis)
    print(p) 
  })
  
}

############################################################################################

############################### Define GUI for Application #################################

ui <- fluidPage(
  
  titlePanel("Body Weight Gains Plot"),
  
  sidebarLayout(
    
    sidebarPanel(
      h3('Study Selection'),
      actionButton('chooseBWfile','Choose a BW Domain File'),br(),
      h5('Study Folder Location:'),
      verbatimTextOutput('bwFilePath'),
      # shinyDirButton('bwDir','Change Directory','Select a Directory'),
      # verbatimTextOutput('directoryPath'),
      # directoryInput('directory',label = 'Directory:',value=defaultStudyFolder),
      h3('Select Plots:'),
      checkboxInput('showBWPlot','Show the Body Weight Plot',value=1),
      checkboxInput('showBWDiffPlot','Show the Body Weight Difference from Day 1 Plot',value=0),
      checkboxInput('showBGPlot','Show the Body Weight Gain Plot',value=0),
      conditionalPanel(
        condition = 'input.showBGPlot==1',
        numericInput('n','Body Weight Gain Interval (Days):',min=1,max=100,value=4)
      ),
      h3('Graph Options:'),
      radioButtons('plotType',"Type of Plot:",
                   c("Individual Data Points","Mean Data Points","Boxplots"),selected="Mean Data Points"),
      conditionalPanel(
        condition = "input.plotType=='Individual Data Points' || input.plotType=='Mean Data Points'",
        checkboxInput('printLines','Display Lines',value=1)
      ),
      conditionalPanel(
        condition = "input.plotType=='Mean Data Points'",
        checkboxInput('printSE','Display Error Bars',value=0)
      ),
      radioButtons("xaxis", "Use for x-axis:",
                   c("BW DAY" = "BWDY",
                     "VISIT DAY" = "VISITDY")),
      selectInput('groupMethod','Grouping Method:',choices=list('Subject Attributes'='attributes','Trial Sets'='sets')),
      conditionalPanel(
        condition = 'input.groupMethod == "attributes"',
        uiOutput('selectTestArticle'),
        radioButtons('sex','Filter by Sex:',choices=c('Male','Female','Both (pooled)','Both (split)'),selected='Both (split)'),
        radioButtons('recovery','Filter by Timing of Sacrifice:',choices=c('Main Study Group','Recovery Group','Both (pooled)','Both (split)'),selected='Both (pooled)'),
        radioButtons('includeTK','Include TK Groups?',choices=c('No TK','TK only','Both (pooled)','Both (split)'),selected='No TK')
      ),
      checkboxGroupInput("Groups", "Filter by Group:", choices = groupList)
    ),
    
    mainPanel(
      # Show each plot if it is selected to be shown
      conditionalPanel(
        condition = "input.showBWPlot==1",
        plotOutput("BWplot")
      ),
      conditionalPanel(
        condition = "input.showBWDiffPlot==1",
        plotOutput("BWDiffplot")
      ),
      conditionalPanel(
        condition = "input.showBGPlot==1",
        plotOutput("BGplot")
      )
    ) 
  )
)

############################################################################################

# Run Shiny App
shinyApp(ui = ui, server = server)