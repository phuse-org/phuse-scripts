# This application can be run for free on a public server at the following address:
# (TBD)
#
# Purpose: Creates SEND datasets with made up data
# Currently can: Allow selections, creates a short ts.xpt file to download
# To use:
#    Get files from github folder Run app in Rstudio
#    Expand and make selections in all left side selectors 
#    Select "Product datasets", they will be downloaded through your browser
#
# Note, that zip requires RTOOLS34.exe (or later)
# Install from https://cran.r-project.org/bin/windows/Rtools/, and make sure install directory
# is on the environment path variable
#
# Done:
# [Eli] Read in CT versions (selectable by date) for use in Species and strain choices
# [Eli] Read in CT versions (selectable by date) for use in observational domains especially
# [Bob] Update CT read to use web location, use this to show Species choices
# [Bob] SEND IG (for variables, domains and types) read from PDF file into a dataframe
# [Bob] Uses the read SEND IG structure to create the ts.xpt file
# [Bob] Correct labels for each domain, ts.xpt file needs labels set correctly
# [Eli] Allow selection of controlled terminology version dates from GUI
# [Eli] Allow selection of controlled terminology for other dashboard items that should come from controlled terminology. strain is one.
# [Bob] Structure xls file no longer needed, as now read from SEND IG directly
# [Bob] Read rest of TS values from a csv file that can be edited on screen and saved
# [Bob] Creates TA, TE, TX domains
# [Bob] Animal should only have 1 TBW, at the end of animal disposition
# [Bob] No need for sasxport changes after 1.6.0 version
# [Bob] Correct spelling of producting, read function.r online,add timeout for xls download,get mean and s.d. from configuration
# [Bob] correct progress "message", only output 1 day each for PC,PP,LB data
# [Bob] Correct TESTCD from numeric datasets, add note in selection that EG, FW, EX, OM,MA,MI,PC are not ready (need configurations)
# [Bob] Enable pp output
# [Bob] Save SENDIG dataset so not SENDIG download needed, reestablish MA and MI output
# [Bob] Move checkCore to SENDIGReader so it loads the function while loading other scripts

# Next steps:
# [???] Need configuration file for OM domain
# [???]   Configuration files need units 
# [Bob] Animals per group should be a single selection
# [Kevin] Update so that no errors occur in main window on initial run
# [Kevin] Update so that you see in main windows all the dataset files with row counts and allow drill down to each
# [Kevin] Update measurement choices to cover all possible 3.1 domains
# [Kevin] Configuration files for ranges of numeric fields
# Output of all domains selected
#   [Eli] Animal demographics and disposition 
#   [Bob] In-life domains - adjust to length of the study
#   [Bob] Post mortem domains 
# Implementation for SEND 3.1 first, then DART, SEND 3.0
# [Bob] Test output against validator
#     
#
#
# install pacakges if needed
.libPaths()
list.of.packages <- c("shiny","shinyalert",
"ggplot2",
"plotly",
"reshape2",
"htmltools",
"RColorBrewer",
"grid",
"GGally",
"MASS",
"shinydashboard",
"shinycssloaders",
"httr",
"tools",
"Hmisc",
"XLConnect",
"SASxport",
"utils",
"DT",
"pdftools",
"rhandsontable",
"parsedate",
"shinyjs")


new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org")
# Load Libraries
library(shiny)
library(shinyjs)
library(shinyalert)
library(ggplot2)
library(plotly)
library(reshape2)
library(htmltools)
library(RColorBrewer)
library(grid)
library(GGally)
library(MASS)
library(shinydashboard)
library(shinycssloaders)
library(httr)
library(tools)
library(Hmisc)
library(XLConnect)
library(SASxport)
library(utils)
library(DT)
library(pdftools)
library(rhandsontable)
library(parsedate)

if(packageVersion("SASxport") < "1.6.0") {
  stop("You need version 1.6.0 or later of SASxport")
}

# sourcedir works in rstudio
sourceDir <<- getSrcDirectory(function(dummy) {dummy})

