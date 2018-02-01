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
#       e) Recovery/non-recovery
# 8) Display box/whisker plots -- Kevin
#####################################################
# Notes
# 1) Check if instem dataset should have control water tk as supplier group 2? -- Bob emailed instem and was told that this was an old study.
#####################################################
# Tasks Remaining
# 1) Resolve issue of different units (display an error if the units aren't consistent, else the units of the first record) -- Hanming
# 2) Calculate days based upon subject epoch (use EPOCH in TA and elements in TE) 
# 3) Add a filter to (optionally) remove the Terminal Body Weights. - Bill Varady.
# 4) Implement alternative Day 1 normalization method - Tony
# 5) Output BG.xpt file
# 6) Statistical Analysis (Dunnet's test; repeated-measures ANOVA) -- Kevin
# 7) Add tests of dataset assumptions
#####################################################
# Hints
#      If the directory selection dialog does not appear when clicking on the "..." button, then
# the Java path is not correct. 
# Test with this R command:   system("java -version");
#####################################################
# Check for Required Packages, Install if Necessary, and Load
# devtools::install_github('hadley/ggplot2',quiet=TRUE)
# devtools::install_github("ropensci/plotly",quiet=TRUE)
list.of.packages <- c("shiny","SASxport","httr","haven","ini",'tools')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
library(Hmisc)
library(httr)
library(ggplot2)
library(tools)
library(plotly)

# Source Required Functions
# source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')
source('~/PhUSE/Repo/trunk/contributed/Nonclinical/R/Functions/Functions.R')
# source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/groupSEND.R')
source('~/PhUSE/Repo/trunk/contributed/Nonclinical/R/Functions/groupSEND.R')
source('~/passwordGitHub.R')

# Initial group list is empty
groupList <- ""

# set default study folder
# defaultStudyFolder <- 'https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/send/PDS/Xpt'

values <- reactiveValues()
values$path <- NULL
############################################################################################


################# Define Functional Response to GUI Input ##################################

