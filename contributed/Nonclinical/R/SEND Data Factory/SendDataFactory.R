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
# Next steps:
# [Kevin] Update so that no errors occur in main window on initial run
# [Kevin] Update so that you see in main windows all the dataset files with row counts and allow drill down to each
# [Kevin] Update measurement choices to cover all possible 3.1 domains
# [Bob] Need SEND IG (for variables, domains and types) in readable format (csv, excel, owl, etc)
# [Eli] Read in CT versions (selectable by date?) for use in Species and strain choices
# [Eli] Read in CT versions (selectable by date?) for use in observational domains especially
# [Kevin] Configuration files for ranges of numeric fields
# Output of all domains selected (each person can pic)
#   Trial domains
#   Animal demographics and disposition
#   In-life domains
#   Post mortem domains
# Implementation for SEND 3.1 first, then DART, SEND 3.0
#     
#
#
# install pacakges if needed
.libPaths()
list.of.packages <- c("shiny",
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
"DT")



new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org")
# Load Libraries
library(shiny)
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

if(packageVersion("SASxport") < "1.5.7") {
  stop("You need version 1.5.7 or later of SASxport")
}
# This section is to replace functions in 1.5.7 or SASxport to allow column lengths of less than 8 bytes
# This gives the directory of the file where the statement was placed , to get current .R script directory
sourceDir <- getSrcDirectory(function(dummy) {dummy})
source(paste(sourceDir, "/write.xport2.R", sep=""))
tmpfun <- get("read.xport", envir = asNamespace("SASxport"))
environment(write.xport2) <- environment(tmpfun)
attributes(write.xport2) <- attributes(tmpfun)
assignInNamespace("write.xport", write.xport2, ns="SASxport")
##########

# Functions
convertMenuItem <- function(mi,tabName) {
  mi$children[[1]]$attribs['data-toggle']="tab"
  mi$children[[1]]$attribs['data-value'] = tabName
  mi
}

readDomainStructure <- function(domain) {
  sourceDir <- getSrcDirectory(function(dummy) {dummy})
  inFile <- (paste(sourceDir, "/",domain,"Structure.xlsx", sep=""))
  # Read in XLSX file
  tsIn <<- readWorksheetFromFile(inFile,
                              sheet=1,
                              startRow = 1,
                              endCol = 7)
}

# read all domain structures
readDomainStructures <-function() {
  # FIXME Read more domains
  readDomainStructure("TS")
}

setTSFile <- function(input) {
    # start with input structure
    tsOut <<- tsIn
    # set values for output
    if (!is.null(input$studyName)) {
      tsOut$STUDYID <<- input$studyName
    }
    if (!is.null(input$testArticle)) {
      tsOut$TSVAL[tsOut$TSPARMCD=="TRT"] <<-  input$testArticle
    }
    if (!is.null(input$species)) {
      tsOut$TSVAL[tsOut$TSPARMCD=="SPECIES"] <<-  input$species
    }
    if (!is.null(input$studyType)) {
      tsOut$TSVAL[tsOut$TSPARMCD=="SSTYP"] <<-  input$studyType
    }
    # FIXME - set rest of values
}

# set or create the output data
setOutputData <- function(input) {
   setTSFile(input)  
}