# Source Functions
# allow to work offline by not using the next line:
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')
#  Use this next line if not on internet
#  source(paste(sourceDir, '/Functions.R', sep = ""))
source(paste(sourceDir, "/SENDColumnData.R", sep=""))
source(paste(sourceDir, "/SendDataGenerator.R", sep=""))
source(paste(sourceDir, "/SendTrialDomains.R", sep=""))
source(paste(sourceDir, "/SendAnimalDomains.R", sep=""))
source(paste(sourceDir, "/SendIgReader.R", sep=""))
source(paste(sourceDir, "/CtReader.R", sep=""))
source(paste(sourceDir, "/ConfigData.R", sep=""))

# Functions
convertMenuItem <- function(mi,tabName) {
  mi$children[[1]]$attribs['data-toggle']="tab"
  mi$children[[1]]$attribs['data-value'] = tabName
  mi
}

# Check for all required input selections
checkRequiredInput <- function(input) {
  aList <- ""
  saveI <<- input
  if (is.null(input$studyName)) { aList <- paste(aList,"Study name;") }
  if (is.null(input$CTSelection)) { aList <- paste(aList,"CT version;") }
  if (is.null(input$TSTable)) { aList <- paste(aList,"Trial summary data;") }
  if (is.null(input$DoseTable)) { aList <- paste(aList,"Dose levels;") }
  if (is.null(input$testArticle)) { aList <- paste(aList,"Test article;") }
  if (is.null(input$sex)) { aList <- paste(aList,"Sexes;") }
  if (is.null(input$treatment)) { aList <- paste(aList,"Treatments;") }
  if (is.null(input$animalsPerGroup)) { aList <- paste(aList,"Animals per group;") }
  if (is.null(input$species)) { aList <- paste(aList,"Species;") }
  if (is.null(input$strain)) { aList <- paste(aList,"Strain;") }
  if (is.null(input$elementOptions )) { aList <- paste(aList,"Element options;") }
  if (is.null(input$TKanimalsPerGroup)) { aList <- paste(aList,"TK animals per group;") }
  if (nchar(aList)>1) {stop(aList)}
}




# read TS from CSV file saved
readTSCSVFile <-function() {
  setwd(sourceDir)
  TSFromFile <<- read.csv("TSFileSettings.csv", header=TRUE)
}

# write TS to CSV file  
writeTSCSVFile <-function() {
  write.csv(TSFromFile,"TSFileSettings.csv",row.names=FALSE)
}

# read Dose from CSV file saved
readDoseFile <-function() {
  setwd(sourceDir)
  DoseFromFile <<- read.csv("DosingConfiguration.csv", header=TRUE)
}

# write TS to CSV file  
writeDoseFile <-function() {
  write.csv(DoseFromFile,"DosingConfiguration.csv",row.names=FALSE)
}

# Add to list to be output
addToSet <<- function(inDomain,inDescription,inDataframe) {
  index <- nrow(domainDFsMade)
  domainDFsMade[index+1,] <<- list(inDomain,inDescription,inDataframe)
}



# set or create the output data
setOutputData <- function(input) {
   # create a data frame to hold the created individual dataframes of data
  domainDFsMade <<- setNames(data.frame(matrix(ncol = 3, nrow = 1)),
                         c("Domain","Description","Dataframe"))
   # save selected CT to a global variable
   gCTVersion <<-input$CTSelection
   setProgress(value=1/30,message='  Producing TS data')
   setTSFile(input)  
   setProgress(value=2/30,message='  Producing TE data')
   setTEFile(input)  
   setProgress(value=3/30,message='  Producing TA data')
   setTAFile(input)  
   setProgress(value=4/30,message='  Producing TX data')
   setTXFile(input) 
   setProgress(value=5/30,message='  Producing DM data')
   setDMFile(input)
   setProgress(value=6/30,message='  Producing SE data')
   setSEFile(input)
   setProgress(value=7/30,message='  Producing DS data')
   setDSFile(input)
   setProgress(value=8/30,message='  Producing EX data')
   setEXFile(input)
   setAnimalDataFiles(input)
}

  writeDatasetToTempFile <- function (studyData,domain,domainLabel,tempFile) {
    # get rid of NAs even if as a character value of "NA"
    studyData[is.na(studyData)] <- ""
    studyData[studyData=="NA"] <- ""
    # Set length for character fields
    SASformat(studyData$DOMAIN) <-"$2."	
    # place this dataset into a list with a name
    aList = list(studyData)
    # name it
    names(aList)[1]<-domain
    # and label it
    attr(aList,"label") <- domainLabel
    # write out dataframe
    write.xport(
      list=aList,
      file = tempFile,
      verbose=FALSE,
      sasVer="7.00",
      osType=R.version.string,	
      cDate=Sys.time(),
      formats=NULL,
      autogen.formats=TRUE
    )
  }




