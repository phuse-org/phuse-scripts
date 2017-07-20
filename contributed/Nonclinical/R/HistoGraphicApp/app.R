####### Issues to Resolve/Feature to Add ##################################################
#
# 1) Handle unscheduled deaths as intended recovery or non-recovery group
#       - Not sure this can be done in a reliable way (eliminated option from GUI)
# 2) Display parameter setting on side of plot
#
###########################################################################################

################ Setup Application ########################################################

# Check for Required Packages, Install if Necessary, and Load
list.of.packages <- c("shiny","XLConnect","rChoiceDialogs","SASxport")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
library(XLConnect)
library(rChoiceDialogs)
library(SASxport)

# Source Required Functions
source('directoryInput.R')
source('Functions.R')

# Default Study Folder
defaultStudyFolder <- path.expand('~')
############################################################################################


################# Define Functional Response to GUI Input ##################################

server <- function(input, output,session) {
  
  output$clinPath <- renderUI({
    if (input$colorBy=='clinPath') {
      
      # Read in user-defined parameters
      path1 <- readDirectoryInput(session,'directory1')
      path2 <- readDirectoryInput(session,'directory2')
      path3 <- readDirectoryInput(session,'directory3')
      path4 <- readDirectoryInput(session,'directory4')
      path5 <- readDirectoryInput(session,'directory5')
      
      # Set studyIDs
      if (input$numStudies == 1) {
        studyIDs <- path1
      } else if (input$numStudies == 2) {
        studyIDs <- c(path1,path2)
      } else if (input$numStudies == 3) {
        studyIDs <- c(path1,path2,path3)
      } else if (input$numStudies == 4) {
        studyIDs <- c(path1,path2,path3,path4)
      } else if (input$numStudies == 5) {
        studyIDs <- c(path1,path2,path3,path4,path5)
      } else {
        stop("Must choose between 1 and 5 studies!")
      }
      
      studyPath <- NA
      for (i in seq(length(studyIDs))) {
        studyPath[i] <- studyIDs[i]
      }
      
      for (i in seq(length(studyPath))) {
        
        ########## Load in SEND Data and Extract/Rename Relevant Fields ########################
        
        # Get Histopath Data from MI Domain
        if (file.exists(paste(studyPath[i],'lb.xpt',sep='/'))) {
          lbData <- read.xport(paste(studyPath[i],'lb.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'LB.xpt',sep='/'))) {
          lbData <- read.xport(paste(studyPath[i],'LB.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'lb.csv',sep='/'))) {
          lbData <- read.csv(paste(studyPath[i],'lb.csv',sep='/'))
        } else if (file.exists(paste(studyPath[i],'LB.csv',sep='/'))) {
          lbData <- read.csv(paste(studyPath[i],'LB.csv',sep='/'))
        } else {
          stop('LB Domain Missing!')
        }
        
        lbFields <- c('LBTEST','LBTESTCD','STUDYID','LBCAT','LBORRESU')
        lbNames <- c('LongName','ShortName','Study','Type','Units')
        labDataTmp <- subTable(lbFields,lbNames,lbData)
        labDataTmp$Study <- paste('Study',i,sep='')
        if (i == 1) {
          labData <- labDataTmp
        } else {
          labData <- rbind(labData,labDataTmp)
        }
      }
      
      typeIndex <- grep(input$clinPathType,toupper(labData$Type))
      labData <- labData[typeIndex,]
      
      numericIndex <- which((!is.na(labData$Units))&(labData$Units!=''))
      labData <- labData[numericIndex,]
      
      shortNamesAll <- unique(labData$ShortName)
      for (i in seq(length(unique(labData$Study)))) {
        studyIndex <- which(labData$Study==unique(labData$Study)[i])
        shortNamesTmp <- unique(labData$ShortName)
        if (i == 1) {
          shortNames <- shortNamesTmp
        } else {
          shortNames <- intersect(shortNames,shortNamesTmp)
        }
      }
      
      labNames <- list()
      for (shortName in sort(shortNames)) {
        shortNameIndex <- which(labData$ShortName==shortName)
        longName <- levels(labData$LongName)[labData$LongName[shortNameIndex][1]]
        labNames[[longName]] <- shortName
      }
      
      selectInput('param',label='Clinical Pathology Parameter:',choices=labNames)
    }
  })
  
  ##################### Handle Choosing Study Directories ##################################
  
  # Handle Choosing Study 1 Directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory1
    },
    handlerExpr = {
      if (input$directory1 == 1) {
        path = rchoose.dir(default = defaultStudyFolder)
        updateDirectoryInput(session, 'directory1', value = path)
        updateTextInput(session,'study1Name',value=basename(path))
      } else if (input$directory1 > 1) {
        path = rchoose.dir(default = readDirectoryInput(session, 'directory1'))
        updateDirectoryInput(session, 'directory1', value = path)
        updateTextInput(session,'study1Name',value=basename(path))
      }
    }
  )
  
  # Handle Choosing Study 2 Directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory2
    },
    handlerExpr = {
      if (input$directory2 == 1) {
        if (input$directory1 >= 1) {
          path = rchoose.dir(default = readDirectoryInput(session,'directory1'))
          updateDirectoryInput(session, 'directory2', value = path)
          updateTextInput(session,'study2Name',value=basename(path))
        } else {
          path = rchoose.dir(default = defaultStudyFolder)
          updateDirectoryInput(session, 'directory2', value = path)
          updateTextInput(session,'study2Name',value=basename(path))
        }
      } else if (input$directory2 > 1) {
        path = rchoose.dir(default = readDirectoryInput(session, 'directory2'))
        updateDirectoryInput(session, 'directory2', value = path)
        updateTextInput(session,'study2Name',value=basename(path))
      }
    }
  )
  
  # Handle Choosing Study 3 Directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory3
    },
    handlerExpr = {
      if (input$directory3 == 1) {
        if (input$directory1 >= 1) {
          path = rchoose.dir(default = readDirectoryInput(session,'directory1'))
          updateDirectoryInput(session, 'directory3', value = path)
          updateTextInput(session,'study3Name',value=basename(path))
        } else {
          path = rchoose.dir(default = defaultStudyFolder)
          updateDirectoryInput(session, 'directory3', value = path)
          updateTextInput(session,'study3Name',value=basename(path))
        }
      } else if (input$directory3 > 1) {
        path = rchoose.dir(default = readDirectoryInput(session, 'directory3'))
        updateDirectoryInput(session, 'directory3', value = path)
        updateTextInput(session,'study3Name',value=basename(path))
      }
    }
  )
  
  # Handle Choosing Study 4 Directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory4
    },
    handlerExpr = {
      if (input$directory4 == 1) {
        if (input$directory1 >= 1) {
          path = rchoose.dir(default = readDirectoryInput(session,'directory1'))
          updateDirectoryInput(session, 'directory4', value = path)
          updateTextInput(session,'study4Name',value=basename(path))
        } else {
          path = rchoose.dir(default = defaultStudyFolder)
          updateDirectoryInput(session, 'directory4', value = path)
          updateTextInput(session,'study4Name',value=basename(path))
        }
      } else if (input$directory4 > 1) {
        path = rchoose.dir(default = readDirectoryInput(session, 'directory4'))
        updateDirectoryInput(session, 'directory4', value = path)
        updateTextInput(session,'study4Name',value=basename(path))
      }
    }
  )
  
  # Handle Choosing Study 2 Directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory5
    },
    handlerExpr = {
      if (input$directory5 == 1) {
        if (input$directory1 >= 1) {
          path = rchoose.dir(default = readDirectoryInput(session,'directory1'))
          updateDirectoryInput(session, 'directory5', value = path)
          updateTextInput(session,'study5Name',value=basename(path))
        } else {
          path = rchoose.dir(default = defaultStudyFolder)
          updateDirectoryInput(session, 'directory5', value = path)
          updateTextInput(session,'study5Name',value=basename(path))
        }
      } else if (input$directory5 > 1) {
        path = rchoose.dir(default = readDirectoryInput(session, 'directory5'))
        updateDirectoryInput(session, 'directory5', value = path)
        updateTextInput(session,'study5Name',value=basename(path))
      }
    }
  )
  
  ##########################################################################################
  
  
  ####### Create HistoGraphic plot from SEND data when Submit button is clicked ###################
  
  createHistoGraphicPlot <- observeEvent(input$submit,{
    
    withProgress(message = 'Loading SEND data into R...',value=0, {
      
      ############## Set Parameters Based on GUI Input #############################
      
      # Read in user-defined parameters
      path1 <- readDirectoryInput(session,'directory1')
      path2 <- readDirectoryInput(session,'directory2')
      path3 <- readDirectoryInput(session,'directory3')
      path4 <- readDirectoryInput(session,'directory4')
      path5 <- readDirectoryInput(session,'directory5')
      organizeBy <- input$organizeBy
      includeNormal <- input$includeNormal
      removeNormal <- input$removeNormal
      severityFilter <- as.numeric(input$severityFilter)
      filterControls <- input$filterControls
      if (input$numStudies < 2) {
        addStudyCategory <- FALSE
      } else if (input$numStudies > 2) {
        addStudyCategory <- TRUE
      } else {
        addStudyCategory <- input$addStudyCategory
      }
      Study1Name <- input$study1Name
      Study2Name <- input$study2Name
      Study3Name <- input$study3Name
      Study4Name <- input$study4Name
      Study5Name <- input$study5Name
      
      # Set studyIDs
      if (input$numStudies == 1) {
        studyIDs <- path1
      } else if (input$numStudies == 2) {
        studyIDs <- c(path1,path2)
      } else if (input$numStudies == 3) {
        studyIDs <- c(path1,path2,path3)
      } else if (input$numStudies == 4) {
        studyIDs <- c(path1,path2,path3,path4)
      } else if (input$numStudies == 5) {
        studyIDs <- c(path1,path2,path3,path4,path5)
      } else {
        stop("Must choose between 1 and 5 studies!")
      }
      
      # Set Order of Rings and Implement Incidence or Count Decision
      if (input$track == 'incidence') {
        trackIncidence <- TRUE
      } else if (input$track == 'counts') {
        trackIncidence <- FALSE
      }
      
      if (organizeBy == 'Organ') {
        if (addStudyCategory == FALSE) {
          reorderNames <- c("Incidence","SeverityNumber","Organ","Finding","Treatment","Recovery","Sex","SubjectID","StudyID")
        } else {
          reorderNames <- c("Incidence","SeverityNumber","Organ","Finding","StudyID","Treatment","Recovery","Sex","SubjectID")
        }
      } else if (organizeBy == 'Subject') {
        trackIncidence <- FALSE
        if (addStudyCategory == FALSE) {
          reorderNames <- c("Incidence","SeverityNumber","Recovery","Treatment","Sex","SubjectID","Organ","Finding","StudyID")
        } else {
          reorderNames <- c("Incidence","SeverityNumber","StudyID","Recovery","Treatment","Sex","SubjectID","Organ","Finding")
        }
      } else if (organizeBy == 'Custom') {
        if (addStudyCategory == FALSE) {
          reorderNames <- c("Incidence","SeverityNumber",input$layer1,input$layer2,input$layer3,input$layer4,input$layer5,input$layer6,"StudyID")
        } else {
          reorderNames <- c("Incidence","SeverityNumber",input$layer1s,input$layer2s,input$layer3s,input$layer4s,input$layer5s,input$layer6s,input$layer7s)
        }
      }
      updateSelectInput(session,'layer1',selected=reorderNames[3])
      updateSelectInput(session,'layer2',selected=reorderNames[4])
      updateSelectInput(session,'layer3',selected=reorderNames[5])
      updateSelectInput(session,'layer4',selected=reorderNames[6])
      updateSelectInput(session,'layer5',selected=reorderNames[7])
      updateSelectInput(session,'layer6',selected=reorderNames[8])
      if (addStudyCategory == TRUE) {
        updateSelectInput(session,'layer1s',selected=reorderNames[3])
        updateSelectInput(session,'layer2s',selected=reorderNames[4])
        updateSelectInput(session,'layer3s',selected=reorderNames[5])
        updateSelectInput(session,'layer4s',selected=reorderNames[6])
        updateSelectInput(session,'layer5s',selected=reorderNames[7])
        updateSelectInput(session,'layer6s',selected=reorderNames[8])
        updateSelectInput(session,'layer7s',selected=reorderNames[9])
      }
      
      ##########################################################################################
      
      
      ################ Prepare Files/Paths #####################################################
      
      # Set File Paths for Studies
      basePath <- getwd()
      studyPath <- NA
      for (i in seq(length(studyIDs))) {
        studyPath[i] <- studyIDs[i]
      }
      
      # Move to HistoGraphic Directory
      HistoGraphicPath <- paste(basePath,'HistoGraphic',sep='/')
      if (dir.exists(HistoGraphicPath)==FALSE) {dir.create(HistoGraphicPath)}
      setwd(HistoGraphicPath)
      
      # Set Excel File Path
      if (dir.exists(path.expand('~/HistoGraphicTemp'))==FALSE) {dir.create(path.expand('~/HistoGraphicTemp'))}
      outputFilePath <- path.expand('~/HistoGraphicTemp/template.xlsm')
      outputCSVPath <- path.expand('~/HistoGraphicTemp/rawData.csv')
      
      # Create Empty Template File
      file.copy("HistoGraphic.xlsm",outputFilePath,overwrite = TRUE)
      
      ##########################################################################################
      
      
      ############# Generate Data Tables from SEND #############################################
      for (i in seq(length(studyPath))) {
        
        ########## Load in SEND Data and Extract/Rename Relevant Fields ########################
        
        if (file.exists(paste(studyPath[i],'lb.xpt',sep='/'))) {
          lbData <- read.xport(paste(studyPath[i],'lb.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'LB.xpt',sep='/'))) {
          lbData <- read.xport(paste(studyPath[i],'LB.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'lb.csv',sep='/'))) {
          lbData <- read.csv(paste(studyPath[i],'lb.csv',sep='/'))
        } else if (file.exists(paste(studyPath[i],'LB.csv',sep='/'))) {
          lbData <- read.csv(paste(studyPath[i],'LB.csv',sep='/'))
        } else {
          stop('LB Domain Missing!')
        }
        
        lbFields <- c('LBTEST','LBTESTCD','STUDYID','LBSTRESN','VISITDY','USUBJID')
        lbNames <- c('LongName','ShortName','Study','Value','Day','Subject')
        labDataTmp <- subTable(lbFields,lbNames,lbData)
        labDataTmp$Study <- paste('Study',i,sep='')
        if (i == 1) {
          labData <- labDataTmp
        } else {
          labData <- rbind(labData,labDataTmp)
        }
        
        # Get Histopath Data from MI Domain
        if (file.exists(paste(studyPath[i],'mi.xpt',sep='/'))) {
          histoData <- read.xport(paste(studyPath[i],'mi.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'MI.xpt',sep='/'))) {
          histoData <- read.xport(paste(studyPath[i],'MI.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'mi.csv',sep='/'))) {
          histoData <- read.csv(paste(studyPath[i],'mi.csv',sep='/'))
        } else if (file.exists(paste(studyPath[i],'MI.csv',sep='/'))) {
          histoData <- read.csv(paste(studyPath[i],'MI.csv',sep='/'))
        } else {
          stop('MI Domain Missing!')
        }
        histoFields <- c('STUDYID','USUBJID','MISTRESC','MISPEC','MISEV')
        histoNames <- c('StudyID','SubjectID','Finding','Organ','Severity')
        DataTmp <- subTable(histoFields,histoNames,histoData)
        DataTmp <- DataTmp[which(DataTmp$Finding!=""),]
        DataTmp$StudyID <- get(paste('Study',i,'Name',sep=''))
        
        # Get Metadata from DM Domain
        if (file.exists(paste(studyPath[i],'dm.xpt',sep='/'))) {
          demData <- read.xport(paste(studyPath[i],'dm.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'DM.xpt',sep='/'))) {
          demData <- read.xport(paste(studyPath[i],'DM.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'dm.csv',sep='/'))) {
          demData <- read.csv(paste(studyPath[i],'dm.csv',sep='/'))
        } else if (file.exists(paste(studyPath[i],'DM.csv',sep='/'))) {
          demData <- read.csv(paste(studyPath[i],'DM.csv',sep='/'))
        } else {
          stop('DM Domain Missing!')
        }
        demFields <- c('USUBJID','SETCD','SEX')
        demFieldNames <- c('SubjectID','TrialSet','Sex')
        metaDataTmp <- subTable(demFields,demFieldNames,demData)
        StudyID <- rep(DataTmp$StudyID[1],dim(metaDataTmp)[1])
        metaDataTmp <- cbind(metaDataTmp,StudyID)
        for (j in seq(dim(metaDataTmp)[1])) {
          if (metaDataTmp$Sex[j]=='FALSE') {
            metaDataTmp$Sex[j] <- 'F'
          }
        }
        # Remove Subjects that do not have Histopath Data in the MI domain
        keepIndex <- which(metaDataTmp$SubjectID %in% DataTmp$SubjectID)
        metaDataTmp <- metaDataTmp[keepIndex,]
        
        # Get Trial Data from TX Domain
        if (file.exists(paste(studyPath[i],'tx.xpt',sep='/'))) {
          txData <- read.xport(paste(studyPath[i],'tx.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'TX.xpt',sep='/'))) {
          txData <- read.xport(paste(studyPath[i],'TX.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'tx.csv',sep='/'))) {
          txData <- read.csv(paste(studyPath[i],'tx.csv',sep='/'))
        } else if (file.exists(paste(studyPath[i],'TX.csv',sep='/'))) {
          txData <- read.csv(paste(studyPath[i],'TX.csv',sep='/'))
        } else {
          stop('TX Domain Missing!')
        }
        trialFields <- c('SET','TXVAL','TXPARMCD','SETCD')
        trialFieldNames <- trialFields
        trialDataTmp <- subTable(trialFields,trialFieldNames,txData)
        StudyID <- rep(DataTmp$StudyID[1],dim(trialDataTmp)[1])
        trialDataTmp <- cbind(trialDataTmp,StudyID)
        
        # Get Dosing Data from EX Domain
        if (file.exists(paste(studyPath[i],'ex.xpt',sep='/'))) {
          EXdataCSV <- read.xport(paste(studyPath[i],'ex.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'EX.xpt',sep='/'))) {
          EXdataCSV <- read.xport(paste(studyPath[i],'EX.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'ex.csv',sep='/'))) {
          EXdataCSV <- read.csv(paste(studyPath[i],'ex.csv',sep='/'))
        } else if (file.exists(paste(studyPath[i],'EX.csv',sep='/'))) {
          EXdataCSV <- read.csv(paste(studyPath[i],'EX.csv',sep='/'))
        } else {
          stop('EX Domain Missing!')
        }
        if ('EXSTDY' %in% colnames(EXdataCSV)) {
          if (! 'EXENDY' %in% colnames(EXdataCSV)) {
            EXENDY <- rep(NA,nrow(EXdataCSV))
            EXdataCSV <- cbind(EXdataCSV,EXENDY)
          }
          EXfields <- c('USUBJID','EXENDY','EXSTDY')
          EXfieldNames <- c('SubjectID','EndDay','StartDay')
          EXdataTmp <- subTable(EXfields,EXfieldNames,EXdataCSV)
        } else {
          EXfields <- c('USUBJID','EXENDY')
          EXfieldNames <- c('SubjectID','EndDay')
          EXdataTmp <- subTable(EXfields,EXfieldNames,EXdataCSV)
          StartDay <- rep(NA,dim(EXdataTmp)[1])
          EXdataTmp <- cbind(EXdataTmp,StartDay)
        }
        
        # Get Timing of Sacrifice Data from DS Domain
        if (file.exists(paste(studyPath[i],'ds.xpt',sep='/'))) {
          DSdataCSV <- read.xport(paste(studyPath[i],'ds.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'DS.xpt',sep='/'))) {
          DSdataCSV <- read.xport(paste(studyPath[i],'DS.xpt',sep='/'))
        } else if (file.exists(paste(studyPath[i],'ds.csv',sep='/'))) {
          DSdataCSV <- read.csv(paste(studyPath[i],'ds.csv',sep='/'))
        } else if (file.exists(paste(studyPath[i],'DS.csv',sep='/'))) {
          DSdataCSV <- read.csv(paste(studyPath[i],'DS.csv',sep='/'))
        } else {
          stop('DS Domain Missing!')
        }
        if ('DSSTDY' %in% colnames(DSdataCSV)) {
          DSfields <- c('USUBJID','VISITDY','DSSTDY')
          DSfieldNames <- c('SubjectID','PlannedDay','SacrificeDay')
          DSdataTmp <- subTable(DSfields,DSfieldNames,DSdataCSV)
        } else {
          DSfields <- c('USUBJID','VISITDY')
          DSfieldNames <- c('SubjectID','PlannedDay')
          DSdataTmp <- subTable(DSfields,DSfieldNames,DSdataCSV)
          SacrificeDay <- rep(NA,dim(DSdataTmp)[1])
          DSdataTmp <- cbind(DSdataTmp,SacrificeDay)
        }
        
        ########################################################################################
        
        
        #################### Combine Study Data Sets (if necessary) ############################
        
        if (i == 1) {
          Data <- DataTmp
          metaData <- metaDataTmp
          trialData <- trialDataTmp
          EXdata <- EXdataTmp
          DSdata <- DSdataTmp
        } else {
          Data <- rbind(Data,DataTmp)
          metaData <- rbind(metaData,metaDataTmp)
          trialData <- rbind(trialData,trialDataTmp)
          
          if (length(levels(EXdata$SubjectID)) < 1) {
            if (length(levels(EXdataTmp$SubjectID)) < 1) {
              EXdataSubjectID <- c(EXdata$SubjectID,EXdataTmp$SubjectID)
            } else {
              EXdataSubjectID <- c(EXdata$SubjectID,levels(EXdataTmp$SubjectID)[EXdataTmp$SubjectID])
            }
          } else {
            if (length(levels(EXdataTmp$SubjectID)) < 1) {
              EXdataSubjectID <- c(levels(EXdata$SubjectID)[EXdata$SubjectID],EXdataTmp$SubjectID)
            } else {
              EXdataSubjectID <- c(levels(EXdata$SubjectID)[EXdata$SubjectID],levels(EXdataTmp$SubjectID)[EXdataTmp$SubjectID])
            }
          }
          
          EXdataEndDay <- c(EXdata$EndDay,EXdataTmp$EndDay)
          EXdataStartDay <- c(EXdata$StartDay,EXdataTmp$StartDay)
          EXdata <- cbind(EXdataSubjectID,EXdataEndDay,EXdataStartDay)
          colnames(EXdata) <- c('SubjectID','EndDay','StartDay')
          EXdata <- as.data.frame(EXdata)
          EXdata$EndDay <- as.numeric(as.character(EXdata$EndDay))
          EXdata$StartDay <- as.numeric(as.character(EXdata$StartDay))
          
          if  (length(levels(DSdata$SubjectID)) < 1) {
            if (length(levels(DSdataTmp$SubjectID)) < 1) {
              DSdataSubjectID <- c(DSdata$SubjectID,DSdataTmp$SubjectID)
            } else {
              DSdataSubjectID <- c(DSdata$SubjectID,levels(DSdataTmp$SubjectID)[DSdataTmp$SubjectID])
            }
          } else {
            if (length(levels(DSdataTmp$SubjectID)) < 1) {
              DSdataSubjectID <- c(levels(DSdata$SubjectID)[DSdata$SubjectID],DSdataTmp$SubjectID)
            } else {
              DSdataSubjectID <- c(levels(DSdata$SubjectID)[DSdata$SubjectID],levels(DSdataTmp$SubjectID)[DSdataTmp$SubjectID])
            }
          }
          
          DSdataPlannedDay <- c(DSdata$PlannedDay,DSdataTmp$PlannedDay)
          DSdataSacrificeDay <- c(DSdata$SacrificeDay,DSdataTmp$SacrificeDay)
          DSdata <- cbind(DSdataSubjectID,DSdataPlannedDay,DSdataSacrificeDay)
          colnames(DSdata) <- c('SubjectID','PlannedDay','SacrificeDay')
          DSdata <- as.data.frame(DSdata)
          DSdata$PlannedDay <- as.numeric(as.character(DSdata$PlannedDay))
          DSdata$SacrificeDay <- as.numeric(as.character(DSdata$PlannedDay))
        }
        
        ########################################################################################
        
        
      }
      
      setProgress(message='Processing data...',value=0.33)
      ##########################################################################################
      
      
      ############ Determine Treatment and Recovery Status for Each Subject ####################
      
      Treatment <- NA
      Recovery <- NA
      for (i in seq(dim(metaData)[1])) {
        # Determine Treatment
        indexFields <- c('TXPARMCD','SETCD','StudyID')
        if (length(levels(metaData$TrialSet))>0) {
          setCD <- levels(metaData$TrialSet)[metaData$TrialSet[i]]
        } else {
          setCD <- metaData$TrialSet[i]
        }
        StudyID <- levels(metaData$StudyID)[metaData$StudyID[i]]
        dose <- getFieldValue(trialData,'TXVAL',indexFields,indexValues=c('TRTDOS',setCD,StudyID))
        doseUnit <- getFieldValue(trialData,'TXVAL',indexFields,indexValues=c('TRTDOSU',setCD,StudyID))
        article <- getFieldValue(trialData,'TXVAL',indexFields,indexValues=c('TCNTRL',setCD,StudyID))
        Treatment[i] <- paste(dose,doseUnit,article)
        
        # Determine Recovery Status
        if (length(levels(metaData$SubjectID))<1) {
          subjectID <- metaData$SubjectID[i]
        } else { 
          subjectID <- levels(metaData$SubjectID)[metaData$SubjectID[i]]
        }
        EXindex <- which(EXdata$SubjectID==subjectID)
        if (is.finite(EXdata$StartDay[EXindex][1])) {
          if (is.finite(EXdata$EndDay[EXindex][1])) {
            maxStartDoseDay <- max(EXdata$StartDay[EXindex])
            maxEndDoseDay <- max(EXdata$EndDay[EXindex])
            maxFinalDoseDay <- max(c(maxStartDoseDay,maxEndDoseDay))
          } else {
            maxFinalDoseDay <- max(EXdata$StartDay[EXindex])
          }
        } else {
          maxFinalDoseDay <- max(EXdata$EndDay[EXindex])
        }
        DSindex <- which(DSdata$SubjectID==subjectID)
        DSindexStudySubjects <- metaData$SubjectID[which(metaData$StudyID==StudyID)]
        DSstudyIndex <- which(DSdata$SubjectID %in% DSindexStudySubjects)
        if (is.finite(DSdata$PlannedDay[DSindex])==0) {
          Recovery[i] <- 'Unscheduled'
        } else if (is.finite(DSdata$SacrificeDay[DSindex])) {
          if (DSdata$PlannedDay[DSindex]!=DSdata$SacrificeDay[DSindex]) {
            Recovery[i] <- 'Unscheduled'
          } else if (DSdata$PlannedDay[DSindex]>(maxFinalDoseDay+6)) {
            Recovery[i] <- 'Recovery'
          } else {
            if (DSdata$PlannedDay[DSindex]>(min(DSdata$PlannedDay[DSstudyIndex],na.rm=TRUE)+6)) {
              Recovery[i] <- 'Non-Recovery'
            } else {
              Recovery[i] <- 'Interim'
            }
          }
        } else {
          if (DSdata$PlannedDay[DSindex]>(maxFinalDoseDay+6)) {
            Recovery[i] <- 'Recovery'
          } else {
            if (DSdata$PlannedDay[DSindex]>(min(DSdata$PlannedDay[DSstudyIndex],na.rm=TRUE)+6)) {
              Recovery[i] <- 'Non-Recovery'
            } else {
              Recovery[i] <- 'Interim'
            }
          }
        }
      }
      for (study in unique(metaData$StudyID)) {
        studyIndex <- which(metaData$StudyID == study)
        if (('Non-Recovery' %in% Recovery[studyIndex])==FALSE) {
          interimIndex <- which(Recovery[studyIndex]=='Interim')
          Recovery[studyIndex[interimIndex]] <- 'Non-Recovery'
        }
      }
      metaData <- cbind(metaData,Treatment,Recovery)
      
      ########################################################################################
      
      
      ############### Organize Data for Plotting #############################################
      
      if (input$colorBy=='clinPath') {
        clinPathIndexParam <- which(levels(labData$ShortName)[labData$ShortName]==input$param)
        if (input$includeSeverity==TRUE) {
          NORMALseverity <- min(labData$Value[clinPathIndexParam],na.rm=TRUE)
          SEVEREseverity <- max(labData$Value[clinPathIndexParam],na.rm=TRUE)
          MINIMALseverity <- NORMALseverity+.2*(SEVEREseverity-NORMALseverity)
          MILDseverity <- NORMALseverity+.4*(SEVEREseverity-NORMALseverity)
          MODERATEseverity <- NORMALseverity+.6*(SEVEREseverity-NORMALseverity)
          MARKEDseverity <- NORMALseverity+.8*(SEVEREseverity-NORMALseverity)
        }
      }
      
      # Map Metadata onto Histopath Data
      Sex <- rep(NA,dim(Data)[1])
      Treatment <- Sex
      Recovery <- Sex
      SeverityNumber <- Sex
      SeverityNumber <- NA
      if (input$includeSeverity == TRUE) {
        realSeverityNumber <- SeverityNumber
      }
      for (i in seq(dim(Data)[1])) {
        if (length(levels(Data$SubjectID[i]))<1) {
          index <- which(metaData$SubjectID==Data$SubjectID[i])
        } else{
          index <- which(metaData$SubjectID==levels(Data$SubjectID)[Data$SubjectID[i]])
        }
        if (length(levels(metaData$Sex))>0) {
          Sex[i] <- levels(metaData$Sex)[metaData$Sex[index]]
        } else {
          Sex[i] <- metaData$Sex[index]
        }
        Treatment[i] <- levels(metaData$Treatment)[metaData$Treatment[index]]
        Recovery[i] <- levels(metaData$Recovery)[metaData$Recovery[index]]
        
        if (input$colorBy=='severity') {
          if (is.finite(Data$Severity[i])==FALSE) {
            SeverityNumber[i] <- 0
          } else if (Data$Severity[i]=="MINIMAL") {
            SeverityNumber[i] <- 1
          } else if (Data$Severity[i]=="MILD") {
            SeverityNumber[i] <- 2
          } else if (Data$Severity[i]=="MODERATE") {
            SeverityNumber[i] <- 3
          } else if (Data$Severity[i]=="MARKED") {
            SeverityNumber[i] <- 4
          } else if (Data$Severity[i]=="SEVERE") {
            SeverityNumber[i] <- 5
          } else {
            SeverityNumber[i] <- 0
          }
        } 
        if (input$colorBy=='clinPath') {
          subjectIndex <- which(levels(labData$Subject)[labData$Subject]==levels(Data$Subject)[Data$Subject[i]])
          clinPathIndex <- intersect(subjectIndex,clinPathIndexParam)
          if (length(clinPathIndex) > 0) {
            clinPathIndexMax <- which(labData$Day[clinPathIndex]==max(labData$Day[clinPathIndex]))
            SeverityNumber[i] <- labData$Value[clinPathIndex][clinPathIndexMax]
          } else {
            SeverityNumber[i] <- NA
          }
          if (is.finite(SeverityNumber[i])==0) {
            SeverityNumber[i] <- NA
          }
          if (input$includeSeverity == TRUE) {
            if (is.finite(Data$Severity[i])==FALSE) {
              realSeverityNumber[i] <- NORMALseverity
            } else if (Data$Severity[i]=="MINIMAL") {
              realSeverityNumber[i] <- MINIMALseverity
            } else if (Data$Severity[i]=="MILD") {
              realSeverityNumber[i] <- MILDseverity
            } else if (Data$Severity[i]=="MODERATE") {
              realSeverityNumber[i] <- MODERATEseverity
            } else if (Data$Severity[i]=="MARKED") {
              realSeverityNumber[i] <- MARKEDseverity
            } else if (Data$Severity[i]=="SEVERE") {
              realSeverityNumber[i] <- SEVEREseverity
            } else {
              realSeverityNumber[i] <- NORMALseverity
            }
          } 
        }
      }

      # Add Metadata to Dataset
      if (input$includeSeverity == TRUE) {
        Data <- Data <- cbind(Data,SeverityNumber,Treatment,Sex,Recovery,realSeverityNumber)
      } else {
        Data <- cbind(Data,SeverityNumber,Treatment,Sex,Recovery)
      }
      
      # Filter Out Organs Based on Input Parameters
      severityFlag <- FALSE
      if ((includeNormal == TRUE)|(severityFilter < 0)) {
        for (organ in unique(Data$Organ)) {
          index <- which(Data$Organ==organ)
          notIndex <- which(Data$Organ!=organ)
          if (length(notIndex)==0) {
            severityFlag <- TRUE
            break
          }
          if (includeNormal == TRUE) {
            if ((length(unique(Data$Finding[index]))==1)&(unique(Data$Finding[index])[1]=="NORMAL")) {
              Data <- Data[notIndex,]
            } else if ((max(Data$SeverityNumber[index]) < severityFilter)&(input$colorBy=='severity')) {
              Data <- Data[notIndex,]
            }
          } else if ((max(Data$SeverityNumber[index]) < severityFilter)&(input$colorBy=='severity')) {
            Data <- Data[notIndex,]
          }
        }
      }
      
      # Remove Normal Findings
      if (removeNormal == TRUE) {
        Data <- Data[which(Data$Finding!="NORMAL"),]
      }
      
      # Order Data Logically
      Data <- Data[order(Data$StudyID,Data$Organ,Data$Finding,Data$Treatment),]
      
      # Calculate Incidence Rates and Fold-Change
      Data$Incidence <- NA
      
      if (input$foldChange==TRUE) {
        # Identify Controls
        controlIndex <- NA
        count <- 1
        for (i in seq(length(Data$Treatment))) {
          if (length(grep('[1-9]',Data$Treatment[i]))==0) {
            controlIndex[count] <- i
            count <- count + 1
          }
        }
      }
      
      for (i in seq(length(Data$Incidence))) {
        if ((trackIncidence==TRUE)|(filterControls==TRUE)) {
          studyIndex <- which(Data$StudyID==Data$StudyID[i])
          treatmentIndex <- which(Data$Treatment==Data$Treatment[i])
          index <- intersect(studyIndex,treatmentIndex)
          sexIndex <- which(Data$Sex==Data$Sex[i])
          index <- intersect(index,sexIndex)
          recoveryIndex <- which(Data$Recovery==Data$Recovery[i])
          index <- intersect(index,recoveryIndex)
          organIndex <- which(Data$Organ==Data$Organ[i])
          index <- intersect(index,organIndex)
          incidence <- 1/length(unique(Data$Subject[index]))
          Data$Incidence[i] <- incidence
        }
        if (input$colorBy == 'clinPath') {
          studyIndex <- which(Data$StudyID==Data$StudyID[i])
          sexIndex <- which(Data$Sex==Data$Sex[i])
          index <- intersect(studyIndex,sexIndex)
          if (input$foldChange==TRUE) {
            recoveryIndex <- which(Data$Recovery==Data$Recovery[i])
            index <- intersect(recoveryIndex,index)
            index <- intersect(controlIndex,index)
          }
          group <- unique(Data$Subject[index])
          labIndexS <- which(labData$Subject %in% group)
          labIndexT <- which(labData$ShortName==input$param)
          labIndex <- intersect(labIndexS,labIndexT)
          if (length(labIndex)>0) {
            trueLabIndex <- NA
            for (j in seq(length(unique(labData$Subject[labIndex])))) {
              labSubjectIndex <- which(labData$Subject[labIndex]==unique(labData$Subject[labIndex])[j])
              trueLabIndex[j] <- labIndex[labSubjectIndex[which(labData$Day[labIndex][labSubjectIndex]==max(labData$Day[labIndex][labSubjectIndex]))]]
            }
            labIndex <- trueLabIndex
          }
          groupMean <- mean(labData$Value[labIndex],na.rm=TRUE)
          if ((is.finite(Data$SeverityNumber[i]))&(is.finite(groupMean))) {
            if (input$foldChange==TRUE) {
              foldChange <- Data$SeverityNumber[i]/groupMean
              Data$SeverityNumber[i] <- foldChange
            }
          } else {
            if (input$foldChange==TRUE) {
              Data$SeverityNumber[i] <- 1
            } else {
              Data$SeverityNumber[i] <- groupMean
            }
          }
        }
      }
      if ((input$includeSeverity==TRUE)&(input$foldChange==TRUE)) {
        newNORMALseverity <- min(Data$SeverityNumber)
        newSEVEREseverity <- max(Data$SeverityNumber)
        newMINIMALseverity <- newNORMALseverity+.2*(newSEVEREseverity-newNORMALseverity)
        newMILDseverity <- newNORMALseverity+.4*(newSEVEREseverity-newNORMALseverity)
        newMODERATEseverity <- newNORMALseverity+.6*(newSEVEREseverity-newNORMALseverity)
        newMARKEDseverity <- newNORMALseverity+.8*(newSEVEREseverity-newNORMALseverity)
        for (severity in c('NORMAL','MINIMAL','MILD','MODERATE','MARKED','SEVERE')) {
          severityLevel <- get(paste(severity,'severity',sep=''))
          newSeverityLevel <- get(paste('new',severity,'severity',sep=''))
          for (i in seq(length(Data$realSeverityNumber))) {
            if (Data$realSeverityNumber[i]==severityLevel) {
              Data$realSeverityNumber[i] <- newSeverityLevel
            }
          }
        }
      }
      if (trackIncidence==FALSE) {
        Data$Incidence <- 1
      }
      
      # Filter Out Organs with No Findings of Greater Incidence or Severity than Controls
      if (filterControls==TRUE) {
        for (organ in unique(Data$Organ)) {
          organIndex <- which(Data$Organ==organ)
          organNotIndex <- which(Data$Organ!=organ)
          for (finding in unique(Data$Finding[organIndex])) {
            indexO <- which(Data$Finding[organIndex]==finding)
            index <- organIndex[indexO]
            notIndexO <- which(Data$Finding[organIndex]!=finding)
            notIndex <- sort(c(organNotIndex,organIndex[notIndexO]))
            if (finding=='NORMAL') { 
              Data <- Data[notIndex,]
            } else {
              controlIncidence <- 0
              treatmentIncidence <- 0
              controlSeverity <- 0
              treatmentSeverity <- 0
              for (treatment in unique(Data$Treatment[index])) {
                treatmentIndex <- which(Data$Treatment[index]==treatment)
                if (length(grep('[1-9]',treatment))==0) {
                  controlIncidenceTmp <- sum(Data$Incidence[index][treatmentIndex])
                  controlIncidence <- max(controlIncidenceTmp,controlIncidence)
                  controlSeverityTmp <- min(Data$SeverityNumber[index][treatmentIndex])
                  controlSeverity <- min(controlSeverityTmp,controlSeverity)
                } else {
                  treatmentIncidenceTmp <- sum(Data$Incidence[index][treatmentIndex])
                  treatmentIncidence <- max(treatmentIncidenceTmp,treatmentIncidence)
                  treatmentSeverityTmp <- min(Data$SeverityNumber[index][treatmentIndex])
                  treatmentSeverity <- min(treatmentSeverityTmp,treatmentSeverity)
                }
              }
              if (input$colorBy=='severity') {
                if ((controlIncidence > treatmentIncidence)&(controlSeverity > treatmentSeverity)) {
                  Data <- Data[notIndex,]
                }
              } else if (controlIncidence > treatmentIncidence) {
                Data <- Data[notIndex,]
              }
            }
          }
        }
      }
      
      # Separate Incidence Rates from Study 1 and Study 2
      if (((addStudyCategory == FALSE)&(length(studyIDs) == 2))|input$includeSeverity==TRUE) {
        if ((input$foldChange==TRUE)|(input$colorBy=='severity')) {
          meanSeverity <- 0
        } else {
          meanSeverity <- mean(Data$SeverityNumber,na.rm=TRUE)
        }
        Incidence2 <- Data$Incidence
        if (input$includeSeverity==TRUE) {
          SeverityNumber2 <- Data$realSeverityNumber
        } else {
          SeverityNumber2 <- Data$SeverityNumber
        }
        Data <- cbind(Data,Incidence2,SeverityNumber2)
        if (input$includeSeverity==TRUE) {
          paramDataName <- rep(input$colorBy,dim(Data)[1])
          Data1 <- cbind(Data,paramDataName)
          paramDataName <- rep('severity',dim(Data)[1])
          Data2 <- cbind(Data,paramDataName)
          Data <- rbind(Data1,Data2)
          for (j in seq(length(unique(Data$paramDataName)))) {
            for (i in seq(length(Data$Incidence))) {
              if (Data$paramDataName[i] == input$colorBy) {
                Data$Incidence2[i] <- 10^-10
                Data$SeverityNumber2[i] <- meanSeverity
              } else {
                Data$Incidence[i] <- 10^-10
                Data$SeverityNumber[i] <- meanSeverity
              }
            }
          }
        } else {
          for (j in seq(length(unique(Data$StudyID)))) {
            for (i in seq(length(Data$Incidence))) {
              if (Data$StudyID[i] == Study1Name) {
                Data$Incidence2[i] <- 10^-10
                Data$SeverityNumber2[i] <- meanSeverity
              } else {
                Data$Incidence[i] <- 10^-10
                Data$SeverityNumber[i] <- meanSeverity
              }
            }
          }
        }
        reorderNames <- c(reorderNames[1:2],'Incidence2','SeverityNumber2',reorderNames[3:length(reorderNames)])
        if (trackIncidence==FALSE) {
          incidenceIndex2 <- which(colnames(Data)=="Incidence2")
          colnames(Data)[incidenceIndex2] <- "Counts2"
          reorderNames[3] <- "Counts2"
        }
      }
      
      # Rename Column for Counts
      if (trackIncidence==FALSE) {
        incidenceIndex <- which(colnames(Data)=="Incidence")
        colnames(Data)[incidenceIndex] <- "Counts"
        reorderNames[1] <- "Counts"
      }
      
      # Order Categories
      reorderIndex <- rep(NA,length(reorderNames))
      for (j in seq(reorderNames)) {
        reorderIndex[j] <- which(colnames(Data)==reorderNames[j])
      }
      newData <- Data[,reorderIndex]
      
      # remove studyID from newData
      if (addStudyCategory == FALSE) {
        newData <- newData[,1:(dim(newData)[2]-1)]
      } else if (input$includeSeverity == TRUE) {
        newData <- newData[,1:(dim(newData)[2]-3)]
      }
      
      setProgress(message='Plotting...',value=0.66)
      ########################################################################################
      
      toolName <- 'HistoGraphic'
      
      ############## Write Data to HistoGraphic Excel Template and Display Plot ##############
      
      # NOTE: May need to chunk the writing of data to the Excel template to reduce RAM usage
      
      # Write Data into Excel Template
      if (severityFlag == TRUE) {
        output$text <- renderText({'No findings present with such severity!'})
        setwd(basePath)
      } else {
        if (trackIncidence == TRUE) {
          if (input$colorBy=='severity') {
            quantifiers <- as.data.frame(cbind('Incidence','Severity'))
          } else {
            quantifiers <- as.data.frame(cbind('Incidence',input$param))
          }
        } else {
          if (input$colorBy=='severity') {
            quantifiers <- as.data.frame(cbind('Counts','Severity'))
          } else {
            quantifiers <- as.data.frame(cbind('Counts',input$param))  
          }
        }
        writeWorksheetToFile(outputFilePath,quantifiers,toolName,startRow=5,startCol=1,header=FALSE)
        xlcFreeMemory()
        if (((length(studyIDs) == 2)&(addStudyCategory == FALSE))|(input$includeSeverity==TRUE)) {
          if (input$includeSeverity==TRUE) {
            study1Name <- as.data.frame(input$param)
            study2Name <- as.data.frame('Severity')
          } else {
            study1Name <- as.data.frame(input$study1Name)
            study2Name <- as.data.frame(input$study2Name)
          }
          writeWorksheetToFile(outputFilePath,study1Name,toolName,startRow=4,startCol=1,header=FALSE)
          writeWorksheetToFile(outputFilePath,study2Name,toolName,startRow=4,startCol=3,header=FALSE)
        } else {
          numberData <- newData[,1:2]
          categoryData <- newData[,3:dim(newData)[2]]
          blankData <- cbind(rep('',dim(newData)[1]),rep('',dim(newData)[1]))
          newData <- cbind(numberData,blankData,categoryData)
        }
        write.table(newData,outputCSVPath,col.names=FALSE,row.names=FALSE,sep=',')
        
        # Run Visual Basic Script to Generate Plot via Excel Macro
        shell(shQuote(paste(HistoGraphicPath,'/runHistoGraphic.vbs ',input$webBrowser,sep='')))
        
        setProgress(message='Plotting complete!',value=1)
        # Return to Application Directory
        setwd(basePath)
      }
      ########################################################################################
      
      # Output Text Upon Completion
      for (i in seq(length(studyIDs))) {
        studyNameTmp <- get(paste('Study',i,'Name',sep=''))
        textMessageTmp <- paste('Finished Plotting',studyNameTmp)
        if (i == 1) {
          textMessage <- textMessageTmp
        } else {
          textMessage <- paste(textMessage,textMessageTmp,sep='\n')
        }
      }
      output$text <- renderText(textMessage)
    })
  })
  
  ##########################################################################################
  
  
}

############################################################################################


############################### Define GUI for Application #################################

ui <- fluidPage(
  
  # Application title
  titlePanel("Create HistoGraphic"),
  
  # Create GUI Parameter Options
  fluidRow(
    column(4,
           # Set number of studies
           numericInput('numStudies',label = h3("How many studies would you like to plot? (up to 5)"),value=1),
           
           # Display Error Message if Less than 1 Study Chosen
           conditionalPanel(
             condition = "input.numStudies < 1",
             h3("")
           ),
           
           # Define Study 1 Directory
           conditionalPanel(
             condition = "input.numStudies >= 1 && input.numStudies <= 5",
             h3('Study 1'),
             directoryInput('directory1',label = 'Directory:',value=defaultStudyFolder),
             textInput('study1Name',label='Study 1 Label:',value='Study 1')
           ),
           
           # Define Study 2 Directory
           conditionalPanel(
             condition = "input.numStudies >= 2 && input.numStudies <= 5",
             h3('Study 2'),
             directoryInput('directory2',label = 'Directory:',value=defaultStudyFolder),
             textInput('study2Name',label='Label:',value='Study 2')
           ),
           conditionalPanel(
             condition = "input.numStudies == 2",
             checkboxInput("addStudyCategory","Add Study as a Category?",value=FALSE)
           ),
           
           # Define Study 3 Directory
           conditionalPanel(
             condition = "input.numStudies >= 3 && input.numStudies <= 5",
             h3('Study 3'),
             directoryInput('directory3',label = 'Directory:',value=defaultStudyFolder),
             textInput('study3Name',label='Label:',value='Study 3')
           ),
           
           # Define Study 4 Directory
           conditionalPanel(
             condition = "input.numStudies >= 4 && input.numStudies <= 5",
             h3('Study 4'),
             directoryInput('directory4',label = 'Directory:',value=defaultStudyFolder),
             textInput('study4Name',label='Label:',value='Study 4')
           ),
           
           # Define Study 5 Directory
           conditionalPanel(
             condition = "input.numStudies ==5",
             h3('Study 5'),
             directoryInput('directory5',label = 'Directory:',value=defaultStudyFolder),
             textInput('study5Name',label='Label:',value='Study 5')
           ),
           
           # Display Error Message if Greater than 5 Studies Chose
           conditionalPanel(
             condition = "input.numStudies > 5",
             h3("Cannot choose more than 5 studies!")
           ),
           
           br(),
           
           # Define Web Browser Selection
           selectInput('webBrowser',label='Choose Your Web Browser:',
                       choices = list("Firefox" = 'Firefox',"Google Chrome" = 'Chrome',"Internet Explorer" = 'IE')),
           
           # Define Submit Button
           actionButton("submit","Submit"),br(),br(),
           
           # Define Output Text Box
           verbatimTextOutput("text")
    ),
    column(4,
           # Define Filters
           h3('Filters'),
           checkboxInput("includeNormal",label="Filter Out Organs without Abnormal Findings",value=TRUE),
           checkboxInput("removeNormal",label="Remove Normal Findings",value=FALSE),
           selectInput('severityFilter',label='Filter Out Organs with Findings of Severity Less than:',
                       choices = list(" "=0,"Minimal"=1,"Mild"=2,"Moderate"=3,"Marked"=4,"Severe"=5)),
           checkboxInput("filterControls",label='Filter Out Findings with Equal or Greater Incidence and/or Severity in Controls',value=FALSE),
           
           br(),
           
           h3('Graphical Parameters'),
           # Define Drop Downs for Preset Category Organization
           selectInput("track",label="Report Counts or Incidence Rate?",
                       choices = list("Counts"='counts',"Incidence Rate"='incidence')),
           
           selectInput('colorBy',label="Color by:",choices=list("Severity"='severity',"Clinical Pathology"='clinPath')),
           
           conditionalPanel(
             condition = "input.colorBy == 'clinPath'",
             selectInput('clinPathType',label="Clinical Pathology Subtype:",choices=list("Clinical Chemistry"='CHEMISTRY',
                                                                                         "Hematology"='HEMATOLOGY',
                                                                                         "Urinalysis"='URINALYSIS',
                                                                                         "Coagulation"='COAGULATION'))
           ),
           
           conditionalPanel(
             condition = "input.colorBy == 'clinPath'",
             uiOutput('clinPath'),
             
             ######################### FIX THIS TO Z-SCORE based on CONTROL VALUES !!!!!!!!!!!!!!!!!!!!!!!!!!!!
             ######################### MAYBE FOLD of CONTROL IS MORE CLEAR         !!!!!!!!!!!!!!!!!!!!!!!!!!!!
             
             checkboxInput('foldChange','Fold-Change from Control by Sex within each Study',value=FALSE)
           ),
           
           conditionalPanel(
             condition = "input.colorBy != 'severity' && (input.numStudies != 2 || input.addStudyCategory != false)",
             checkboxInput('includeSeverity','Include Severity?',value=FALSE)
           )
    ),
    column(4,
           h3('Preset Category Organization'),
           selectInput("organizeBy",label="Organize By:",
                       choices = list("Organ"='Organ',"Subject"='Subject',"Custom"='Custom')),
           
           # Define Drop Downs for Custom Category Organization
           h3('Custom Category Organization'),
           conditionalPanel(
             condition = "input.numStudies == 1 || (input.numStudies == 2 && input.addStudyCategory == false)",
             selectInput("layer1",label="Category 1",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer2",label="Category 2",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer3",label="Category 3",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer4",label="Category 4",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer5",label="Category 5",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer6",label="Category 6",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID'))
           ),
           conditionalPanel(
             condition = "input.addStudyCategory == true || input.numStudies > 2",
             selectInput("layer1s",label="Category 1",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer2s",label="Category 2",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer3s",label="Category 3",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer4s",label="Category 4",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer5s",label="Category 5",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer6s",label="Category 6",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer7s",label="Category 7",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID'))
           )
    )
  )
)

############################################################################################


# Run Shiny App
shinyApp(ui = ui, server = server)