createOutputDirectory <- function (aDir,aStudy) {	
  setwd(aDir)
  if (file.exists(aStudy)){
    setwd(file.path(aDir, aStudy))
  } else {
    dir.create(file.path(aDir, aStudy))
    setwd(file.path(aDir, aStudy))
  }
}

  writeDatasetToTempFile <- function (studyData,domain,domainLabel,tempFile) {
    # get rid of NAs
    studyData[is.na(studyData)] <- ""
    # Set length for character fields
    SASformat(studyData$DOMAIN) <-"$2."	
    # place this dataset into a list with a name
    aList = list(studyData)
    # name it
    names(aList)[1]<-domain
    # and label it
    attr(aList,"label") <- domainLabel
    # write out dataframe
    write.xport2(
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


sleepSeconds <- function(x)
{
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1 # The cpu usage should be negligible
}

addUIDep <- function(x) {
  jqueryUIDep <- htmlDependency("jqueryui", "1.10.4", c(href="shared/jqueryui/1.10.4"),
                                script = "jquery-ui.min.js",
                                stylesheet = "jquery-ui.min.css")
  
  attachDependencies(x, c(htmlDependencies(x), list(jqueryUIDep)))
}

## Read in CT file, This should only be called from the getCT function.
importCT <- function(version) {
  
  # Switch function to determine version
  # Assumes a CT folder with CDISC library exports
  df <- switch(version,
               '2018-09' = readWorksheetFromFile("CT/SEND_Terminology_2018-09-28.xls",
                                                 "SEND Terminology 2018-09-28"),
               '2018-06' = readWorksheetFromFile("CT/SEND_Terminology_2018-06-29.xls",
                                                 "SEND Terminology 2018-06-29")
  )
  
  # Attribute used to determine if user changes CT version.
  attr(df, "version") <- version
  
  df
  
}

# Return CT codelist
getCT <- function(codelist, version) {
  
  # If CT hasn't been loaded in already, superassign to parent environment
  if(!exists("CTdf") || !(attr(CTdf, "version") == version)) CTdf <<- importCT(version)
  
  
  # Return the reqested codelist as a character vector, remove the codelist header row.
  CTdf[(CTdf$`Codelist Name` == codelist) &
         !(is.na(CTdf$`Codelist Code`)), "CDISC Submission Value"]
}

# Source Functions
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')
# source('~/PhUSE/Repo/trunk/contributed/Nonclinical/R/Functions/Functions.R')

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
  
  # Store Client Data Regarding previous choices
  cdata <- session$clientData
  
  # Set study name
  output$StudyName <- renderUI({
    # FIXME - remember last choice
    textInput('studyName','Study Name to create:')
  })

  # Set test article
  output$TestArticle <- renderUI({
    # FIXME - remember last choice
    textInput('testArticle','Test article:')
  })
  
  # Display Send versions
  output$SENDVersions <- renderUI({
    # FIXME - these should come from a configuration file
    SENDVersion <- c("SEND IG 3.0","SEND IG 3.1", "DART IG 1.1")
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
    # FIXME - these should come from a configuration file
    species <- c("Canine","Monkey","Rat","Mouse","Guinea pig","Rabbit")
    radioButtons('species','Select species:',species,selected=species[1])
  })
  
  # Display output type
  output$Strain <- renderUI({
    # FIXME - these should come from a configuration file,conditional on species
    strain <- c("TBD")
    radioButtons('strain','Select strain:',strain,selected=strain[1])
  })

    # Display Study types
  output$StudyType <- renderUI({
    # FIXME - these should come from a configuration file
    studyType <- c("Single-dose","Multi-dose","Carcinogenicity","Safety Pharm - Respiratory","Safety Pharm - Cardiovascular","Early Fetal Development")
    radioButtons('studyType','Select Study Type:',studyType,selected=studyType[1])
  })

  # Display Subgroups
  output$Subgroups <- renderUI({
    # FIXME - these should come from a configuration file
    subgroups <- c("TK animals","Recovery animals")
    checkboxGroupInput('subgroups','Select set options:',subgroups,selected=subgroups[1])
  })
  
  # Display Number of sex choice
  output$Sex <- renderUI({
    # FIXME - these should come from a configuration file
    sex <- c("Male","Female")
    checkboxGroupInput('sex','Select sex:',sex,selected=c(sex))
  })

    # Display Number of animals per group
  output$AnimalsPerGroup <- renderUI({
    # FIXME - these should come from a configuration file
    animalsPerGroup <- c("4","8","16","20","40","100")
    checkboxGroupInput('animalsPerGroup','Select animals Per Group:',animalsPerGroup,selected=animalsPerGroup[1])
  })

    # Display Test Categories
  output$OutputCategories <- renderUI({
  # FIXME - these should come from a configuration file
    testCategories <- c("Exposure","Body weights","Mass observations","Food consumption","Urinanalysis","Hematology","Organ weights","Macropathology","Micropathology","ECG")
    checkboxGroupInput('testCategories','Data domains to create:',testCategories,selected=testCategories)
  })
  
  # Display Treatment Selection
  output$Treatment <- renderUI({
    # FIXME - these should come from a configuration file
    treatmentList <- c("Control group","Group 2: Low dose","Group 3: Mid dose","Group 4: High dose")
    checkboxGroupInput('treatment',label='Select Treatment Groups:',choices=treatmentList,selected=treatmentList)
  })

  # view Tsdata
  output$tsData <- renderTable({
    tsOut
  })
  
  # Downloadable  dataset ----
  # FIXME _ make zip of all the data, all domains
  output$downloadData <- downloadHandler(
    filename = function() {
      "ts.xpt"
    },
    content = function(file) {
      # write to this file
      writeDatasetToTempFile(tsOut,"TS","TRIAL SUMMARY",file)
    }
  )  
  
  # Produce datasets
  observeEvent(ignoreNULL=TRUE,eventExpr=input$produceDatasets,
               handlerExpr={
                 withProgress({
                        # Read domain structures
                        readDomainStructures()
                        setOutputData(input)
                        # FIXME - use temporary directory?
                        createOutputDirectory(sourceDir,input$studyName)
                        # FIXME - must actually create all domain files
                        # FIXME - must actually create these files
                        aValue <- 1
                        for (aData in input$testCategories) {
                          setProgress(value=aValue,message=paste('Producting dataset',aData))
                          sleepSeconds(1)
                          aValue <- aValue + 1
                        }
                 })
               })
  
}

# NEED TO UPDATE SERVERS AND GITHUB

ui <- dashboardPage(
  
  dashboardHeader(title='SEND data factory',titleWidth=sidebarWidth),
  
  dashboardSidebar(width=sidebarWidth,
                   sidebarMenu(id='sidebar',
                    menuItem('Output settings',icon=icon('database'),startExpanded=T,
                              withSpinner(uiOutput('SENDVersions'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Outputtype'),type=7,proxy.height='200px')
                     ),
                     menuItem('Study design',icon=icon('calendar'),startExpanded=F,
                              withSpinner(uiOutput('StudyName'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('TestArticle'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('StudyType'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Treatment'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Subgroups'),type=7,proxy.height='200px')
                     ),
                     menuItem('Animal information',icon=icon('paw'),startExpanded=F,
                              withSpinner(uiOutput('Species'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Strain'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('Sex'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('AnimalsPerGroup'),type=7,proxy.height='200px')
                     ),
                     menuItem('Data selections',icon=icon('flask'),startExpanded=F,
                              withSpinner(uiOutput('OutputCategories'),type=7,proxy.height='200px')
                     ),
                     menuItem('Produce Data',icon=icon('angle-double-right'),startExpanded=T,
                             actionButton('produceDatasets',label='Produce datasets'),
                             downloadButton("downloadData", "Download dataset")
                     ),
                    menuItem('Other Settings',icon=icon('cogs'),startExpanded=F,
                             actionButton('clearSetup',label='Clear All')
                    )
                   )
  ),
  
  dashboardBody(
    
    tags$script(HTML("$('body').addClass('sidebar-mini');")),
    tags$script(HTML("$('body').addClass('treeview');")),
    h3('Datasets created'),
    tableOutput("tsData")
  )
  
)

# Run Shiny App
shinyApp(ui = ui, server = server)
