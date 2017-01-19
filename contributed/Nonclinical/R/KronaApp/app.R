library(shiny)
library(XLConnect)
library(rChoiceDialogs)

source('directoryInput.R')
source('Functions.R')

# Default Study Folder
defaultStudyFolder <- path.expand('~')

server <- function(input, output,session) {
  # Handle choosing the App directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$studyfolder
    },
    handlerExpr = {
      if (input$studyfolder > 0) {
        path = rchoose.dir(default = readDirectoryInput(session,'studyfolder'))
        updateDirectoryInput(session,'studyfolder',value = path)
        updateDirectoryInput(session,'directory1',value = path)
        updateDirectoryInput(session,'directory2',value = path)
      }
    }
  )
  
  # Handle choosing Study 1 directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory1
    },
    handlerExpr = {
      if (input$directory1 == 1) {
        path = rchoose.dir(default = defaultStudyFolder)
        updateDirectoryInput(session, 'directory1', value = path)
      } else if (input$directory1 > 1) {
        path = rchoose.dir(default = readDirectoryInput(session, 'directory1'))
        updateDirectoryInput(session, 'directory1', value = path)
      }
    }
  )
  
  # Handle choosing Study 2 directory
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory2
    },
    handlerExpr = {
      if (input$directory2 == 1) {
        path = rchoose.dir(default = defaultStudyFolder)
        updateDirectoryInput(session, 'directory2', value = path)
      } else if (input$directory2 > 1) {
        path = rchoose.dir(default = readDirectoryInput(session, 'directory1'))
        updateDirectoryInput(session, 'directory2', value = path)
      }
    }
  )
  
  # Create Krona plot from SEND data when Submit button is clicked
  createKronaPlot <- observeEvent(input$submit,{
    # Set working directory
    WD <- readDirectoryInput(session,'studyfolder')
    setwd(WD)

    # Read in user-defined parameters
    path1 <- readDirectoryInput(session,'directory1')
    path2 <- readDirectoryInput(session,'directory2')
    organizeBy <- input$organizeBy
    includeNormal <- input$includeNormal
    
    # Set studyIDs
    if (input$directory2 > 0) {
      studyIDs <- c(path1,path2)
    } else {
      studyIDs <- path1
    }
    
    # Parameters not to change (for now...)
    filterOutput <- FALSE # NOTE: Proper filtering routine has not yet been implemented
    
    # Set Order of Rings and Implement Incidence or Count Decision
    if (organizeBy == 'Organ') {
      trackIncidence <- TRUE
      reorderNames <- c("Incidence","SeverityNumber","Organ","Recovery","Finding","Treatment","Sex","SubjectID","StudyID")
    } else if (organizeBy == 'Subject') {
      trackIncidence <- FALSE
      reorderNames <- c("Incidence","SeverityNumber","Recovery","Treatment","Sex","SubjectID","Organ","Finding","StudyID")
    } else if (organizeBy == 'Custom') {
      if (input$track == 'incidence') {
        trackIncidence <- TRUE
      } else if (input$track == 'counts') {
        trackIncidence <- FALSE
      }
      reorderNames <- c("Incidence","SeverityNumber",input$layer1,input$layer2,input$layer3,input$layer4,input$layer5,input$layer6,"StudyID")
    }
    updateSelectInput(session,'layer1',selected=reorderNames[3])
    updateSelectInput(session,'layer2',selected=reorderNames[4])
    updateSelectInput(session,'layer3',selected=reorderNames[5])
    updateSelectInput(session,'layer4',selected=reorderNames[6])
    updateSelectInput(session,'layer5',selected=reorderNames[7])
    updateSelectInput(session,'layer6',selected=reorderNames[8])
    
    # Set File Paths for Studies
    basePath <- WD
    studyPath <- NA
    for (i in seq(length(studyIDs))) {
      studyPath[i] <- studyIDs[i]
    }
    
    # Move to Krona Directory
    kronaPath <- paste(basePath,'Krona',sep='/')
    if (dir.exists(kronaPath)==FALSE) {dir.create(kronaPath)}
    setwd(kronaPath)
    
#    # Set Excel File Path
    outputFilePath <- 'temp/template.xlsm'
    
    # Create Empty Template File
    file.copy("Krona2-4.xlsm",outputFilePath,overwrite = TRUE)
    
    # Generate Data Tables from SEND
    for (i in seq(length(studyPath))) {
      # Get Histopath Data from MI Domain
      histoData <- read.csv(paste(studyPath[i],'MI.csv',sep='/'))
      histoFields <- c('STUDYID','USUBJID','MISTRESC','MISPEC','MISEV')
      histoNames <- c('StudyID','SubjectID','Finding','Organ','Severity')
      DataTmp <- subTable(histoFields,histoNames,histoData)
      DataTmp <- DataTmp[which(DataTmp$Finding!=""),]
      
      # Get Metadata from DM and TX Domains
      demData <- read.csv(paste(studyPath[i],'DM.csv',sep='/'))
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
      
      txData <- read.csv(paste(studyPath[i],'TX.csv',sep='/'))
      trialFields <- c('SET','TXVAL','TXPARMCD','SETCD')
      trialFieldNames <- trialFields
      trialDataTmp <- subTable(trialFields,trialFieldNames,txData)
      StudyID <- rep(DataTmp$StudyID[1],dim(trialDataTmp)[1])
      trialDataTmp <- cbind(trialDataTmp,StudyID)
      
      EXdataCSV <- read.csv(paste(studyPath[i],'EX.csv',sep='/'))
      if ('EXSTDY' %in% colnames(EXdataCSV)) {
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
      
      DSdataCSV <- read.csv(paste(studyPath[i],'DS.csv',sep='/'))
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
        
        if (is.numeric(EXdata$SubjectID[1])) {
          if (is.numeric(EXdataTmp$SubjectID[1])) {
            EXdataSubjectID <- c(EXdata$SubjectID,EXdataTmp$SubjectID)
          } else {
            EXdataSubjectID <- c(EXdata$SubjectID,levels(EXdataTmp$SubjectID)[EXdataTmp$SubjectID])
          }
        } else {
          if (is.numeric(EXdataTmp$SubjectID[1])) {
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
        
        if (is.numeric(DSdata$SubjectID[1])) {
          if (is.numeric(DSdataTmp$SubjectID[1])) {
            DSdataSubjectID <- c(DSdata$SubjectID,DSdataTmp$SubjectID)
          } else {
            DSdataSubjectID <- c(DSdata$SubjectID,levels(DSdataTmp$SubjectID)[DSdataTmp$SubjectID])
          }
        } else {
          if (is.numeric(DSdataTmp$SubjectID[1])) {
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
    }
    
    # Determine Treatment and Recovery Status for Each Subject
    Treatment <- NA
    Recovery <- NA
    for (i in seq(dim(metaData)[1])) {
      indexFields <- c('TXPARMCD','SETCD','StudyID')
      if (length(levels(metaData$TrialSet))>0) {
        setCD <- levels(metaData$TrialSet)[metaData$TrialSet[i]]
      } else {
        setCD <- metaData$TrialSet[i]
      }
      StudyID <- levels(metaData$StudyID)[metaData$StudyID[i]]
      dose <- getFieldValue(trialData,'TXVAL',indexFields,indexValues=c('TRTDOS',setCD,StudyID))
      doseUnit <- getFieldValue(trialData,'TXVAL',indexFields,indexValues=c('TRTDOSU',setCD,StudyID))
      Treatment[i] <- paste(dose,doseUnit)
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
      if (is.finite(DSdata$PlannedDay[DSindex])==0) {
        Recovery[i] <- 'Unscheduled'
      } else if (is.finite(DSdata$SacrificeDay[DSindex])) {
        if (DSdata$PlannedDay[DSindex]!=DSdata$SacrificeDay[DSindex]) {
          Recovery[i] <- 'Unscheduled'
        } else if (DSdata$PlannedDay[DSindex]>(maxFinalDoseDay+6)) {
          Recovery[i] <- 'Recovery'
        } else {
          Recovery[i] <- 'No Recovery'
        }
      } else {
        if (DSdata$PlannedDay[DSindex]>(maxFinalDoseDay+6)) {
          Recovery[i] <- 'Recovery'
        } else {
          Recovery[i] <- 'No Recovery'
        }
      }
    }
    metaData <- cbind(metaData,Treatment,Recovery)
    
    # Map Metadata onto Histopath Data
    Sex <- rep(NA,dim(Data)[1])
    Treatment <- Sex
    Recovery <- Sex
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
    }
    
    # Initialize Severity Number Score Field
    SeverityNumber <- Treatment
    SeverityNumber <- NA
    
    # Add Metadata to Dataset
    Data <- cbind(Data,SeverityNumber,Treatment,Sex,Recovery)
    
    # Remove Organs with No Abnormal Findings
    if (includeNormal == TRUE) {
      for (organ in unique(Data$Organ)) {
        index <- which(Data$Organ==organ)
        notIndex <- which(Data$Organ!=organ)
        if ((length(unique(Data$Finding[index]))==1)&(unique(Data$Finding[index])[1]=="NORMAL")) {
          Data <- Data[notIndex,]
        }
      }
    } else {
      Data <- Data[which(Data$Finding!="NORMAL"),]
    }
    
    # Order Data Logically
    Data <- Data[order(Data$StudyID,Data$Organ,Data$Finding,Data$Treatment),]
    
    # Convert Severity Scores into Numbers
    for (i in seq(length(Data$Severity))) {
      if (is.finite(Data$Severity[i])==FALSE) {
        Data$SeverityNumber[i] <- 0
      } else if (Data$Severity[i]=="MINIMAL") {
        Data$SeverityNumber[i] <- -1
      } else if (Data$Severity[i]=="MILD") {
        Data$SeverityNumber[i] <- -2
      } else if (Data$Severity[i]=="MODERATE") {
        Data$SeverityNumber[i] <- -3
      } else if (Data$Severity[i]=="MARKED") {
        Data$SeverityNumber[i] <- -4
      } else if (Data$Severity[i]=="SEVERE") {
        Data$SeverityNumber[i] <- -5
      } else {
        Data$SeverityNumber[i] <- 0
      }
    }
    
    # Calculate Incidence Rates for Study 1
    Data$Incidence <- NA
    for (i in seq(length(Data$Incidence))) {
      treatmentIndex <- which(Data$Treatment==Data$Treatment[i])
      sexIndex <- which(Data$Sex==Data$Sex[i])
      index <- intersect(treatmentIndex,sexIndex)
      recoveryIndex <- which(Data$Recovery==Data$Recovery[i])
      index <- intersect(index,recoveryIndex)
      if (trackIncidence==TRUE) {
        organIndex <- which(Data$Organ==Data$Organ[i])
        index <- intersect(index,organIndex)
        incidence <- 1/length(unique(Data$Subject[index]))
      } else {
        incidence <- 1
      }
      Data$Incidence[i] <- incidence
    }
    
    # Calculate Incidence Rates for Study 2
    if (length(studyIDs) == 2) {
      Incidence2 <- Data$Incidence
      SeverityNumber2 <- Data$SeverityNumber
      Data <- cbind(Data,Incidence2,SeverityNumber2)
      for (j in seq(length(unique(Data$StudyID)))) {
        for (i in seq(length(Data$Incidence))) {
          if (Data$StudyID[i] == unique(Data$StudyID)[1]) {
            Data$Incidence2[i] <- 10^-10
            Data$SeverityNumber2[i] <- 0
          } else {
            Data$Incidence[i] <- 10^-10
            Data$SeverityNumber[i] <- 0
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
    
    # Calculate Counts
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
    newData <- newData[,1:(dim(newData)[2]-1)]
    
    # Write Data into Excel Template
    if (length(studyIDs) == 2) {
      writeWorksheetToFile(outputFilePath,newData,"Krona",startRow=6,startCol=1,header=FALSE)
      study1Name <- as.data.frame(input$study1Name)
      writeWorksheetToFile(outputFilePath,study1Name,"Krona",startRow=4,startCol=1,header=FALSE)
      study2Name <- as.data.frame(input$study2Name)
      writeWorksheetToFile(outputFilePath,study2Name,"Krona",startRow=4,startCol=3,header=FALSE)
    } else {
      numberData <- newData[,1:2]
      categoryData <- newData[,3:dim(newData)[2]]
      writeWorksheetToFile(outputFilePath,numberData,"Krona",startRow=6,header=FALSE)
      writeWorksheetToFile(outputFilePath,categoryData,"Krona",startRow=6,startCol=5,header=FALSE)
    }
    quantifiers <- as.data.frame(cbind(colnames(newData)[1],'Severity'))
    writeWorksheetToFile(outputFilePath,quantifiers,"Krona",startRow=5,startCol=1,header=FALSE)
    
    print(getwd())
    
    shell(shQuote(paste(kronaPath,'runKrona.vbs',sep='/')))

    output$text <- renderText({paste('Finished Running Analysis of',basename(studyIDs),'\n')})
  })
}


# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Create Krona Plot"),
  
  # Sidebar with a slider input for parameters
  fluidRow(
    column(4,
           h3('Study 1'),
           directoryInput('directory1',label = 'Directory:',value=defaultStudyFolder),
           textInput('study1Name',label='Study 1 Label:',value='Study 1'),br(),
           h3('Study 2 (optional)'),
           directoryInput('directory2',label = 'Directory:',value=defaultStudyFolder),
           textInput('study2Name',label='Label:',value='Study 2'),br(),
           h3('Filters'),
           checkboxInput("includeNormal",label="Include Normal Findings?",value=TRUE),
           checkboxInput("includeUnscheduled",label='Separate Unscheduled Deaths? (broken)',value=TRUE),
           checkboxInput("filterControl",label='Filter Out Control Findings? (broken)',value=FALSE),
           selectInput('severityFilter',label='Filter Severity Less than: (broken)',
                       choices = list(" "='blank',"Minimal"='minimal',"Mild"='mild',"Moderate"='moderate',"Marked"='marked',"Severe"='severe')),br(),
           actionButton("submit","Submit")
    ),
    column(4,
           h3('Preset Category Organization'),
           selectInput("organizeBy",label="Organize By:",
                       choices = list("Organ"='Organ',"Subject"='Subject',"Custom"='Custom')),
           h3('Custom Category Organization'),
           selectInput("layer1",label="Category 1",
                       choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"SubjectID"='SubjectID')),
           selectInput("layer2",label="Category 2",
                       choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"SubjectID"='SubjectID')),
           selectInput("layer3",label="Category 3",
                       choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"SubjectID"='SubjectID')),
           selectInput("layer4",label="Category 4",
                       choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"SubjectID"='SubjectID')),
           selectInput("layer5",label="Category 5",
                       choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"SubjectID"='SubjectID')),
           selectInput("layer6",label="Category 6",
                       choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"SubjectID"='SubjectID')),
           selectInput("track",label="Report Incidence or Counts?",
                       choices = list("Incidence"='incidence',"Counts"='counts'))
    ),
    column(4,
           directoryInput('studyfolder',label = 'Change App Folder',value=defaultStudyFolder),br(),
           verbatimTextOutput("text"))
  )
)

shinyApp(ui = ui, server = server)