addUIDep <- function(x) {
  jqueryUIDep <- htmlDependency("jqueryui", "1.10.4", c(href="shared/jqueryui/1.10.4"),
                                script = "jquery-ui.min.js",
                                stylesheet = "jquery-ui.min.css")
  
  attachDependencies(x, c(htmlDependencies(x), list(jqueryUIDep)))
}


# Get GitHub Password (if possible)
if (file.exists('~/passwordGitHub.R')) {
  source('~/passwordGitHub.R')
  Authenticate <- TRUE
} else {
  Authenticate <- FALSE
}

# Set Reactive Values
values <- reactiveValues()

# Set Heights and Widths
sidebarWidth <- '300px'
plotHeight <- '800px'
server <- function(input, output, session) {

  # Read domain structures
  readDomainStructures()
  # Read TS domain other values
  readTSCSVFile()
  readDoseFile()
  
  # Store Client Data Regarding previous choices
  cdata <- session$clientData
  
  # Set study name
  output$StudyName <- renderUI({
    textInput('studyName','Study Name to create:',value='MyStudy')
  })

  # Set test article
  output$TestArticle <- renderUI({
    textInput('testArticle','Test article:',value='MyDrug')
  })
  
  # Display Send versions
  output$SENDVersions <- renderUI({
    # FIXME - these should come from a configuration file
    SENDVersion <- c("3.0","3.1", "DART 1.1")
    radioButtons('SENDVersions','Select SEND Version:',SENDVersion,selected=SENDVersion[1])
  })

  # Display output type
  output$Outputtype <- renderUI({
    # FIXME - these should come from a configuration file
    outputtype <- c("XPT files","CSV files")
    radioButtons('outputtype','Select output type:',outputtype,selected=outputtype[1])
  })

    # Display species
  output$Species <- renderUI({
    # Get species choices from the code list
    species <- getCTDF("Species", input$CTSelection)[,"CDISC.Submission.Value"]
    selectInput('species','Select species:',species,selected=species[1])
  })
  
  # Display output type
  output$Strain <- renderUI({
    # FIXME - these should come from a configuration file,conditional on species
    strain <- getCTDF("Strain/Substrain", input$CTSelection)[,"CDISC.Submission.Value"]
    selectInput('strain','Select strain:',strain,selected=strain[1])
  })

    # Display Study types
  output$StudyType <- renderUI({
    # FIXME - these should come from a configuration file
    studyType <- c("Single-dose","Multi-dose","Carcinogenicity","Safety Pharm - Respiratory","Safety Pharm - Cardiovascular","Early Fetal Development")
    radioButtons('studyType','Select Study Type:',studyType,selected=studyType[1])
  })

  # Display ElementOptions
  output$ElementOptions <- renderUI({
    # FIXME - these should come from a configuration file
    elementOptionChoices <- c("Pre-treatment","Recovery")
    checkboxGroupInput('elementOptions','Select element options:',elementOptionChoices,selected=unlist(elementOptionChoices))
  })
  
  # Display Number of sex choice
  output$Sex <- renderUI({
    # FIXME - these should come from a configuration file
    sexList <- c("M","F")
    checkboxGroupInput('sex','Select sex:',sexList,selected=c(sexList))
  })

    # Display Number of animals per group
  output$AnimalsPerGroup <- renderUI({
    # FIXME - these should come from a configuration file
    animalsPerGroup <- c("4","8","16","20","40","100")
    radioButtons('animalsPerGroup','Select animals Per Group:',animalsPerGroup,selected=animalsPerGroup[1])
  })

  # Display Number of TK animals per group
  output$TKAnimalsPerGroup <- renderUI({
    # FIXME - these should come from a configuration file
    TKanimalsPerGroupList <- c("0","2","4","6","8")
    radioButtons('TKanimalsPerGroup','Select TK animals Per Group:',TKanimalsPerGroupList,selected=TKanimalsPerGroupList[1])
  })
  
  # Display Test Categories
  output$OutputCategories <- renderUI({
    testDomains <- c("BW", "CL", "FW", "LB", "OM", "MA", "MI", "EG","PC","PP")
    testCategories <- c("Body weights","Clinical Observations","Food consumption (not ready)","Lab Tests",
                        "Organ weights (not ready)","Macropathology","Micropathology","ECG (not ready)",
                        "Pharmacokinetic Concentrations (not ready)","Pharmacokinetic Parameters")
    checkboxGroupInput('testCategories','Data domains to create:',choiceValues=testDomains,choiceNames=testCategories,selected=testCategories)
  })
  
  # Display Treatment Selection
  output$Treatment <- renderUI({
    # FIXME - these should come from a configuration file
    treatmentList <- c("Vehicle Control","Group 2: Low dose","Group 3: Mid dose","Group 4: High dose")
    checkboxGroupInput('treatment',label='Select Treatment Groups:',choices=treatmentList,selected=treatmentList)
  })

  # view SEND structure
  output$SENDIGStructure <- renderTable({
    dfSENDIG
  })

  output$TSTable <- renderRHandsontable({
     rhandsontable(TSFromFile) %>%
      hot_col(col = "TSPARMCD", type = "text") %>%
      hot_col(col = "TSPARM", type = "text") %>%
      hot_col(col = "TSVAL", type = "text")
  })
  
  output$DoseTable <- renderRHandsontable({
    rhandsontable(DoseFromFile) %>%
      hot_col(col = "Dose.group", type = "text") %>%
      hot_col(col = "Male.dose.level", type = "text") %>%
      hot_col(col = "Male.dose.units", type = "text") %>%
      hot_col(col = "Female.dose.level", type = "text") %>%
      hot_col(col = "Female.dose.units", type = "text")
  })

    # Downloadable  dataset ----
  # make zip of all the data, all domains
  output$downloadData <- downloadHandler(
    filename = function() {
      tryCatch ({
        # make study name into a zip file
        paste(input$studyName,".zip",sep="")
      }, error = function(e) {validate(need(FALSE,
          paste("Unable to create output. Ensure you have entered a study name "
         ,e
         )))})
      
    },
    content = function(file) {
      # zip from list of all the domains created
      fileList <- list() 
      # skip first blank row
      withProgress({
        setProgress(value=0,message='Dataset file preparation')
        for (aRow in 2:nrow(domainDFsMade)) {
          # append name with domain to make up the individual files that go into the zip
          filePart <- paste(dirname(file),.Platform$file.sep,tolower(domainDFsMade$Domain[aRow]),".xpt",sep="")
          # pass the data frame itself instead of its name as a string
          aDF <- get(domainDFsMade$Dataframe[aRow])
          writeDatasetToTempFile(aDF,domainDFsMade$Domain[aRow],domainDFsMade$Description[aRow],filePart)
          fileList <- c(fileList, filePart)
          setProgress(value=aRow/nrow(domainDFsMade),message=paste('File prepared: ',
          domainDFsMade$Domain[aRow],".xpt",sep=""))
        }
      # combine into zip file
      setProgress(value=1,message=paste('Combining to a zip file'))
      zip(file,unlist(fileList, use.names=FALSE),flags = '-r9Xj')
      zip
      })
    }
  )  
  
  observeEvent(input$saveTSOther, {  
    
    TSFromFile <<-  hot_to_r(input$TSTable)
    writeTSCSVFile()
  })

    observeEvent(input$saveDoseConf, {  
    DoseFromFile <<-  hot_to_r(input$DoseTable)
    writeDoseFile()
  })
  
  # Produce datasets
  observeEvent(ignoreNULL=TRUE,eventExpr=input$produceDatasets,
               handlerExpr={
                 withProgress({
                      setProgress(value=0,message=paste('Producting datasets...'))
                      tryCatch ({ checkRequiredInput(input) 
                          setOutputData(input)
                          # FIXME - use temporary directory?
                          tryCatch ({
                            createOutputDirectory(sourceDir,input$studyName)
                          }, error = function(e) {validate(need(FALSE,
                            paste("Unable to create directory. Ensure you have entered a study name "
                            ,e
                            )))})
                      } , error = function(e) {
                        errore <<- e
                        shinyalert("Missing required selections (you must at least open each data selection section)", e$message, type = "error")}
                      )
                 })
               })
  
  isolate({updateTabItems(session, "sidebar", "SEND_IG_Structure")})
}