server <- function(input, output,session) {
  
  # Create Drop Down to Select Studies from PhUSE GitHub Repo
  output$selectGitHubStudy <- renderUI({
    Req <- GET(paste('https://api.github.com/repos/phuse-org/phuse-scripts/contents/data/send'),
               authenticate(userGitHub,passwordGitHub))
    contents <- content(Req,as='parsed')
    GitHubStudies <- NULL
    for (i in seq(length(contents))) {
      GitHubStudies[i] <- strsplit(contents[[i]]$path,'/send/')[[1]][2]
    }
    selectInput('selectGitHubStudy',label='Select Study from PhUSE GitHub:',choices = GitHubStudies,selected='PDS')
  })
  
  # Handle Study Selection
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$chooseBWfile
    },
    handlerExpr = {
      if (input$chooseBWfile >= 1) {
        # FIX FILE PATH PROBLEM, Check OS, and remove ini, point to PDS github as default
        # File <- choose.files(default=values$path,caption = "Select a BW Domain",multi=F,filters=cbind('.xpt or .csv files','*.xpt;*.csv'))
        File <- file.choose()
        
        # If file was chosen, update 
        if (length(File>0)) {
          path <- dirname(File)

          # save for next run if good one selected
          if (dir.exists(path)) {
            values$path <- path
          }
        }
      }
    }
  )
  
  # Print Current Study Folder Location
  output$bwFilePath <- renderText({
    req(values$path)
    values$path
    # if (!is.null(values$path)) {
    #   values$path
    # } else {
    #   defaultStudyFolder
    # }
  })
  
  # Load Dataset
  loadData <- reactive({
    req(input$selectGitHubStudy)
    if (input$dataSource=='GitHub') {
      values$path <- paste0('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/send/',input$selectGitHubStudy)
    }
    path <- values$path
    if (input$dataSource=='local') {
      setwd(path)
      if (length(list.files(pattern='*.xpt'))>0) {
        Dataset <- load.xpt.files()
      } else if (length(list.files(pattern='*.csv'))>0) {
        Dataset <- load.csv.files()
      } else {
        stop('No .xpt or .csv files to load!')
      }
    } else if (input$dataSource=='GitHub') {
      StudyDir <- paste0('data/send/',input$selectGitHubStudy)
      Dataset <- load.GitHub.xpt.files(studyDir=StudyDir,
                                       authenticate=TRUE,User=userGitHub,Password=passwordGitHub)
    }
    groupedData <- groupSEND(Dataset,'bw')
    return(groupedData)
  })
  
  # Create Checkboxes if Multiple Test Articles Present
  output$selectTestArticle <- renderUI({
    req(input$selectGitHubStudy)
    groupedData <- loadData()
    testArticleNames <- unique(groupedData$Treatment)
    testArticles <- as.list(testArticleNames)
    checkboxGroupInput('testArticle',label='Test Article:',choices = testArticles,selected=testArticleNames)
  })
  
  # Process Dataset
  processData <- reactive({
    req(input$testArticle)
    groupedData <- loadData()
    
    if (input$groupMethod == 'attributes') {
      
      # Get Dose Levels
      groupedData$Group <- groupedData$Dose
      
      # Filter by Test Article
      testArticleIndex <- NULL
      for (testArticle in input$testArticle) {
        tmpIndex <- which(groupedData$EXTRT==testArticle)
        testArticleIndex <- c(testArticleIndex,tmpIndex)
      }
      groupedData <- groupedData[testArticleIndex,]
      
      # Filter by Sex
      if (input$sex == 'Male') {
        groupedData$Group <- paste(groupedData$Group,groupedData$SEX)
        sexIndex <- which(groupedData$SEX=='M')
        groupedData <- groupedData[sexIndex,]
      } else if (input$sex == 'Female') {
        groupedData$Group <- paste(groupedData$Group,groupedData$SEX)
        sexIndex <- which(groupedData$SEX=='F')
        groupedData <- groupedData[sexIndex,]
      } else if (input$sex == 'Both (split)') {
        groupedData$Group <- paste(groupedData$Group,groupedData$SEX)
      }
      
      # Filter by Time of Sacrifice
      noRecoveryIndex <- which(groupedData$RecoveryStatus==FALSE)
      recoveryIndex <- which(groupedData$RecoveryStatus==TRUE)
      if (input$recovery == 'Main Study Group') {
        groupedData <- groupedData[noRecoveryIndex,]
      } else if (input$recovery == 'Recovery Group') {
        groupedData <- groupedData[recoveryIndex,]
      } else if (input$recovery == 'Both (split)') {
        groupedData$Group[recoveryIndex] <- paste(groupedData$Group[recoveryIndex],'Recovery')
      }
      
      if (nrow(groupedData)>0) {
        
        # Filter by TK
        noTKindex <- which(groupedData$TKstatus==F)
        TKindex <- which(groupedData$TKstatus==T)
        groupedData$TK <- ''
        groupedData$TK[noTKindex] <- 'No TK'
        groupedData$TK[TKindex] <- 'TK'
        if (input$includeTK=='No TK') {
          groupedData <- groupedData[noTKindex,]
        } else if (input$includeTK=='TK only') {
          groupedData <- groupedData[TKindex,]
        }  else if (input$includeTK=='Both (pooled)') {
          groupedData <- groupedData
        } else if (input$includeTK=='Both (split)') {
          groupedData$Group <- paste(groupedData$Group,groupedData$TK)
          groupedData <- groupedData
        }
        groupedData$Group <- factor(groupedData$Group)
      } else if (input$groupMethod=='sets') {
        if ("SPGRPCD" %in% colnames(groupedData)) {
          groupedData$Group <- as.factor(paste(groupedData$SPGRPCD,groupedData$SET,sep=":"))
        } else {
          groupedData$Group <- groupedData$SET
        }
      }
      
      validate(
        need(!is.null(groupedData), label = "Could not read body weight data from dataset")
      )
      
      # Add group list choices for selection
      groupList <- levels(groupedData$Group)
      updateCheckboxGroupInput(session,"Groups", choices = groupList, selected = groupList)
    }
    
    return(groupedData)
  })
  
  prepBWplot <- reactive({
    groupedData <- processData()
    if (is.null(input$Groups) ) { 
      dataFilt <- groupedData
    }
    else if ( length(input$Groups) == 0 ) { 
      dataFilt <- groupedData
    } 
    else {
      dataFilt <- groupedData[groupedData$Group  %in% input$Groups, ]  
    }
    return(dataFilt)
  })
  
  prepBWdiffPlot <- reactive({
    groupedData <- processData()
    if (nrow(groupedData)>0) {
      # retrieve xaxis choice
      xaxis <- input$xaxis
      # filter now based on group selection
      if (is.null(input$Groups) ) { 
        dataFilt <- groupedData
      }
      else if ( length(input$Groups) == 0 ) { 
        dataFilt <- groupedData
      } 
      else {
        dataFilt <- groupedData[groupedData$Group  %in% input$Groups, ]  
      }
      
      dataFilt$BWPDIFF <- NA # create a new column with nothing in it.
      
      for (i in 1:nrow(dataFilt)) 
      {
        DayOneWeight <- dataFilt$BWSTRESN[which((dataFilt[,xaxis]==1) & (dataFilt$USUBJID==dataFilt$USUBJID[i]))]
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
        dataFilt$BWPDIFF[i] <- 100*((dataFilt$BWSTRESN[i]-DayOneWeight) / DayOneWeight)
      }
      return(dataFilt)
    }
  })
  
  prepBGplot <- reactive({
    groupedData <- processData()
    # retrieve xaxis choice
    xaxis <- input$xaxis
    # filter now based on group selection
    if (is.null(input$Groups) ) { 
      dataFilt <- groupedData
    }
    else if ( length(input$Groups) == 0 ) { 
      dataFilt <- groupedData
    } 
    else {
      dataFilt <- groupedData[groupedData$Group  %in% input$Groups, ]  
    }
    
    # Order Dataset by Subject and then by Day
    dataFilt <- dataFilt[order(dataFilt$USUBJID,dataFilt[,xaxis]),]
    
    # Calculate Body Weight Gains and Filter by Interval Length
    dataFilt$BGSTRESN <- dataFilt$BWSTRESN
    for (subject in unique(dataFilt$USUBJID)) {
      index <- which(dataFilt$USUBJID==subject)
      subjectData <- dataFilt[index,]
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
      dataFilt$BGSTRESN[index] <- bgDataTmp
    }
    
    # Remove NA values from dataset
    dataFilt <- dataFilt[which(is.finite(dataFilt$BGSTRESN)),]
    return(dataFilt)
  })
  
  createPlot <- function(df,response) {
    response_mean <- paste(response,'mean',sep='_')
    response_se <- paste(response,'se',sep='_')
    # retrieve xaxis choice
    xaxis <- input$xaxis
    if (input$plotType == 'Mean Data Points') {
      if (input$sex != 'Both (pooled)') {
        dfMeans <- createMeansTable(df,response,c('Group',xaxis),'Sex')
      } else {
        dfMeans <- createMeansTable(df,response,c('Group',xaxis))
        dfMeans <- dfMeans[!is.na(dfMeans$Group),]
        dfMeans$Sex <- 'M/F Pooled'
      }
      dfMeans <- dfMeans[!is.na(dfMeans[[response_mean]]),]
      dfMeans$Sex <- factor(dfMeans$Sex)
      dfMeans$Group <- factor(dfMeans$Group,levels=sort(levels(dfMeans$Group)))
      if (input$plotly==FALSE) {
      p <- ggplot(dfMeans,aes(x=dfMeans[,xaxis],y=get(response_mean),colour=Group,label=Group,shape=Sex)) + geom_point(size=3)
      } else {
        p <- ggplot(dfMeans,aes(x=dfMeans[,xaxis],y=get(response_mean),colour=Group,label=Group)) + geom_point(size=3)
      }
      if (input$printSE == TRUE) {
        p <- p + geom_errorbar(aes(ymin=(get(response_mean)-get(response_se)),ymax=(get(response_mean)+get(response_se))),width=0.8)
      }
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    } else if (input$plotType == 'Boxplots') {
      xaxis_levels <- as.character(sort(as.numeric(unique(df[,xaxis]))))
      df[,xaxis] <- factor(df[,xaxis],levels=xaxis_levels)
      p <- ggplot(df,aes(x=df[,xaxis],y=get(response),fill=Group,label=Group))+
        geom_boxplot()
    } else {
      # plot with color by group
      df$`Group | Subject ID` <- paste(df$Group,df$USUBJID,sep=' | ')
      if (input$plotly==FALSE) {
        p <- ggplot(df,aes(x=df[,xaxis],y=get(response),group=USUBJID,colour=Group,label=`Group | Subject ID`,shape=Sex)) + geom_point(size=3)
      } else {
        p <- ggplot(df,aes(x=df[,xaxis],y=get(response),group=USUBJID,colour=Group,label=`Group | Subject ID`)) + geom_point(size=3)
      }
      if (input$printLines == TRUE) {
        # plot with lines connecting subjects
        p <- p + geom_line()
      }
    }
    p <- p + labs(x=xaxis) + theme_minimal() + theme(text = element_text(size=16))
    return(p)
  }
  
  # Plot Body Weights
  output$BWplot <- renderPlot({
    dataFilt <- prepBWplot()
    p <- createPlot(dataFilt,'BWSTRESN')
    if (length(unique(dataFilt$BWSTRESU))==1) {
      Unit <- unique(dataFilt$BWSTRESU)
    } else {
      maxLength <- 0
      for (candidate in unique(dataFilt$BWSTRESU)) {
        candidateLength <- length(which(dataFilt$BWSTRESU==candidate))
        if (candidateLength>maxLength) {
          maxLength <- candidateLength
          Unit <- candidate
        }
      }
    }
    p <- p + ggtitle('Body Weight Plot') + labs(y=paste('Body Weight (',Unit,')',sep=''))
    print(p)
  })
  
  # Plotly Body Weights
  output$BWplotly <- renderPlotly({
    dataFilt <- prepBWplot()
    p <- createPlot(dataFilt,'BWSTRESN')
    if (length(unique(dataFilt$BWSTRESU))==1) {
      Unit <- unique(dataFilt$BWSTRESU)
    } else {
      maxLength <- 0
      for (candidate in unique(dataFilt$BWSTRESU)) {
        candidateLength <- length(which(dataFilt$BWSTRESU==candidate))
        if (candidateLength>maxLength) {
          maxLength <- candidateLength
          Unit <- candidate
        }
      }
    }
    p <- p + ggtitle('Body Weight Plot') + labs(y=paste('Body Weight (',Unit,')',sep=''))
    if (input$plotType=='Boxplots') {
      p <- ggplotly(p)%>%layout(boxmode='group')
    } else {
      p <- ggplotly(p,tooltip=c('label'))
    }
    p$elementId <- NULL
    p
  })
  
  # Plot Body Weights Percent Difference from Day 1
  output$BWDiffplot <- renderPlot({
    dataFilt <- prepBWdiffPlot()
    p <- createPlot(dataFilt,'BWPDIFF')
    p <- p + ggtitle('Body Weight Percent Difference from Day 1 Plot') + labs(y='Percent Baseline Body Weight (%)')
    print(p)
  })
  
  # Plotly Body Weights Percent Difference from Day 1
  output$BWDiffplotly <- renderPlotly({
    dataFilt <- prepBWdiffPlot()
    p <- createPlot(dataFilt,'BWPDIFF')
    p <- p + ggtitle('Body Weight Percent Difference from Day 1 Plot') + labs(y='Percent Baseline Body Weight (%)')
    if (input$plotType=='Boxplots') {
      p <- ggplotly(p)%>%layout(boxmode='group')
    } else {
      p <- ggplotly(p,tooltip=c('label'))
    }
    p$elementId <- NULL
    p
  })
  
  # Plot Body Weight Gains (using user-defined interval)
  output$BGplot <- renderPlot({
    dataFilt <- prepBGplot()
      p <- createPlot(dataFilt,'BGSTRESN')
      if (length(unique(dataFilt$BWSTRESU))==1) {
        Unit <- unique(dataFilt$BWSTRESU)
      } else {
        maxLength <- 0
        for (candidate in unique(dataFilt$BWSTRESU)) {
          candidateLength <- length(which(dataFilt$BWSTRESU==candidate))
          if (candidateLength>maxLength) {
            maxLength <- candidateLength
            Unit <- candidate
          }
        }
      }
      p <- p + ggtitle('Body Weight Gain Plot') + labs(y=paste('Change in Body Weight (',Unit,')',sep=''))
      print(p) 
  })
  
  # Plotly Body Weight Gains (using user-defined interval)
  output$BGplotly <- renderPlotly({
    dataFilt <- prepBGplot()
    p <- createPlot(dataFilt,'BGSTRESN')
    if (length(unique(dataFilt$BWSTRESU))==1) {
      Unit <- unique(dataFilt$BWSTRESU)
    } else {
      maxLength <- 0
      for (candidate in unique(dataFilt$BWSTRESU)) {
        candidateLength <- length(which(dataFilt$BWSTRESU==candidate))
        if (candidateLength>maxLength) {
          maxLength <- candidateLength
          Unit <- candidate
        }
      }
    }
    p <- p + ggtitle('Body Weight Gain Plot') + labs(y=paste('Change in Body Weight (',Unit,')',sep=''))
    if (input$plotType=='Boxplots') {
      p <- ggplotly(p)%>%layout(boxmode='group')
    } else {
      p <- ggplotly(p,tooltip=c('label'))
    }
    p$elementId <- NULL
    p 
  })
  
}

############################################################################################

############################### Define GUI for Application #################################

ui <- fluidPage(
  
  titlePanel("Body Weight Gains Plot"),
  
  sidebarLayout(
    
    sidebarPanel(
      h3('Study Selection'),
      selectInput('dataSource','Select Data Source:',c('GitHub','local')),
      conditionalPanel(
        condition = 'input.dataSource=="GitHub"',
        uiOutput('selectGitHubStudy')
      ),
      conditionalPanel(
        condition = 'input.dataSource=="local"',
        actionButton('chooseBWfile','Choose a BW Domain File')
      ),br(),
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
      checkboxInput('plotly',label='Interactive Plot',value=F),
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
        condition = "input.showBWPlot==true && input.plotly==false",
        plotOutput("BWplot",height='600px')
      ),
      conditionalPanel(
        condition = "input.showBWPlot==true && input.plotly==true",
        plotlyOutput("BWplotly",height='600px')
      ),
      conditionalPanel(
        condition = "input.showBWDiffPlot==true && input.plotly==false",
        plotOutput("BWDiffplot",height='600px')
      ),
      conditionalPanel(
        condition = "input.showBWDiffPlot==true && input.plotly==true",
        plotlyOutput("BWDiffplotly",height='600px')
      ),
      conditionalPanel(
        condition = "input.showBGPlot==true && input.plotly==false",
        plotOutput("BGplot",height='600px')
      ),
      conditionalPanel(
        condition = "input.showBGPlot==true && input.plotly==true",
        plotlyOutput("BGplotly",height='600px')
      )
    ) 
  )
)

############################################################################################

# Run Shiny App
shinyApp(ui = ui, server = server)