# NEED TO UPDATE SERVERS AND GITHUB

ui <- dashboardPage(
  dashboardHeader(title='SEND data factory',titleWidth=sidebarWidth),
  
  dashboardSidebar(width=sidebarWidth,
                   sidebarMenu(id='sidebar',
                    menuItem('Output settings',icon=icon('database'),startExpanded=T,
                              selectInput("CTSelection", "CT Version", choices = CTVersions, selected = "2019-12-20"),
                              withSpinner(uiOutput('SENDVersions'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Outputtype'),type=7,proxy.height='200px')
                     ),
                    menuItem("Show structure", tabName = "SEND_IG_Structure", icon = icon('calendar')), 
                    menuItem('Study design',icon=icon('calendar'),startExpanded=F,
                              withSpinner(uiOutput('StudyName'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('TestArticle'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('StudyType'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Treatment'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('ElementOptions'),type=7,proxy.height='200px')
                     ),
                    menuItem("Addt'l trial summary", tabName = "Additional_Trial_Summary", icon = icon("calendar")), 
                    menuItem("Dosing configuration", tabName = "Dosing_Configuration", icon = icon("calendar")), 
                    menuItem('Animal information',icon=icon('paw'),startExpanded=F,
                              withSpinner(uiOutput('Species'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Strain'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Sex'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('AnimalsPerGroup'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('TKAnimalsPerGroup'),type=7,proxy.height='200px')
                    ),
                     menuItem('Data selections',icon=icon('flask'),startExpanded=F,
                              withSpinner(uiOutput('OutputCategories'),type=7,proxy.height='200px')
                     ),
                     menuItem('Produce Data',icon=icon('angle-double-right'),startExpanded=T,
                             actionButton('produceDatasets',label='Produce datasets'),
                             downloadButton("downloadData", "Download dataset")
                     )
                   )
  ),
  
  dashboardBody(
    useShinyalert(),  # Set up shinyalert
    tags$script(HTML("$('body').addClass('sidebar-mini');")),
    tags$script(HTML("$('body').addClass('treeview');")),
    tabItems(
      tabItem(tabName = "SEND_IG_Structure",
              h3("SEND IG Structure"),
              tableOutput("SENDIGStructure")
      ),
      
      tabItem(tabName = "Additional_Trial_Summary",
              h3("Additional trial summary (editable)"),
              actionButton('saveTSOther',label='Save'),
              rHandsontableOutput("TSTable")
      ),
      tabItem(tabName = "Dosing_Configuration",
              h3("Dosing configurration (editable)"),
              actionButton('saveDoseConf',label='Save'),
              rHandsontableOutput("DoseTable")
      )
    )
  )  
)

# Run Shiny App
shinyApp(ui = ui, server = server)
