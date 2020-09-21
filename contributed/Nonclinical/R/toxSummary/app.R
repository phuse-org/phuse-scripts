
# libraries

library(shiny)
library(ggplot2)
library(stringr)
library(htmltools)
library(shinydashboard)
library(shinycssloaders)
library(tidyverse)
library(ggstance)
library(ggrepel)
library(RColorBrewer)
library(DT)
library(plotly)
library(officer)
library(flextable)
library(magrittr)
library(ggiraph)
library(patchwork)


# Bugs ####


# notes from 07/13/2020

# nonclinical 
#### group findings, rearranging like study option and put right side of Study # done
##### fix finding plot so that dose text readable when there are lot more findings --
##### (text size 4, when more than 6 findings, else textsize 6)

##### add autocompletion for adding findings # done
# make a list for possible findings and provide that list as choices in findings # yousuf
# warning message for save study while required field empty
# save automatically for study 
##### double save button not working properly for savestudy # fixed
# male/female (sex) severity filtered in plot

#clinical
# fix the issue that two start dose appeared 
# dosing units

#table 
# check filter option for numeric column (only slider option available)
# table 2 does not show table sometimes (only shows NOAEL and no absent severity)
# export any appication (whole dataset in rds)



# Notes from 6/29: ################################

# Data Selection:
#### - Change Enter Tox Program to Enter Application Number # done

# - Automatically open new application after entering it rather than having user select from list

# Clinical Data:
# - Set default to check Start Dose and MRHD
# - Fix that need to enter both a Start Dose and MRHD
#### pop up delete button to confirm delete # added by yousuf

#### - Add solid-lines above Start Dose/MRHD/Custom Dose ## Done

# - Wait for feedback on everything above Start Dose Information: in Clinical Data

# Nonclinical Data:
#### - Move study name below Species and Duration  ## Done
#### - Add a save button at bottom of Nonclincial Data 
#### - Add dashed-lines above Dose 2/3/etc., and above Findings 2/3/etc.  ## Done # dashed line above 1/2/3
#### - Move NOAEL checkbox below Cmax and AUC # done
#### - Add solid-lines above number of Dose levels and above number of findings # done
# - Add asterisk next to Dose 1/2/3/etc. ???
#### - Fix typo in "Partially Revesible" # done

# Main Panel:
# - Generate informative error message if safety margin calculation method of Cmax or
#   AUC is selected but no Cmax or AUC clinical (or nonclinical) data has been provided.

# - Wait for feedback on table names

# General Notes:
#### - Fix numericInputs to not take negative values for dose and Cmax and AUC # done, what should be the minimum number? 0?
# - Figure out how to handle data entry in the context of updates to the application'
# - Explore User-based updates

###################################################

# Project Improvement Ideas:
# - Add legend to figure that lists dose compared and PK/HED option
# - Allow user to create display names of findings with legend at bottom
# - Add option to display margin on top of figure
# - Make an optional figure legend (with checkbox)
# - Color "errorbar" to indicate severity (white for no toxicity at dose)
#   Color by the lowest dose on the ladder and switch color half-way between dose edges if space allows
#     on the UI bar side, change checkboxes to selectInputs to indicate dose severity
# - For table export, generate the three tables from the smart template in Word format
# - Add footnotes tied to findings (numbered) as well as a general footnote
# - Start with Smart Template as default table layout
# - Allow table to be flexibly modified
# - Brackets for findings
# - Text wrap finding names so that they don't overlap and use bullets to denote findings
# - Stagger doses (down -> up) so they don't overlap when close
# - use error bar to combine findings across doses

## added by Yousuf


# apply roundSigigs funciton to plotData_p$SM 
# remove findings string from hovertext in findings figure

### need to add or change in 3rd table of template
# correct the HED calculation
# add starting Dose and MHRD 
# add 

# 


'%ni%' <- Negate('%in%')

# # Save configuration of blankData.rds below for later: ####

# Data <- list(
#   INDnumber = NULL,
#   'Clinical Information'= list(
#     HumanWeight = 60,
#     MgKg = F,
#     'Start Dose' = list(
#       StartDose = NULL,
#       StartDoseMgKg = NULL,
#       StartDoseCmax = NULL,
#       StartDoseAUC = NULL
#     ),
#     'MRHD' = list(
#       MRHDDose = NULL,
#       MRHDDoseMgKg = NULL,
#       MRHDCmax = NULL,
#       MRHDAUC = NULL
#     ),
#     'Custom Dose' = list(
#       CustomDose = NULL,
#       CustomDoseMgKg = NULL,
#       CustomDoseCmax = NULL,
#       CustomDoseAUC = NULL
#     )
#   ),
#   'Nonclinical Information' = list(
#     'New Study' = list(
#       Species = NULL,
#       Duration = NULL,
#       Doses = list(
#         Dose = NULL,
#         NOAEL = F,
#         Cmax = NULL,
#         AUC = NULL
#       ),
#       Findings = list(
#         Finding = NULL,
#         Reversibility = F,
#         FindingDoses = NULL
#       )
#     ),
#     'Rat Study' = list(
  #       Species = NULL,
  #       Duration = NULL,
  #       Doses = list(
  #         Dose = NULL,
  #         NOAEL = F,
  #         Cmax = NULL,
  #         AUC = NULL
  #       ),
  #       Findings = list(
  #         Finding = NULL,
  #         Reversibility = F,
  #         FindingDoses = NULL
  #       )
  #     )
#     'Dog Study' = list(
#       Species = NULL,
#       Duration = NULL,
#       Doses = list(
#         Dose = NULL,
#         NOAEL = F,
#         Cmax = NULL,
#         AUC = NULL
#       ),
#       Findings = list(
#         Finding = NULL,
#         Reversibility = F,
#         FindingDoses = NULL
#       )
#     )
#   )
# )
# 
# saveRDS(Data,'blankData.rds')

addUIDep <- function(x) {
  jqueryUIDep <- htmlDependency("jqueryui", "1.10.4", c(href="shared/jqueryui/1.10.4"),
                                script = "jquery-ui.min.js",
                                stylesheet = "jquery-ui.min.css")
  
  attachDependencies(x, c(htmlDependencies(x), list(jqueryUIDep)))
}


values <- reactiveValues()
values$Application <- NULL
values$SM <- NULL
values$selectData <- NULL

# Species Conversion ----

speciesConversion <- c(6.2,1.8,3.1,3.1
                       ,12.3,1.1,4.6,7.4)
names(speciesConversion) <- c('Rat','Dog','Monkey','Rabbit',
                              'Mouse', 'Mini-pig', 'Guinea pig', 'Hamster')

# speciesConversion <- c(6.2,1.8,3.1,3.1)
# names(speciesConversion) <- c('Rat','Dog','Monkey','Rabbit')

clinDosingOptions <- c('Start Dose','MRHD','Custom Dose')


## significant figure

sigfigs <- function(x){
  orig_scipen <- getOption("scipen")
  options(scipen = 999)
  on.exit(options(scipen = orig_scipen))
  
  x <- as.character(x)
  x <- sub("\\.", "", x)
  x <- gsub("(^0+|0+$)", "", x)
  nchar(x)
}

roundSigfigs <- function(x,N=2) {
  if (is.na(x)) {
    return(x)} else {
      roundNumber <- round(x,digits=0)
      if (sigfigs(roundNumber)<=N) {
        roundNumber <- signif(x,digits=N)
      }
      return(roundNumber)
      
    }
}

# create Applications folder if it does not exist
dir.create('Applications',showWarnings = F)

# create ramdom number which will add with folder name
directory_number <- ceiling(runif(1, min = 1, max = 10000))
if (paste0('folder_',directory_number) %in% list.files('Applications')) {
  directory_number <- ceiling(runif(1, min = 1, max = 10000))
  if (paste0('folder_',directory_number) %in% list.files('Applications')) {
    directory_number <- ceiling(runif(1, min = 1, max = 10000))
    if (paste0('folder_',directory_number) %in% list.files('Applications')) {
      directory_number <- ceiling(runif(1, min = 1, max = 10000))
      if (paste0('folder_',directory_number) %in% list.files('Applications')) {
        directory_number <- ceiling(runif(1, min = 1, max = 10000))
      }
    }
  }
}

# get all the file path for Application_Demo.rds
files_rds <- list.files('Applications', pattern = "Application_Demo.rds", recursive = T, full.names = T)

# get current data time
current <- Sys.time()

for ( i in seq(files_rds)) {
  file_dir <- files_rds[[i]]
  last_mod_time <- file.mtime(file_dir)
  differece_days <- ceiling(difftime(current, last_mod_time, units = 'days'))
  
  if (differece_days >= 3 ) {
    dir_delet <- dirname(file_dir)
    unlink(dir_delet, recursive = T)
  }
  
  
}


# Server function started here (selectData) ----

server <- function(input,output,session) {
  
  
  # pop up box for fda email ---- 
  
  # user_name <- modalDialog(
  #   title = "Welcome to toxSummary App",
  #   textInput("user", "Insert FDA Email:"),
  #   easyClose = F,
  #   footer = tagList(
  #     actionButton("run", "Enter")
  #   )
  # )
  # 
  # showModal(user_name)
  # 
  # observeEvent(input$run, {
  #   
  #   req(input$user)
  #   
  #   fda_domain <- unlist(str_split(input$user, '@'))[2]
  #   name <- unlist(str_split(input$user, '@'))[1]
  #  
  #   
  #   if ("fda.hhs.gov" %in% fda_domain & name != "")
  #   {
  #     removeModal()
  #   }
  #   
  #  
  # })
  # 
  
  ## user for pop up box ----
  
  # user <- reactive({
  #   req(input$run)
  #   
  #   name <- isolate(unlist(str_split(input$user, '@'))[1])
  #   name
  # })
  
  
  
  
  #### user folder  ----
  
  user <- reactive({
    # url_search <- session$clientData$url_search
    # username <- unlist(strsplit(url_search,'user='))[2]
    # username <- str_to_lower(username)
    username <- paste0('folder_', directory_number)
    username <- paste0("Applications/", username)
    return(username)
  })
  
  observeEvent(user(), {
    
    dir_list <- list.dirs("Applications", full.names = F, recursive = F)
    if (!basename(user()) %in% dir_list) {
      dir.create(user())
      file.copy("Application_Demo.rds", user())
      
      
    }
    
  })

  output$selectData <- renderUI({
    datasets <- c('blankData.rds',grep('.rds',list.files(user(),full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    names(datasets)[which(datasets=='blankData.rds')] <- 'New Program'
    if (is.null(values$selectData)) {
      selectInput('selectData','Select Develpment Program:',datasets,selected='blankData.rds')
    } else {
      selectInput('selectData','Select Develpment Program:',datasets,selected=values$selectData)
    }
  })
  
  output$studyName <- renderUI({
    req(input$selectData)
    if (input$selectData!='blankData.rds') {
      HTML(paste(
        p(HTML(paste0('<h4>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<u>Selected Program:</u></h4>
                      <h4 style= "color:skyblue"> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
                      (basename(unlist(strsplit(input$selectData,'.rds')))),'</h4>')
        ))
      ))
    }
  })
  
# getData ------
  
  getData <- reactive({
    input$refreshPlot
    req(input$selectData)
    input$selectStudy
    Data <- readRDS(input$selectData)
  })
  
  observe({
    req(input$selectData)
    if (input$selectData == 'blankData.rds') {
      values$Application <- paste0(user(), "/",input$newApplication,'.rds')
    } else {
      values$Application <- input$selectData
    }
  })
  
  observeEvent(input$saveData,{
    Data <- getData()
    saveRDS(Data,values$Application)
    datasets <- c('blankData.rds',grep('.rds',list.files(user(),full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    names(datasets)[which(datasets=='blankData.rds')] <- 'New Program'
    selectInput('selectData','Select Develpment Program:',datasets)
    updateSelectInput(session,'selectData',choices=datasets,selected=values$Application)
  })
  
  
  #observeEvent(input$saveData, {print(list.files(user(), full.names = T))})
  
  # observeEvent(input$deleteData,{
  #   file.remove(values$Application)
  #   datasets <- c('blankData.rds',grep('.rds',list.files('Applications/',full.names = T),value=T))
  #   names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
  #   names(datasets)[which(datasets=='blankData.rds')] <- 'New Application'
  #   selectInput('selectData','Select Application:',datasets)
  #   updateSelectInput(session,'selectData',choices=datasets,selected='blankData.rds')
  # })
  
  
  observeEvent(input$deleteData, {
    showModal(modalDialog(
      title="Delete Program?",
      footer = tagList(modalButton("Cancel"),
                       actionButton("confirmDelete", "Delete")
                       
      )
    ))
  })
  
  
  observeEvent(input$confirmDelete, {

    file.remove(values$Application)
    datasets <- c('blankData.rds',grep('.rds',list.files(user(),full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    names(datasets)[which(datasets=='blankData.rds')] <- 'New Program'
    selectInput('selectData','Select Develpment Program:',datasets)
    updateSelectInput(session,'selectData',choices=datasets,selected='blankData.rds')
    
    removeModal()
  })
  
  
  output$selectStudy <- renderUI({
    req(input$selectData)
    input$selectData
    isolate(Data <- getData())
    studyList <- names(Data[['Nonclinical Information']])
    selectInput('selectStudy','Select Study:',choices=studyList)
  })
  
  # Clinical information -----
  
  observeEvent(input$selectData,ignoreNULL = T,{
    Data <- getData()
    #update units for Cmax/AUC
    updateTextInput(session, "cmax_unit", value=Data[["CmaxUnit"]])
    updateTextInput(session, "auc_unit", value=Data[["AUCUnit"]])
    # update clinical information
    clinData <- Data[['Clinical Information']]
    if (clinData$MgKg==F) {
      updateNumericInput(session,'HumanWeight',value = clinData$HumanWeight)
    } else { updateCheckboxInput(session, "MgKg", value = T)}
    
    
    clinDosing <- NULL
    for (dose in clinDosingOptions) {
      clin_dose <- clinData[[dose]][[gsub(' ','',dose)]]
      clin_dose_mgkg <- clinData[[dose]][[paste0(gsub(' ','',dose), 'MgKg')]]
      if ((!is.null(clin_dose)) | (!is.null(clin_dose_mgkg))) {
        clinDosing <- c(clinDosing,dose)
      }
    }
    updateCheckboxGroupInput(session,'clinDosing',selected=clinDosing)
    
    
    
    for (dose in clinDosing) {
      doseName <- gsub(' ','',dose)
      if (clinData$MgKg==F) {
        updateNumericInput(session,doseName,value = clinData[[dose]][[doseName]])
      } else {
        updateNumericInput(session,paste0(doseName,'MgKg'),value = clinData[[dose]][[paste0(doseName,'MgKg')]])
      }
      updateNumericInput(session,paste0(doseName,'Cmax'),value = clinData[[dose]][[paste0(doseName,'Cmax')]])
      updateNumericInput(session,paste0(doseName,'AUC'),value = clinData[[dose]][[paste0(doseName,'AUC')]])
    }
  })
  
# Nonclinical data update ------
  
  observeEvent(input$selectStudy,ignoreNULL = T,{
    Data <- getData()
    studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
    updateSelectInput(session,'Species',selected=studyData$Species)
    updateTextInput(session,'Duration',value=studyData$Duration)
    updateNumericInput(session,'nDoses',value=studyData$nDoses)
    updateNumericInput(session,'nFindings',value=studyData$nFindings)
    updateCheckboxInput(session, "notes", value = studyData$check_note) 
    # if (studyData$check_note==T) {
    #   updateTextAreaInput(session, "note_text", value = studyData$Notes)
    # }
    #updateTextAreaInput(session, "study_note", value = studyData$Notes)
    #print(studyData$Notes)
    
  })
  
  
  # first save study button ----
  
  observeEvent(eventExpr = input$saveStudy, {
    doseList <- as.list(seq(input$nDoses))
    names(doseList) <- paste0('Dose',seq(input$nDoses))
    for (i in seq(input$nDoses)) {
      doseList[[i]] <- list(Dose=input[[paste0('dose',i)]],
                            NOAEL = input[[paste0('NOAEL',i)]],
                            Cmax = input[[paste0('Cmax',i)]],
                            AUC = input[[paste0('AUC',i)]]
      )
    }
    
    findingList <- as.list(seq(input$nFindings))
    names(findingList) <- paste0('Finding',seq(input$nFindings))
    if (input$nFindings > 0) {
      for (i in seq(input$nFindings)) {
        severity <- list()
        for (j in seq(input$nDoses)) {
        severity[[paste0("Dose", j)]] <- input[[paste0("Severity", i, "_", j)]]
        }
        findingList[[i]] <- list(Finding=input[[paste0('Finding',i)]],
                                 Reversibility = input[[paste0('Reversibility',i)]],
                                 # FindingDoses = input[[paste0('FindingDoses',i)]],
                                 Severity = severity
        )
      }
    } else {
      findingList[[1]] <- NULL
    }
    
    # Severity data update -----
    
    
    
    # studyName and data -----
    
    Data <- getData()
   
    studyName <- paste(input$Species,input$Duration,sep=': ')
    Data[['Nonclinical Information']][[studyName]] <- list(
      Species = input$Species,
      Duration = input$Duration,
      Notes = input$note_text,
      check_note = input$notes,
      nDoses = input$nDoses,
      Doses = doseList,
      nFindings = input$nFindings,
      Findings = findingList
      
    )
    
    saveRDS(Data,values$Application)
    showNotification("Saved", duration = 3)
    
    studyList <- names(Data[['Nonclinical Information']])
    updateSelectInput(session,'selectStudy',choices=studyList,selected=studyName)
    input$refreshPlot
  })
  
  # second save study button ----
  
  observeEvent(eventExpr = input$saveStudy_02, {
    doseList <- as.list(seq(input$nDoses))
    names(doseList) <- paste0('Dose',seq(input$nDoses))
    for (i in seq(input$nDoses)) {
      doseList[[i]] <- list(Dose=input[[paste0('dose',i)]],
                            NOAEL = input[[paste0('NOAEL',i)]],
                            Cmax = input[[paste0('Cmax',i)]],
                            AUC = input[[paste0('AUC',i)]]
      )
    }
    
    findingList <- as.list(seq(input$nFindings))
    names(findingList) <- paste0('Finding',seq(input$nFindings))
    if (input$nFindings > 0) {
      for (i in seq(input$nFindings)) {
        severity <- list()
        for (j in seq(input$nDoses)) {
          severity[[paste0("Dose", j)]] <- input[[paste0("Severity", i, "_", j)]]
        }
        findingList[[i]] <- list(Finding=input[[paste0('Finding',i)]],
                                 Reversibility = input[[paste0('Reversibility',i)]],
                                 # FindingDoses = input[[paste0('FindingDoses',i)]],
                                 Severity = severity
        )
      }
    } else {
      findingList[[1]] <- NULL
    }
    
    # Severity data update -----
    
    
    
    # studyName and data -----
    
    Data <- getData()
    
    studyName <- paste(input$Species,input$Duration,sep=': ')
    Data[['Nonclinical Information']][[studyName]] <- list(
      Species = input$Species,
      Duration = input$Duration,
      Notes = input$note_text,
      check_note = input$notes,
      nDoses = input$nDoses,
      Doses = doseList,
      nFindings = input$nFindings,
      Findings = findingList
    )
    
    saveRDS(Data,values$Application)
    showNotification("Saved", duration = 3)
    
    studyList <- names(Data[['Nonclinical Information']])
    updateSelectInput(session,'selectStudy',choices=studyList,selected=studyName)
    input$refreshPlot
  })
  

  

## save clinical information ---- 
  
  observeEvent(input$saveClinicalInfo, {
    Data <- getData()
    clinData <- Data[['Clinical Information']]
    if (input$MgKg==F) {
      clinData[['HumanWeight']] <- input$HumanWeight
    } else {
      clinData[['HumanWeight']] <- NULL
    }
    clinData[['MgKg']] <- input$MgKg
    if (length(input$clinDosing)>0) {
      for (clinDose in input$clinDosing) {
        clinDoseName <- gsub(' ','',clinDose)
        if (input$MgKg==F) {
          clinData[[clinDose]][[clinDoseName]] <- input[[clinDoseName]]
        } else {
          clinData[[clinDose]][[paste0(clinDoseName,'MgKg')]] <- input[[paste0(clinDoseName,'MgKg')]]
        }
        clinData[[clinDose]][[paste0(clinDoseName,'Cmax')]] <- input[[paste0(clinDoseName,'Cmax')]]
        clinData[[clinDose]][[paste0(clinDoseName,'AUC')]] <- input[[paste0(clinDoseName,'AUC')]]
      }
    }
    Data[['Clinical Information']] <- clinData
    saveRDS(Data,values$Application)
    showNotification("saved", duration = 3)
  })
  
  # 
  # observeEvent(input$deleteStudy,{
  #   Data <- getData()
  #   studyIndex <- which(names(Data[['Nonclinical Information']])==input$selectStudy)
  #   restIndex <- seq(length(names(Data[['Nonclinical Information']])))[-studyIndex]
  #   restNames <- names(Data[['Nonclinical Information']])[restIndex]
  #   Data[['Nonclinical Information']] <- Data[['Nonclinical Information']][restNames]
  #   saveRDS(Data,values$Application)
  #   studyList <- names(Data[['Nonclinical Information']])
  #   updateSelectInput(session,'selectStudy',choices=studyList,selected='New Study')
  # })
  
  
  ## delete study ---- 
  
  observeEvent(input$deleteStudy, {
    showModal(modalDialog(

      title="Delete Study?",
      footer = tagList(modalButton("Cancel"),
                       
                       actionButton("confirmRemove", "Delete")
                       
      )
    ))
  })
  
  
  observeEvent(input$confirmRemove, {
    
    Data <- getData()
    studyIndex <- which(names(Data[['Nonclinical Information']])==input$selectStudy)
    restIndex <- seq(length(names(Data[['Nonclinical Information']])))[-studyIndex]
    restNames <- names(Data[['Nonclinical Information']])[restIndex]
    Data[['Nonclinical Information']] <- Data[['Nonclinical Information']][restNames]
    saveRDS(Data,values$Application)
    studyList <- names(Data[['Nonclinical Information']])
    updateSelectInput(session,'selectStudy',choices=studyList,selected='New Study')
    removeModal()
  })
  
  
  output$studyTitle <- renderText({
    paste(input$Species,input$Duration,sep=': ')
  })
  
  # output$displayStudies ----
  
  output$displayStudies <- renderUI({
    req(input$clinDosing)
    input$selectData
    input$selectStudy
    isolate(Data <- getData())
    studyList <- names(Data[['Nonclinical Information']])
    studyList <- studyList[-which(studyList=='New Study')]
    studyList <- str_sort(studyList, numeric = T)
    addUIDep(selectizeInput('displayStudies',label='Select and Order Studies to Display:',choices=studyList,
                            selected=studyList,
                            multiple=TRUE,width='100%',options=list(plugins=list('drag_drop','remove_button'))))
  })
  
  ## display findings ----
  
  output$displayFindings <- renderUI({
    req(input$clinDosing)
    input$selectData
    input$selectStudy
    data <- getPlotData()
    find_fact <- as.factor(data$Findings)
    findings <- unique(find_fact)
    findings <- str_sort(findings, numeric = T)
    
    addUIDep(selectizeInput('displayFindings', label = 'Select and Order Findings to Display:', choice= findings, selected = findings,
                            multiple = TRUE, width = "100%", options=list(plugins=list('drag_drop','remove_button' ))))
    
  })
  
  ## output$Doses -----
  
  output$Doses <- renderUI({
    req(input$selectStudy)
    cmax_unit <- paste0(" Cmax (", input$cmax_unit, ")")
    auc_unit <- paste0(" AUC (", input$auc_unit, ")")
    if (input$selectStudy=='New Study') {
      lapply(1:(4*input$nDoses), function(i) {
        I <- ceiling(i/4)
        if (i %% 4 == 1) {
          div(
            hr(style = "border-top: 1px dashed skyblue"),
          numericInput(paste0('dose',I),paste0('*Dose ',I,' (mg/kg/day):'), min = 0,NULL))
        } else if (i %% 4 == 2) {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              #numericInput(paste0('Cmax',I),paste0('Dose ',I,' Cmax (ng/mL):'), min = 0, NULL))
              numericInput(paste0('Cmax',I),paste0('Dose ',I, cmax_unit), min = 0, NULL))
        }
        else if (i %% 4 == 3) {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              numericInput(paste0('AUC',I),paste0('Dose ',I, auc_unit),min = 0, NULL))
        } else {
          div(checkboxInput(paste0('NOAEL',I),'NOAEL?',value=F))
        }
      })
    } else {
      Data <- getData()
      studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
      lapply(1:(4*input$nDoses), function(i) {
        I <- ceiling(i/4)
        doseName <- names(studyData$Doses)[I]
        if (i %% 4 == 1) {
          div(hr(style = "border-top: 1px dashed skyblue"),
          numericInput(paste0('dose',I),paste0('*Dose ',I,' (mg/kg/day):'),studyData$Doses[[doseName]][['Dose']]))
        } else if (i %% 4 == 2) {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              numericInput(paste0('Cmax',I),paste0('Dose ',I, cmax_unit),studyData$Doses[[doseName]][['Cmax']]))
        }
        else if (i %% 4 == 3) {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              numericInput(paste0('AUC',I),paste0('Dose ',I, auc_unit),studyData$Doses[[doseName]][['AUC']]))
          
        } else {
         div(checkboxInput(paste0('NOAEL',I),'NOAEL?',value=studyData$Doses[[doseName]][['NOAEL']]))
        }
      })
    }
  })
  
  # findings with severity -----


  
  output$Findings <- renderUI({
    req(input$selectStudy)
 
    
    if (input$selectStudy=='New Study') {
      if (input$nFindings>0) {
        numerator <- 2 + input$nDoses
        lapply(1:(numerator*input$nFindings), function(i) {
          
          
          I <- ceiling(i/numerator)
          if (i %% numerator == 1) {
            
            data <- calculateSM()
            
            find_fact <- as.factor(data$Findings)
            
            findings <- unique(find_fact)
            #print(paste0("findings _______", findings))
          
            
            if (is.null(findings)) {
              
              
            
              div(
                hr(style = "border-top: 1px dashed skyblue"),
                
                #rightnow
                selectizeInput(paste0('Finding',I),paste0('*Finding ',I,':'), choices = findings,
                               options = list(create = TRUE, onInitialize = I('function() { this.setValue(""); }'))))
 
            } else { div(
              hr(style = "border-top: 1px dashed skyblue"),
              
              #rightnow
              selectizeInput(paste0('Finding',I),paste0('*Finding ',I,':'), choices = findings,
                             options = list(create = TRUE, 
                                            onInitialize = I('function() { this.setValue(""); }'))))
              
            }
            
            
            # div(
            #   hr(style = "border-top: 1px dashed skyblue"),
            #   
            #   #rightnow
            # selectizeInput(paste0('Finding',I),paste0('Finding ',I,':')), choices = , options = list(create = TRUE))
            # 
          
            
            
            
            
            } else if (i %% numerator == 2) {
            radioButtons(paste0('Reversibility',I),'Reversibility:',
                         choiceNames=c('Reversible [Rev]','Not Reversible [NR]',
                                       'Partially Reversible [PR]','Not Assessed'),
                         choiceValues=c('[Rev]','[NR]','[PR]',''))
          } else {
            lapply(1:input$nDoses, function(j) {
              if ((i %% numerator == 2+j)|((i %% numerator == 0)&(j==input$nDoses))) {
               selectInput(inputId = paste0('Severity',I,'_',j),label = paste0('Select Severity at Dose ',j,' (',input[[paste0('dose',j)]],' mg/kg/day)'),
                            choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'))
                
              }
            })
          }
        })
      }
    } else {
      Data <- getData()
      studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
      #print(studyData)
      if (input$nFindings>0) {
        numerator <- 2 + input$nDoses
        lapply(1:(numerator*input$nFindings), function(i) {
          I <- ceiling(i/numerator)
          if (i %% numerator == 1) {
            
            data <- calculateSM()
            find_fact <- as.factor(data$Findings)
            findings <- unique(find_fact)
          
            
            div(
              hr(style = "border-top: 1px dashed skyblue"),
              
             
                selectizeInput(paste0('Finding',I),paste0('*Finding ',I,':'), choices= findings,
                               selected = studyData$Findings[[paste0('Finding',I)]]$Finding,
                               options = list(create = TRUE)))
            
              
          } else if (i %% numerator == 2) {
            radioButtons(paste0('Reversibility',I),'Reversibility:',
                         choiceNames=c('Reversible [Rev]','Not Reversible [NR]',
                                       'Partially Reversible [PR]','Not Assessed'),
                         choiceValues=c('[Rev]','[NR]','[PR]',''),
                         selected=studyData$Findings[[paste0('Finding',I)]]$Reversibility)
          } else {
            
            lapply(1:input$nDoses, function(j) {
              if ((i %% numerator == 2+j)|((i %% numerator == 0)&(j==input$nDoses))) {
                
                selectInput(inputId = paste0('Severity',I,'_',j),label = paste0('Select Severity at Dose ',j,' (',input[[paste0('dose',j)]],' mg/kg/day)'),
                            choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'),
                            selected=studyData$Findings[[paste0('Finding',I)]]$Severity[[paste0('Dose',j)]])
                
                
              }
              
              
              
            })
          }
          
        
        })
      }
    }
    
  })
  
  # output$Findings <- renderUI({
  #   req(input$selectStudy)
  #   if (input$selectStudy=='New Study') {
  #     if (input$nFindings>0) {
  #       numerator <- 2 + input$nDoses
  #       lapply(1:(numerator*input$nFindings), function(i) {
  #         I <- ceiling(i/numerator)
  #         if (i %% numerator == 1) {
  #           textInput(paste0('Finding',I),paste0('Finding ',I,':'))
  #         } else if (i %% numerator == 2) {
  #           radioButtons(paste0('Reversibility',I),'Reversibility:',
  #                        choiceNames=c('Reversible [Rev]','Not Reversible [NR]',
  #                                      'Partially Reversible [PR]','Not Assessed'),
  #                        choiceValues=c('[Rev]','[NR]','[PR]',''))
  #         } else {
  #           lapply(1:input$nDoses, function(j) {
  #             if ((i %% numerator == 2+j)|((i %% numerator == 0)&(j==input$nDoses))) {
  #               selectInput(inputId = paste0('Severity',I,'_',j),label = paste0('Select Severity at Dose ',j,' (',input[[paste0('dose',j)]],' mg/kg/day)'),
  #                           choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'))
  #             }
  #           })
  #         }
  #       })
  #     }
  #   } else {
  #     Data <- getData()
  #     studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
  #     if (input$nFindings>0) {
  #       numerator <- 2 + input$nDoses
  #       lapply(1:(3*input$nFindings), function(i) {
  #         I <- ceiling(i/numerator)
  #         if (i %% numerator == 1) {
  #           textInput(paste0('Finding',I),paste0('Finding ',I,':'),
  #                     studyData$Findings[[paste0('Finding',I)]]$Finding)
  #         } else if (i %% numerator == 2) {
  #           radioButtons(paste0('Reversibility',I),'Reversibility:',
  #                        choiceNames=c('Reversible [Rev]','Not Reversible [NR]',
  #                                      'Partially Reversible [PR]','Not Assessed'),
  #                        choiceValues=c('[Rev]','[NR]','[PR]',''),
  #                        selected=studyData$Findings[[paste0('Finding',I)]]$Reversibility)
  #         } else {
  #           lapply(1:input$nDoses, function(j) {
  #             if ((i %% numerator == 2+j)|((i %% numerator == 0)&(j==input$nDoses))) {
  #               selectInput(inputId = paste0('Severity',I,'_',j),label = paste0('Select Severity at Dose ',j,' (',input[[paste0('dose',j)]],' mg/kg/day)'),
  #                           choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'))
  #             }
  #           })
  #         }
  #       })
  #     }
  #   }
  # })
  
  
  ### add note for study ----
  
  output$study_note <- renderUI({
    req(input$selectStudy)
    Data <- getData()
    studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
    
    if (input$selectStudy=='New Study') {
      if (input$notes ==T) {
        textAreaInput("note_text", "Notes:", placeholder = "Enter Note here for this Study", height = "100px")
      }
    } else{
        if (input$notes==T) {
          textAreaInput("note_text", "Notes:", value = studyData$Notes, height = "100px")
        }
      }
      
    
    
    # if (input$notes ==T) {
    #   textAreaInput("note_text", "Notes:", placeholder = "Enter Note here for this Study", height = "100px")
    # }
  })
  
  
  
  # Create PlotData (changed) -----
  

  
 getPlotData <- reactive({
  Data <- getData()
  plotData <- data.frame(matrix(ncol = 17 ))
  column_names <- c("Study", "Dose", 
                    "NOAEL", "Cmax", "AUC", "Findings",
                    "Reversibility", "Severity",  "Value_order", 
                    "SM", "HED_value", "SM_start_dose", "SM_MRHD", "noael_value", "Severity_max", "Severity_num", "Study_note")
  # plotData <- data.frame(matrix(ncol = 21 ))
  # column_names <- c("Study", "Species", "Months", "Dose_num", "Dose", 
  #                   "NOAEL", "Cmax", "AUC", "Findings",
  #                   "Reversibility", "Severity", "Value", "Value_order", 
  #                   "SM", "HED_value", "SM_start_dose", "SM_MRHD", "noael_value", "Severity_max", "Severity_num", "Study_note")
  colnames(plotData) <- column_names
  
  
  count <- 1
  
  for (Study in names(Data[["Nonclinical Information"]])) {
    if (Study != "New Study") {
      studyData <- Data[["Nonclinical Information"]][[Study]]
      
      for (i in seq(studyData$nFindings)){
        for (j in seq(studyData$nDoses)){
          
          plotData[count, "Study"] <- Study
          #plotData[count, "Species"] <- studyData[["Species"]]
          #plotData[count, "Months"] <- studyData[["Duration"]]
          #plotData[count, "Dose_num"] <- names(studyData[["Doses"]][j])
          plotData[count, "Dose"] <- studyData[["Doses"]][[paste0("Dose", j)]][["Dose"]]
          plotData[count, "NOAEL"] <- studyData[["Doses"]][[paste0("Dose",j)]][["NOAEL"]]
          plotData[count, "Cmax"] <- studyData[["Doses"]][[paste0("Dose", j)]][["Cmax"]]
          plotData[count, "AUC"] <- studyData[["Doses"]][[paste0("Dose", j)]][["AUC"]]
          plotData[count, "Findings"] <- studyData[["Findings"]][[paste0("Finding", i)]][["Finding"]]
          plotData[count, "Reversibility"] <- studyData[["Findings"]][[paste0("Finding", i)]][["Reversibility"]]
          plotData[count, "Severity"] <- studyData[["Findings"]][[paste0("Finding", i)]][["Severity"]][[paste0("Dose", j)]]
          #plotData[count, "Value"] <- 1
          plotData[count, "Value_order"] <- j
          plotData[count, "SM"] <- NA
          plotData[count, "HED_value"] <- NA
          plotData[count, "SM_start_dose"] <- NA
          plotData[count, "SM_MRHD"] <- NA
          plotData[count, "noael_value"] <- NA
          plotData[count, "Severity_max"] <- NA
          plotData[count, "Severity_num"] <- NA
          #plotData[count, "Study_note"] <- NA
          
          if (!is.null(studyData[["Notes"]])) {
            plotData[count, "Study_note"] <- studyData[["Notes"]]
            } else {plotData[count, "Study_note"] <- NA}
          
          
          
          count <- count+1
          
          
        }
      }
    }
  }
  
  #plotData$Findings <- tolower(plotData$Findings)
  #plotData$Findings <- str_to_title(plotData$Findings)
  plotData$Rev <- gsub("\\[|\\]", "", plotData$Reversibility)
  #print(plotData$Findings)
  
  #plotData$finding_rev <- paste0(plotData$Findings,"_", plotData$Rev)
  #print(plotData$finding_rev)
  #plotData$find_rev_b <- paste0(plotData$Findings, plotData$Reversibility)
  # plotData$Study <- str_to_lower(plotData$Study)
  # plotData$Study <- str_to_title(plotData$Study)

  #plotData$Findings <- factor(plotData$Findings)
  plotData$Dose <- as.numeric(plotData$Dose)
  plotData$Value <- 1
  
  
  plotData$Rev[plotData$Rev == ""] <- "Not Assessed"
  plotData$Rev[plotData$Rev == "Rev"] <- "Reversible"
  plotData$Rev[plotData$Rev == "NR"] <- "Not Reversible"
  plotData$Rev[plotData$Rev == "PR"] <- "Partially Reversible"
  
  plotData <- plotData[which(plotData$Study %in% input$displayStudies),]
  
  plotData$Severity <- factor(plotData$Severity, 
                              levels= c('Absent','Present','Minimal', 'Mild',
                                        'Moderate', 'Marked', 'Severe'), ordered = TRUE)
  
  plotData$Severity_num <- as.numeric(plotData$Severity)
  
  

  return(plotData)
  
  
})
 
 
    
## human dose ----
  
  output$humanDosing <- renderUI({
    req(input$clinDosing)
    Data <- getData()
    clinDosingNames <- input$clinDosing
    names(clinDosingNames) <- clinDosingNames
    if (length(clinDosingNames)>0) {
      for (clinDose in input$clinDosing) {
        if (Data[['Clinical Information']][['MgKg']]==F) {
          names(clinDosingNames)[which(clinDosingNames==clinDose)] <- paste0(clinDose,
                                                                             ': (', Data[['Clinical Information']][[clinDose]][[paste0(unlist(strsplit(clinDose,' ')),
                                                                                                                                      collapse='')]],' mg)')
        } else {
          names(clinDosingNames)[which(clinDosingNames==clinDose)] <- paste0(clinDose,': (', Data[['Clinical Information']][[clinDose]][[paste0(gsub(' ', '', clinDose), 'MgKg')]],' mg/kg)')
        }
      }
    }
    selectInput('humanDosing','Select Human Dose:',choices=clinDosingNames)
  })
  
  
  
  ##  filter NOAEL data preparation ----
  
  filter_NOAEL <- reactive({
    
    df_plot <- getPlotData()
   
    count <- 0
    for (i in unique(df_plot$Study)){
      
      ind <- which(df_plot$Study == i)
      study <- df_plot[ind,]
      max_severe <- max(study$Severity)
      row_num <- nrow(study)
      
      
      for (j in seq(nrow(study))) {
        if (any(study$NOAEL == TRUE)) {
          dose <- study$Dose[which(study$NOAEL == TRUE)]
          dose <- unique(dose)
          k <- count+j
          df_plot[k, "noael_value"] <- as.numeric(dose)
          df_plot[k, "Severity_max"] <- max_severe
          
        } else {
          dose <- min(study$Dose)
          dose <- as.numeric(dose) - 1
          k <- count + j
          df_plot[k, "noael_value"] <- as.numeric(dose)
          df_plot[k, "Severity_max"] <- max_severe
          
        }
        
        
      }
      
      count <- count +row_num
    }
 
    
    df_plot

  })
  
   #observeEvent(filter_NOAEL(), {print(filter_NOAEL())})
  
  # 
  # for (i in unique(df_plot$Study)){
  #   
  #   ind <- which(df_plot$Study == i)
  #   study <- df_plot[ind,]
  #   row_num <- nrow(study)
  #   
  #   
  #   for (j in seq(nrow(study))) {
  #     
  #     dose <- study$Dose[which(study$NOAEL == TRUE)]
  #     dose <- unique(dose)
  #     k <- count+j
  #     df_plot[k, "noael_value"] <- dose
  #     
  #   }
  #   
  #   count <- count +row_num
  # }
  
  
# ## calculate safety margin (SM) ------
#
  calculateSM <- reactive({
    Data <- getData()
    plotData <- filter_NOAEL()
    # HED_value <- NULL
    # SM <- NULL
    if (nrow(plotData)>0) {
      for (i in seq(nrow(plotData))) {
        if (input$SMbasis=='HED') {
          Dose <- as.numeric(plotData[i,'Dose'])
        } else if (input$SMbasis=='Cmax') {
          Dose <- as.numeric(plotData[i,'Cmax'])
        } else if (input$SMbasis=='AUC') {
          Dose <- as.numeric(plotData[i,'AUC'])
        }
        Species <- unlist(strsplit(plotData[i,'Study'],':'))[1]
        humanDoseName <- gsub(' ','',input$humanDosing)
        # humanDose <- input[[humanDoseName]]
        if (input$SMbasis=='HED') {
          
          HED <- Dose/speciesConversion[[Species]]
          
          
          if (input$MgKg==F) {
            humanDose <- Data[['Clinical Information']][[input$humanDosing]][[humanDoseName]]
            HED <- HED*Data[['Clinical Information']][['HumanWeight']]
                     
            if (!is.null(Data[["Clinical Information"]][["Start Dose"]][["StartDose"]])) {
              SM_start <- HED/(Data[["Clinical Information"]][["Start Dose"]][["StartDose"]])
            } else {SM_start <- NA}
            
            if (!is.null(Data[["Clinical Information"]][["MRHD"]][["MRHD"]])) {
              SM_MRHD <- HED/(Data[["Clinical Information"]][["MRHD"]][["MRHD"]])
              
            } else {SM_MRHD <- NA}
            
            # input$MgKg==T
          }  else {
            
            humanDose <- Data[['Clinical Information']][[input$humanDosing]][[paste0(humanDoseName, "MgKg")]]

             if (!is.null(Data[["Clinical Information"]][["Start Dose"]][["StartDoseMgKg"]])){
               SM_start <- HED/(Data[["Clinical Information"]][["Start Dose"]][["StartDoseMgKg"]])
             } else {SM_start <- NA}
            
             if (!is.null(Data[["Clinical Information"]][["MRHD"]][["MRHDMgKg"]])) {
               SM_MRHD <- HED/(Data[["Clinical Information"]][["MRHD"]][["MRHDMgKg"]])
             } else {SM_MRHD <- NA}
            
          }
          
          
          
          
          
          
          
          # if (!is.null(Data[['Clinical Information']][[input$humanDosing]][[humanDoseName]])) {
          #   humanDose <- Data[['Clinical Information']][[input$humanDosing]][[humanDoseName]]
          # } else {humanDose <- NaN}
          # 
          # 
          # 
          # HED <- Dose/speciesConversion[[Species]]
          # 
          # if (!is.null(Data[["Clinical Information"]][["Start Dose"]][["StartDoseMgKg"]])){
          #   SM_start <- HED/(Data[["Clinical Information"]][["Start Dose"]][["StartDoseMgKg"]])
          # } else {SM_start <- NA}
          # 
          # if (!is.null(Data[["Clinical Information"]][["MRHD"]][["MRHDMgKg"]])) {
          #   SM_MRHD <- HED/(Data[["Clinical Information"]][["MRHD"]][["MRHDMgKg"]])
          # } else {SM_MRHD <- NA}
          # 
          # 
          # 
          # if (input$MgKg==F) {
          #   HED <- HED*Data[['Clinical Information']][['HumanWeight']]
          #   if (!is.null(Data[["Clinical Information"]][["Start Dose"]][["StartDose"]])) {
          #     SM_start <- HED/(Data[["Clinical Information"]][["Start Dose"]][["StartDose"]])
          #   } else {SM_start <- NA}
          # 
          #   if (!is.null(Data[["Clinical Information"]][["MRHD"]][["MRHD"]])) {
          #     SM_MRHD <- HED/(Data[["Clinical Information"]][["MRHD"]][["MRHD"]])
          # 
          #   } else {SM_MRHD <- NA}
          # 
          # }
          
        } else if (input$SMbasis=='Cmax') {
          
          if (!is.null(Data[['Clinical Information']][[input$humanDosing]][[paste0(humanDoseName,input$SMbasis)]])) {
            humanDose <- Data[['Clinical Information']][[input$humanDosing]][[paste0(humanDoseName,input$SMbasis)]]
          } else {humanDose <- NA}
          
          
          
          HED <- Dose
          
          if (!is.null(Data[["Clinical Information"]][["Start Dose"]][["StartDoseCmax"]])) {
            SM_start <- HED/(Data[["Clinical Information"]][["Start Dose"]][["StartDoseCmax"]])
          } else {SM_start <- NA}
          
          if (!is.null(Data[["Clinical Information"]][["MRHD"]][["MRHDCmax"]])) {
            SM_MRHD <- HED/(Data[["Clinical Information"]][["MRHD"]][["MRHDCmax"]])
          } else (SM_MRHD <- NA)
          
          
          
        } else {
          
          if (!is.null(Data[['Clinical Information']][[input$humanDosing]][[paste0(humanDoseName,input$SMbasis)]])) {
            humanDose <- Data[['Clinical Information']][[input$humanDosing]][[paste0(humanDoseName,input$SMbasis)]]
          } else {humanDose <- NA}
          
          HED <- Dose
 
          
          if (!is.null(Data[["Clinical Information"]][["Start Dose"]][["StartDoseAUC"]])) {
            SM_start <- HED/(Data[["Clinical Information"]][["Start Dose"]][["StartDoseAUC"]])
          } else (SM_start <- NA)
          
          if (!is.null(Data[["Clinical Information"]][["MRHD"]][["MRHDAUC"]])) {
            SM_MRHD <- HED/(Data[["Clinical Information"]][["MRHD"]][["MRHDAUC"]])
          } else {SM_MRHD <- NA}
           
          
        }
        
        plotData[i, "HED_value"]<- round(HED, digits = 2) ##for table 03
        plotData[i, "SM"] <- round(HED/humanDose, 2)
        plotData[i, "SM_start_dose"] <- round(SM_start, digits = 2)
        plotData[i, "SM_MRHD"] <- round(SM_MRHD, digits = 2)
      }
    }
    
    
    #plotData <- cbind(plotData,SM, HED_value)
    return(plotData)
    
  })

  
  
  #observeEvent(calculateSM(), {print(str(calculateSM()))})
  ### output table ----
  

  
  dt_01 <- reactive({
    
    plotData_tab <- calculateSM()
    plotData_tab <- plotData_tab %>% 
      mutate(Findings = as.factor(Findings),
             Rev = as.factor(Rev),
             Study = as.factor(Study),
             Dose = as.numeric(Dose),
             SM = as.numeric(SM),
             Severity = as.factor(Severity))
    
    plotData_tab <- plotData_tab %>% 
      select( Findings,Rev, Study, Dose, SM, Severity) %>%
      filter(Severity != "Absent") %>% 
      select(-Severity) %>% 
      #arrange(Findings, Rev) %>% 
      rename(Reversibility = Rev,
             "Clinical Exposure Margin" = SM,
             "Dose (mg/kg/day)" = Dose)
    
    plotData_tab$Findings <- factor(plotData_tab$Findings,levels= input$displayFindings)
    plotData_tab <- plotData_tab %>%
      arrange(Findings)
    plotData_tab
 
  })
  


  

  
  
  
  output$table_01 <- renderDT({
    plotData_tab <- dt_01()
  
    plotData_tab <- datatable(plotData_tab, rownames = FALSE,
                              class = "cell-border stripe",
                              filter = list(position = 'top'),
                              extensions = list("Buttons" = NULL,
                                                "ColReorder" = NULL),
                              caption = htmltools::tags$caption(
                                style = "caption-side: top; text-align: center; font-size: 20px; color: black",
                                "Table :", htmltools::strong("Nonclinical Findings of Potential Clinical Relevance")
                              ),

                              options = list(
                                dom = "lfrtipB",
                                buttons = c("csv", "excel", "copy", "print"),
                                colReorder = TRUE,
                                scrollY = TRUE,
                                pageLength = 25,
                                columnDefs = list(list(className = "dt-center", targets = "_all")),
                                initComplete = JS(
                                  "function(settings, json) {",
                                  "$(this.api().table().header()).css({'background-color': '#000', 'color': '#fff'});",
                                  "}"),

                                rowsGroup = list(0,1,2))) %>%
      formatStyle(columns = colnames(plotData_tab), `font-size` = "18px")
    
    path <- "DT_extension" # folder containing dataTables.rowsGroup.js
    dep <- htmltools::htmlDependency(
      "RowsGroup", "2.0.0",
      path, script = "dataTables.rowsGroup.js")
    plotData_tab$dependencies <- c(plotData_tab$dependencies, list(dep))
    plotData_tab
  })
  
  
  filtered_tab_01 <- reactive({
    req(input$table_01_rows_all)
    data <- dt_01()
    data[input$table_01_rows_all, ]

  })



  dt_to_flex_01 <- reactive({
    plotData_tab <- filtered_tab_01()

    plotData_tab <- plotData_tab %>%

      #select( Findings,Rev, Study, Dose, SM) %>%
      #group_by(Findings, Rev, Study) %>%
      dplyr::arrange(Findings, Reversibility, Study) %>%
      flextable() %>%
      merge_v(j = ~ Findings + Reversibility + Study) %>%

      flextable::autofit() %>%
      add_header_row(values = c("Nonclinical Findings of Potential Clinical Relevance"), colwidths = c(5)) %>%
      #flextable::autofit() %>% 
      theme_box()
    #fontsize(size = 18, part = "all") %>%
    plotData_tab

  })



  #observeEvent(input$down_01_doc, {save_as_docx(dt_to_flex_01(), path = paste0(user(), "/clinical_relevance.docx"))})



  output$down_01_doc <- downloadHandler(
   
    filename = function() {
      Sys.sleep(2)
      paste0("clinical_relevance", ".docx")
    },
    content = function(file) {
      save_as_docx(dt_to_flex_01(), path = paste0(user(), "/clinical_relevance.docx"))
    
      file.copy(paste0(user(),"/clinical_relevance.docx"), file)


    }
  )

  #### table 02 ----
  
  dt_02 <- reactive({
 
    plotData_tab <- calculateSM()
    plotData_tab <- plotData_tab %>% 
      dplyr::select(Study, Dose, NOAEL, Cmax, AUC, SM) %>% 
      #mutate(Study = as.factor(Study)) %>% 
             filter(NOAEL == TRUE) %>% 
             #filter(Severity != "Absent") %>% 
             dplyr::select(-NOAEL) %>%
          #group_by(Findings, Rev, Study) %>%
             dplyr::arrange(Study, Dose)
    
    
    plotdata_finding <- calculateSM()
    
    greater_than_noeal <- plotdata_finding[which(plotdata_finding$Dose>plotdata_finding$noael_value),]
    greater_than_noeal <- greater_than_noeal %>% 
      #filter(Severity_max==Severity_num) %>% 
      select(Study, Findings) %>% 
      distinct() 
      #mutate(Study = as.factor(Study))
    
    cmax_unit <- paste0("Cmax (", input$cmax_unit, ")")
    auc_unit <- paste0("AUC (", input$auc_unit, ")")
    
    
    plotData_tab <- full_join(plotData_tab, greater_than_noeal, by="Study") %>% 
      arrange(Study,Dose,Cmax,AUC,SM,Findings) %>% 
      rename(
        "NOAEL (mg/kg/day)" = Dose,
        #"Cmax (ng/ml)" = Cmax, "AUC (ng*h/ml)" = AUC, 
        "Safety Margin" = SM,
        "Findings at Greater than NOAEL for the Study" = Findings
      ) %>% 
      mutate(Study = as.factor(Study))
    
    names(plotData_tab)[names(plotData_tab)=="Cmax"] <- cmax_unit
    names(plotData_tab)[names(plotData_tab)=="AUC"] <- auc_unit
    
    plotData_tab$Study <- factor(plotData_tab$Study,levels= input$displayStudies)
    plotData_tab <- plotData_tab %>%
      arrange(Study)
      
    
    plotData_tab
    
  })
  
 #observeEvent(dt_02(), {print(dt_02())})
  
# make column name same as flextable (add unit in DT table)
  output$table_02 <- renderDT({
    plotData_tab <- dt_02()
    plotData_tab <- datatable(plotData_tab, rownames = FALSE, class = "cell-border stripe",
                              filter = list(position = 'top'),
                              extensions = list("Buttons" = NULL),
                              caption = htmltools::tags$caption(
                                style = "caption-side: top; text-align: center; font-size: 20px; color: black",
                                "Table :", htmltools::strong("Key Study Findings")
                              ),
                            
                              
                              options = list(
                                scrollY = TRUE,
                                pageLength = 100,
                                dom = "lfrtipB",
                                buttons = c("csv", "excel", "copy", "print"),
                                
                                columnDefs = list(list(className = "dt-center", targets = "_all")),
                                initComplete = JS(
                                  "function(settings, json) {",
                                  "$(this.api().table().header()).css({'background-color': '#000', 'color': '#fff'});",
                                  "}"),
                                rowsGroup = list(0,1,2,3,4,5))) %>%
      formatStyle(columns = colnames(plotData_tab), `font-size` = "18px")
    
    path <- "DT_extension" # folder containing dataTables.rowsGroup.js
    dep <- htmltools::htmlDependency(
      "RowsGroup", "2.0.0", 
      path, script = "dataTables.rowsGroup.js")
    plotData_tab$dependencies <- c(plotData_tab$dependencies, list(dep))
    plotData_tab
  })
  
  
  
  filtered_tab_02 <- reactive({
    req(input$table_02_rows_all)
    data <- dt_02()
    data[input$table_02_rows_all, ]
    
  })
  
  
  dt_to_flex_02 <- reactive({
    
    cmax_unit <- paste0("Cmax (", input$cmax_unit, ")")
    auc_unit <- paste0("AUC (", input$auc_unit, ")")
    
    plotData_tab <- filtered_tab_02()
    plotData_tab <- plotData_tab %>% 
      rename(
         "Dose" ="NOAEL (mg/kg/day)",
         #"Cmax" = "Cmax (ng/ml)",
         #"AUC" = "AUC (ng*h/ml)", 
         "SM"= "Safety Margin",
         "Findings" = "Findings at Greater than NOAEL for the Study"
      )
    
    colnames(plotData_tab)[3] <- "Cmax"
    colnames(plotData_tab)[4] <- "AUC"
    
    plotData_tab <- plotData_tab %>%
      flextable() %>% 
          merge_v(j = ~ Study + Dose + Cmax+ AUC +SM+Findings) %>%
          flextable::autofit() %>% 
      
          set_header_labels("Dose" = "NOAEL (mg/kg/day)",
                        "Cmax" = cmax_unit,
                        "AUC" = auc_unit,
                        "Findings" = "Findings at Greater than NOAEL for the Study",
                        "SM" = "Safety Margin") %>% 
      add_header_row(values = c("Key Study Findings"), colwidths = c(6)) %>%
          theme_box()
    plotData_tab
    
  })
  
  
  
  #observeEvent(dt_to_flex_02(), {save_as_docx(dt_to_flex_02(), path = paste0(user(), "/key_findings.docx"))})
  
  
  
  output$down_02_doc <- downloadHandler(
    filename = function() {
      paste0("key_findings", ".docx")
    },
    content = function(file) {
      save_as_docx(dt_to_flex_02(), path = paste0(user(), "/key_findings.docx"))
      file.copy(paste0(user(), "/key_findings.docx"), file)
      
      
    }
  )
  
  
  
  
  
  ## table 03 ----
  
  dt_03 <- reactive({
    
    cmax_unit <- paste0("Cmax (", input$cmax_unit, ")")
    auc_unit <- paste0("AUC (", input$auc_unit, ")")
    plotData_03 <- calculateSM()
    plotData_03 <- plotData_03 %>% 
      select( Study,NOAEL, Dose, SM , HED_value, Cmax, AUC , SM_start_dose, SM_MRHD) %>% 
      mutate(Study = as.factor(Study)) %>% 
      unique() %>% 
      filter(NOAEL == TRUE) %>% 
      select(-NOAEL) %>% 
      dplyr::rename("NOAEL (mg/kg/day)" = Dose,
                     #"Cmax (ng/ml)" = Cmax, "AUC (ng*h/ml)" = AUC, 
                     #cmax_unit = Cmax, auc_unit = AUC,
                    
                     "Safety Margin" = SM,
                     "Safety Margin at Starting Dose" = SM_start_dose,
                     "Safety Margin at MRHD" = SM_MRHD)
  
    names(plotData_03)[names(plotData_03)=="Cmax"] <- cmax_unit
    names(plotData_03)[names(plotData_03)=="AUC"] <- auc_unit
    
    
    if (input$MgKg==F) {
      plotData_03 <- plotData_03 %>% 
        rename("HED (mg/day)" = HED_value)
    } else {plotData_03 <- plotData_03 %>% 
      rename("HED (mg/kg/day)" = HED_value)
    }
    
    plotData_03$Study <- factor(plotData_03$Study,levels= input$displayStudies)
    plotData_03 <- plotData_03 %>%
      arrange(Study)
      #dplyr::mutate('Starting Dose' = NA, MRHD = NA) # have to change
    plotData_03
    
  })
  
  output$table_03 <- renderDT({
    plotData_03 <- dt_03()
    plotData_03 <- datatable(plotData_03,rownames = FALSE, 
                             extensions = list("Buttons" = NULL,
                                               "ColReorder" = NULL), 
                          
                             
                             class = "cell-border stripe",
                             filter = list(position = 'top'),
                             caption = htmltools::tags$caption(
                               style = "caption-side: top; text-align: center; font-size: 20px; color: black",
                               "Table :", htmltools::strong("Safety Margins Based on NOAEL from Pivotal Toxicology Studies")
                             ),
                             options = list(
                               
                               #autoWidth = TRUE,
                               #columnDefs = list(list(width = "150px", targets = "_all")),
                               dom = "lfrtipB",
                               buttons = c("csv", "excel", "copy", "print"),
                               colReorder = TRUE,
                               pageLength = 10,
                               columnDefs = list(list(className = "dt-center", targets = "_all")),
                               
                               scrollY = TRUE,
                               initComplete = JS(
                                 "function(settings, json) {",
                                 "$(this.api().table().header()).css({'background-color': '#000', 'color': '#fff'});",
                                 "}"))) %>% 
      formatStyle(columns = colnames(plotData_03), `font-size` = "18px")

    plotData_03
  })
  
  
  filtered_tab_03 <- reactive({
    req(input$table_03_rows_all)
    data <- dt_03()
    data[input$table_03_rows_all, ]
    
  })
  
  
  dt_to_flex_03 <- reactive({
    plotData_tab <- filtered_tab_03() %>% 
      flextable() %>%
      add_header_row(values = c("Nonclinical", "Clinical Safety Margins"), colwidths = c(6,2)) %>%
      add_header_row(values = c("Safety Margins Based on NOAEL from Pivotal Toxicology Studies"), colwidths = c(8)) %>%
      theme_box()
    
    plotData_tab
    
    
  })
  
  
  
  #observeEvent(dt_to_flex_03(), {save_as_docx(dt_to_flex_03(), path = paste0(user(), "/safety_margin.docx") )})

  
  output$down_03_doc <- downloadHandler(
    filename = function() {
      paste0("safety_margin", ".docx")
    },
    content = function(file) {
      save_as_docx(dt_to_flex_03(), path = paste0(user(), "/safety_margin.docx") )
      file.copy(paste0(user(), "/safety_margin.docx"), file)
      
      
    }
  )
  
  
  ## download all table 
  
  
  
   download_all <- reactive({
     doc <- read_docx()
     doc_02 <-  body_add_flextable(doc, dt_to_flex_01()) %>%
       body_add_par("   ") %>%
       body_add_par("   ") %>%
       body_add_par("   ") %>%
       body_add_flextable( dt_to_flex_02()) %>%
       body_add_par("   ") %>%
       body_add_par("   ") %>%
       body_add_par("   ") %>%
       body_add_flextable(dt_to_flex_03())

     doc_02
   })

 #observeEvent(download_all(), {print(download_all() , target = paste0(user(), "/table_all.docx"))})



   output$down_all <- downloadHandler(
     filename = function() {
       paste0("table_all", ".docx")
     },
     content = function(file) {
       print(download_all() , target = paste0(user(), "/table_all.docx"))
       file.copy(paste0(user(), "/table_all.docx"), file)


     }
   )
  
  # craete notes table ----
   
   all_study_notes <- reactive({
     plotData_tab <- calculateSM()
     plotData_tab <- plotData_tab %>% 
       dplyr::select(Study_note, Study) %>% 
       dplyr::rename(Notes = Study_note)
     plotData_tab$Study <- factor(plotData_tab$Study,levels= input$displayStudies)
     plotData_tab <- plotData_tab %>% 
       distinct() %>% 
       arrange(Study)
     
     
     plotData_tab
   })
   
 
   # output table for notes  ----
   
   output$table_note <- renderTable({all_study_notes()},  
                             bordered = TRUE,
                             striped = TRUE,
                             spacing = 'xs',  
                             width = '100%', align = 'lr')
   
 
   ## download notes table
   table_note_to_flex <- reactive({
     note_table <- all_study_notes() %>% 
       flextable() %>%
       add_header_row(values = c("Note for Studies"), colwidths = c(2)) %>%
       theme_box()
     
     note_table
     
     
   })
   
   
   
   #observeEvent(table_note_to_flex(), {save_as_docx(table_note_to_flex(), path = paste0(user(), "/note_table.docx") )})
   
   
   output$down_notes <- downloadHandler(
     filename = function() {
       paste0("note_table", ".docx")
     },
     content = function(file) {
       save_as_docx(table_note_to_flex(), path = paste0(user(), "/note_table.docx"))
       file.copy(paste0(user(), "/note_table.docx"), file)
       
       
     }
   )
   
   
   
 #### plotheight ----

  # plotHeight <- function() {
  #   plotData <- calculateSM()
  #   nStudies <- length(unique(plotData$Study))
  #   if (nStudies < 2){
  #     plotHeight <- as.numeric(8*nStudies)
  #   } else {
  #     plotHeight <- as.numeric(5*nStudies)
  #     }
  # }
  
  # y_limit <- function() {
  #   y_axis <- calculateSM()
  #   y_max <-as.numeric(max(y_axis$Value_order))
  #   y_min <- as.numeric(min(y_axis$Value_order))
  #   
  # }

   

## filter NOAEL reactive ----
   
  filtered_plot <- reactive({
    if (input$NOAEL_choices == "ALL") {
      plot_data <- calculateSM()
    } else if (input$NOAEL_choices == "Less than or equal to NOAEL") {
        
        plot_data <- calculateSM()
        plot_data <- plot_data %>% 
          dplyr::filter(Dose <= noael_value)
 } else {
   plot_data <- calculateSM()
   plot_data <- plot_data %>% 
     dplyr::filter(Dose > noael_value)
    }
    
    plot_data
  })

   
  # plotheight ----
   
   plotHeight <- reactive({
     plotData <- calculateSM()
     nStudies <- length(unique(plotData$Study))
     plot_height <- (input$plotheight) * (nStudies)
     plot_height
   })
  
   
   
  ## figure -----
  
  output$figure <- renderGirafe({
    
    req(input$clinDosing)
    input$selectData
    
    plotData <- filtered_plot()
    plotData <- plotData[which(plotData$Findings %in% input$displayFindings),]
    plotData$Dose <- as.numeric(plotData$Dose)
    axis_limit <- calculateSM()
    suppressWarnings(SM_max <- max(axis_limit$SM))
    suppressWarnings(y_max <- as.numeric(max(axis_limit$Value_order)) +1)
    suppressWarnings(q_y_max <- as.numeric(max(axis_limit$Value_order)))
    finding_count <- length(unique(plotData$Findings))
      
      
      if (finding_count < 4) {
        q_col_width <- 0.2* finding_count
      } else {
        q_col_width <- 0.9
      }
      # q_col_width <- 0.9
      
      
      
      # text size of finding plot
      
      if (finding_count < 6) {
        q_text_size <- 6
      } else {
        q_text_size <- 4
      }
      
    ## plotdata for p plot (changed) ----
    plotData_p <- plotData
  
    plotData_p <- plotData_p %>% 
      select(Study, Dose, SM, Value, NOAEL, Value_order, Study_note) %>% 
      #group_by(Study, Dose, SM) %>% 
      unique()
    plotData_p$SM <- lapply(plotData_p$SM, roundSigfigs)
    plotData_p$SM <- as.numeric(plotData_p$SM)
    
    #note 
    plotData_note <- plotData_p %>% 
      select(Study, Study_note, SM, Value_order) %>% 
      filter(Value_order==1) %>% 
      unique()
      
    
    if (nrow(plotData)>0) {
      plotData$Study <- factor(plotData$Study,levels= input$displayStudies)
      plotData_p$Study <- factor(plotData_p$Study,levels= input$displayStudies)
      plotData$Findings <- factor(plotData$Findings, levels = input$displayFindings)
      plotData$DoseLabel <- factor(paste(plotData$Dose,'mg/kg/day'),levels=unique(paste(plotData$Dose,'mg/kg/day'))[order(unique(as.numeric(plotData$Dose),decreasing=F))])
      maxFindings <- 1
      for (doseFinding in plotData$doseFindings) {
        nFindings <- str_count(doseFinding,'\n')
        if (nFindings > maxFindings) {
          maxFindings <- nFindings
        }
      }
      maxFindings <- maxFindings + 1

      #plotData$Findings <- as.factor(plotData$Findings)
      plotData$Severity <- as.factor(plotData$Severity)
      
      
      # make severity ordered factor
      plotData$Severity <- factor(plotData$Severity, 
                                  levels= c('Absent','Present','Minimal', 'Mild',
                                            'Moderate', 'Marked', 'Severe'), ordered = TRUE)
    
      #color_manual <- c('transparent','grey','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#b10026')
      color_manual <- c('Absent' = 'transparent',
                        'Present' = 'grey',
                        'Minimal' = '#feb24c',
                        'Mild' = '#fd8d3c',
                        'Moderate' = '#fc4e2a',
                        'Marked' = '#e31a1c',
                        'Severe' = '#b10026')

# # safety margin plot ----
      color_NOAEL <- c("TRUE" = "#239B56", "FALSE" = "black")
      
      tooltip_css <- "background-color:#3DE3D8;color:black;padding:2px;border-radius:5px;"
      
      
      if (input$dose_sm==1) {
        
          plot_p_label <- ggplot(plotData_p)+
          geom_label_interactive(aes(x = SM, y = Value_order,
                                     label = paste0(Dose, " mg/kg/day"),
                                     
                                     tooltip =paste0("SM: ", SM, "x")), #DoseLabel changed
                                 color = "white",
                                 fontface = "bold",
                                 size = 6,
                                 fill= ifelse(plotData_p$NOAEL == TRUE, "#239B56", "black"),
                                 label.padding = unit(0.6, "lines")
          )
          
      } else if (input$dose_sm==2) {
        plot_p_label <- ggplot(plotData_p)+
          geom_label_interactive(aes(x = SM, y = Value_order,
                                     label = paste0(Dose, " mg/kg/day", "\n", SM, "x"),
                                     #label= ifelse(input$dose_sm==1, paste0(Dose, " mg/kg/day"), paste0(Dose, " mg/kg/day", "_", SM, "x")),
                                     tooltip =paste0(Study_note)), #DoseLabel changed
                                 color = "white",
                                 fontface = "bold",
                                 size = 6,
                                 fill= ifelse(plotData_p$NOAEL == TRUE, "#239B56", "black"),
                                 label.padding = unit(0.6, "lines"))
        
      } else {
        plot_p_label <- ggplot(plotData_p)+
          geom_label_interactive(aes(x = SM, y = Value_order,
                                     label = paste0(Dose, " mg/kg/day", "\n", SM, "x"),
                                     #label= ifelse(input$dose_sm==1, paste0(Dose, " mg/kg/day"), paste0(Dose, " mg/kg/day", "_", SM, "x")),
                                     tooltip =paste0(Study_note)), #DoseLabel changed
                                 color = "white",
                                 fontface = "bold",
                                 size = 6,
                                 fill= ifelse(plotData_p$NOAEL == TRUE, "#239B56", "black"),
                                 label.padding = unit(0.6, "lines")
          )+
        
          geom_text(data=plotData_note ,aes(x = 0.5*(SM_max), y=0.3 , label= Study_note),
                    color = "black",
                    size= 6)
      }
      
      p <- plot_p_label +
        scale_x_log10(limits = c(min(axis_limit$SM/2), max(axis_limit$SM*2)))+
        #scale_fill_manual(values = color_NOAEL)+
        ylim(0,y_max)+
        facet_grid( Study ~ .)+
        labs( title = "      Summary of Toxicology Studies", x = "Exposure Margin")+
        theme_bw(base_size=12)+
        theme(
          axis.title.y = element_blank(),
              axis.ticks.y= element_blank(),
              axis.text.y = element_blank(),
           
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              plot.title = element_text(size= 20, hjust = 1),
              
              axis.title.x = element_text(size = 18, vjust = -0.9),
              axis.text.x = element_text(size = 16),
              legend.position = "none",
              strip.text.y = element_text(size=14, color="black"),
              strip.background = element_rect( fill = "white"))
      
# findings plot ----
      
      q <- ggplot(plotData)+
        geom_col_interactive(aes(x= Findings, y = Value, fill = Severity, group = Dose,  tooltip = Findings),
                 position = position_stack(reverse = TRUE),
                 color = 'transparent',
                 width = q_col_width)+
        geom_text_interactive(aes(x = Findings, y = Value, label = Dose, group = Dose,  tooltip = Findings),
                  size = q_text_size,
                  color = 'white',
                  fontface = 'bold',
                  position = position_stack(vjust = 0.5, reverse = TRUE))+
        #scale_y_discrete(position = 'right')+
        ylim(0, q_y_max)+
        scale_fill_manual(values = color_manual)+
        facet_grid(Study ~ ., scales = 'free')+
        theme_bw(base_size=12)+
        theme(axis.title.y = element_blank(),
              strip.text.y = element_blank(),
              axis.ticks.y = element_blank(),
              axis.text.y  = element_blank(),
              axis.title.x = element_blank(),
              axis.text.x  = element_text(size= 16, angle = 90), #need to work
              #plot.title = element_text(size=20,hjust = 0.5),
              panel.grid.major.y = element_blank(),
              panel.grid.minor.y = element_blank(),
              panel.grid.major.x = element_line(),
              panel.grid.minor.x = element_blank(),
              legend.text  = element_text(size = 14),
              legend.title = element_text(size = 16),
              legend.justification = "top")+
        #labs(title = '' )+
        guides(fill = guide_legend(override.aes = aes(label = "")))

      girafe(code = print(p+q+plot_layout(ncol = 2, widths = c(3,1))),
             options = list(opts_tooltip(css = tooltip_css)),
             fonts = list(sans= "Roboto"),
             width_svg = 18, height_svg = plotHeight())
      
      #q <- girafe(ggobj = q)
      # p + q + plot_layout(ncol=2,widths=c(3,1))
      
      #ggplotly(p, tooltip = "x")
      
      # p <- ggplotly(p, tooltip = c("text","text"), height = plotHeight()) %>% 
      #   plotly::style(showlegend = FALSE)
      # q <- ggplotly(q, tooltip = "text",  height = plotHeight()) #show warning though
      # 
      # subplot(p, q, nrows = 1, widths = c(0.7, 0.3), titleX = TRUE, titleY = TRUE) %>% 
      #   layout(title= "Summary of Toxicology Studies",
      #          xaxis = list(title = "Safety Margin"), 
      #          xaxis2 = list(title = ""))
      
    }
  })

  observe({
    req(input$selectData)
    values$selectData <- input$selectData
  })
  
  
  ## download rds file

  
  output$download_rds <- renderUI({
    
    datasets <- c(grep('.rds',list.files(user(),full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    selectInput("downloadRDS", "Select to Download Program Data:", choices = datasets, selected = NULL)
    
  })
  

  #observeEvent(input$downloadRDS, {print(input$upload_rds$datapath)})
  
  
  output$down_btn <- downloadHandler(
    filename = function() {
      
      app_name <- basename(input$downloadRDS)
      app_name
    },
    content = function(file) {
      file.copy(input$downloadRDS, file)
    }
  )
  
  ## upload file rds
  
  observe({
    if (is.null(input$upload_rds)) return()
    file.copy(input$upload_rds$datapath,   paste0(user(), "/",  input$upload_rds$name))
    datasets <- c('blankData.rds',grep('.rds',list.files(user(),full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    names(datasets)[which(datasets=='blankData.rds')] <- 'New Program'
    selectInput('selectData','Select Develpment Program:',datasets)
    updateSelectInput(session,'selectData',choices=datasets,selected=values$Application)
  })
  
  
  # download tar file ----



  # user_name <- modalDialog(
  #   title = "Welcome to toxSummary App",
  #   textInput("user", "Insert FDA Email:"),
  #   easyClose = F,
  #   footer = tagList(
  #     actionButton("run", "Enter")
  #   )
  # )
  # 
  # showModal(user_name)
  # 
  # observeEvent(input$run, {
  # 
  #   req(input$user)
  # 
  #   fda_domain <- unlist(str_split(input$user, '@'))[2]
  #   name <- unlist(str_split(input$user, '@'))[1]
  # 
  # 
  #   if ("fda.hhs.gov" %in% fda_domain & name != "")
  #   {
  #     removeModal()
  #   }
  # })
  # 
  # get_name <- reactive({
  #   req(input$run)
  # 
  #   name <- isolate(unlist(str_split(input$user, '@'))[1])
  #   name
  # })
  
  # observeEvent(input$deleteData, {
  #   showModal(modalDialog(
  #     title="Delete Application?",
  #     footer = tagList(modalButton("Cancel"),
  #                      actionButton("confirmDelete", "Delete")
  #                      
  #     )
  #   ))
  # })
  
  
  
  
  
  
  
  output$tar_file <- downloadHandler(
    filename = function() {
      "all_file.tar"
    },
    content = function(file) {
      all_file <- tar("all_file.tar", files = "Applications")
      file.copy("all_file.tar", file)
    }
  )
  
  dir_to_df <- reactive({
    
    df_files <- data.frame(matrix(ncol = 2))
    colnames(df_files) <- c("user", "files")
    
    folder_list <- basename(list.dirs("Applications/"))
    folder_list <- tail(folder_list, -1)
    
    count <- 1
    
    for (folder in folder_list) {
      
        file_list <- grep(".rds", list.files(paste0("Applications/", folder)), value = T)
        for (file in file_list) {
          df_files[count, "user"] <- folder
          file <- unlist(strsplit(file, ".rds"))
          df_files[count, "files"] <- file
          count <- count+1
        }
    }
    
    df_files <- df_files %>% 
      arrange(user, files)
    df_files
    
  })
  
  
  
  
  
  
  output$dir_list <- renderDT({
    dir_tab <- dir_to_df()
    dir_tab <- datatable(dir_tab, rownames = FALSE, class = "cell-border stripe",
                              filter = list(position = 'top'),
                              extensions = list("Buttons" = NULL),
                              caption = htmltools::tags$caption(
                                style = "caption-side: top; text-align: center; font-size: 20px; color: black",
                                "Table :", htmltools::strong("All the RDS Files")
                              ),
                              
                              
                              options = list(
                                scrollY = TRUE,
                                pageLength = 100,
                                dom = "lfrtipB",
                                buttons = c("csv", "excel", "copy", "print"),
                                
                                columnDefs = list(list(className = "dt-center", targets = "_all")),
                                initComplete = JS(
                                  "function(settings, json) {",
                                  "$(this.api().table().header()).css({'background-color': '#000', 'color': '#fff'});",
                                  "}"),
                                rowsGroup = list(0))) %>%
      formatStyle(columns = colnames(dir_tab), `font-size` = "18px")
    
    path <- "DT_extension" # folder containing dataTables.rowsGroup.js
    dep <- htmltools::htmlDependency(
      "RowsGroup", "2.0.0", 
      path, script = "dataTables.rowsGroup.js")
    dir_tab$dependencies <- c(dir_tab$dependencies, list(dep))
    dir_tab
  })
  
  
  ## save units for Cmax and AUC ----
  
  # get_unit_cmax <- reactive({
  #   input$save_units
  #  
  #   Data <- getData()
  #   cmax <- Data[["CmaxUnit"]]
  #   cmax
  #   
  # })
  
  observeEvent(input$save_units, {
    Data <- getData()
    Data[["CmaxUnit"]] <- input$cmax_unit
    Data[["AUCUnit"]] <- input$auc_unit
    saveRDS(Data,values$Application)
    showNotification("saved", duration = 3)
  })
  
  five_space <- paste0(HTML('&nbsp;'), HTML('&nbsp;'), HTML('&nbsp;'),
                       HTML('&nbsp;'), HTML('&nbsp;'))
  ## start dose cmax and auc untis
  output$start_cmax <- renderUI({
    cmax <- paste0("Start Dose Cmax ", "(", input$cmax_unit, "):")
    HTML(paste0(five_space, strong(cmax)))
  })
  
  output$start_auc <- renderUI({
    auc <- paste0("Start Dose AUC ", "(", input$auc_unit, "):")
    HTML(paste0(five_space, strong(auc)))
  })
  
 ## MRHD dose cmax and auc unit
  output$MRHD_cmax <- renderUI({
    cmax <- paste0("MRHD Dose Cmax ", "(", input$cmax_unit, "):")
    HTML(paste0(five_space, strong(cmax)))
  })
  
  output$MRHD_auc <- renderUI({
    auc <- paste0("MRHD Dose AUC ", "(", input$auc_unit, "):")
    HTML(paste0(five_space, strong(auc)))
  })
  
  ## custom dose 
  output$custom_cmax <- renderUI({
    cmax <- paste0("Custom Dose Cmax ", "(", input$cmax_unit, "):")
    HTML(paste0(five_space, strong(cmax)))
  })
  
  output$custom_auc <- renderUI({
    auc <- paste0("Custom Dose AUC ", "(", input$auc_unit, "):")
    HTML(paste0(five_space, strong(auc)))
  })
  
  
  
  
   
  # output$menu function -----
  
  output$menu <- renderMenu({

    if (!is.null(input$selectData)) {
      if (input$selectData=='blankData.rds') {
        sidebarMenu(id='menu',
                    menuItem('Data Selection',icon=icon('database'),startExpanded = T,
                             uiOutput('selectData'),
                             conditionalPanel('input.selectData=="blankData.rds"',
                                              textInput('newApplication','Enter Program Name:')
                             ),
                             actionButton('saveData','Open New Program',icon=icon('plus-circle')),
                             br()
                    ),
                    # br(),
                    # uiOutput('studyName'),
                    # br(),
                    # br(),
                    hr(),
                    menuItem('Source Code',icon=icon('code'),href='https://github.com/phuse-org/phuse-scripts/blob/master/contributed/Nonclinical/R/toxSummary/app.R')
        )
      } else {
        # Data <- getData()
        # cmax <- Data[["CmaxUnit"]]
        
        sidebarMenu(id='menu',
                    menuItem('Data Selection',icon=icon('database'),startExpanded = T,
                             uiOutput('selectData'),
                             conditionalPanel('input.selectData=="blankData.rds"',
                                              textInput('newApplication','Enter Program Name:')
                             ),
                             actionButton('deleteData','Delete',icon=icon('minus-circle')),
                             br()
                    ),
                    hr(),
                    uiOutput('studyName'),
                    hr(),
                    menuItem("Units for Cmax/AUC", icon = icon("balance-scale"),
                             textInput("cmax_unit", "*Insert Unit for Cmax:", value = "ng/mL"),
                             textInput("auc_unit", "*Insert Unit for AUC:", value = "ng*h/mL"),
                             actionButton('save_units','Save Units',icon=icon('plus-circle')),
                             br()),
                    
                    
                    menuItem('Clinical Data',icon=icon('user'),
                             checkboxGroupInput('clinDosing','Clinical Dosing:',clinDosingOptions),
                             conditionalPanel('condition=input.MgKg==false',
                                              numericInput('HumanWeight','*Human Weight (kg):',value=60)
                             ),
                             checkboxInput('MgKg','Dosing in mg/kg?',value=F),
                             conditionalPanel(
                               condition='input.clinDosing.includes("Start Dose")',
                               hr(),
                               # hr line         
                               
                               #tags$hr(style="height:3px;border-width:0;color:white;background-color:green"),
                               
                               h4('Start Dose Information:'),
                               conditionalPanel(condition='input.MgKg==true',
                                                numericInput('StartDoseMgKg','*Start Dose (mg/kg/day):',value=NULL,min=0)
                               ),
                               conditionalPanel(condition='input.MgKg==false',
                                                numericInput('StartDose','*Start Dose (mg/day):',value = NULL, min=0)
                               ),
                               uiOutput("start_cmax"),
                               numericInput('StartDoseCmax',NULL,value=NULL, min=0),
                               #numericInput('StartDoseCmax',paste0('Start Dose Cmax ', input$cmax_unit),value=NULL, min=0),
                               uiOutput("start_auc"),
                               numericInput('StartDoseAUC',NULL,value=NULL, min=0)
                             ),
                             conditionalPanel(
                               condition='input.clinDosing.includes("MRHD")',
                               hr(),
                               #tags$hr(style="height:3px;border-width:0;color:white;background-color:skyblue"),
                               
                               h4('MRHD Information:'),
                               conditionalPanel(condition='input.MgKg==true',
                                                numericInput('MRHDMgKg','*MRHD (mg/kg):',value=NULL, min=0)
                               ),
                               conditionalPanel(condition='input.MgKg==false',
                                                numericInput('MRHD','*MRHD (mg):',value = NULL, min=0)
                               ),
                               uiOutput("MRHD_cmax"),
                               numericInput('MRHDCmax',NULL,value=NULL, min=0),
                               uiOutput("MRHD_auc"),
                               numericInput('MRHDAUC',NULL,value=NULL, min=0)
                             ),
                             conditionalPanel(
                               condition='input.clinDosing.includes("Custom Dose")',
                               
                               
                               hr(),
                               #tags$hr(style="height:3px;border-width:0;color:white;background-color:white"),
                               
                               h4('Custom Dose Information:'),
                               conditionalPanel(condition='input.MgKg==true',
                                                numericInput('CustomDoseMgKg','*Custom Dose (mg/kg):',value=NULL, min=0)
                               ),
                               conditionalPanel(condition='input.MgKg==false',
                                                numericInput('CustomDose','*Custom Dose (mg):',value = NULL, min=0)
                               ),
                               uiOutput("custom_cmax"),
                               numericInput('CustomDoseCmax',NULL,value=NULL, min=0),
                               uiOutput("custom_auc"),
                               numericInput('CustomDoseAUC',NULL,value=NULL, min=0)
                             ),
                             actionButton('saveClinicalInfo','Save Clinical Information',icon=icon('plus-circle')),
                             br()
                    ),                   
                    menuItem('Nonclinical Data',icon=icon('flask'),tabName = 'Nonclinical Info',
                             uiOutput('selectStudy'),
                             actionButton('saveStudy','Save Study',icon=icon('plus-circle')),
                             actionButton('deleteStudy','Delete Study',icon=icon('minus-circle')),
                             
                             
                             
                             selectInput('Species','*Select Species:',choices=names(speciesConversion)),
                             textInput('Duration','*Study Duration/Description:'),
                             
                             h4('Study Name:'),
                             verbatimTextOutput('studyTitle'),
                             
                             hr(),
                             #tags$hr(style="height:3px;border-width:0;color:white;background-color:green"),
                             
                             numericInput('nDoses','*Number of Dose Levels:',value=3,step=1,min=1),
                             
                             uiOutput('Doses'),
                             
                             hr(),
                             #tags$hr(style="height:3px;border-width:0;color:white;background-color:green"),
                             
                             numericInput('nFindings','*Number of Findings:',value=1,step=1,min=1),
                             
                             uiOutput('Findings'),
                             #br(),
                             checkboxInput("notes", "Notes for Study?", value = FALSE),
                             uiOutput("study_note"),
                             actionButton('saveStudy_02','Save Study',icon=icon('plus-circle'))
                    ),
                    hr(),
                    h6('* Indicates Required Fields'),
                    hr(),
                    menuItem('Source Code',icon=icon('code'),href='https://github.com/phuse-org/phuse-scripts/blob/master/contributed/Nonclinical/R/toxSummary/toxSummary.R')
        )
      }
    } else {
      sidebarMenu(id='menu',
                  menuItem('Data Selection',icon=icon('database'),startExpanded = T,
                           uiOutput('selectData'),
                           conditionalPanel('input.selectData=="blankData.rds"',
                                            textInput('newApplication','Enter Program Name:')
                           ),
                           actionButton('saveData','Open New Program',icon=icon('plus-circle')),
                           br()
                  ),
                  # br(),
                  # uiOutput('studyName'),
                  # br(),
                  # br(),
                  hr(),
                  menuItem('Source Code',icon=icon('code'),href='https://github.com/phuse-org/phuse-scripts/blob/master/contributed/Nonclinical/R/toxSummary/toxSummary.R')
      )
    }
  })
  
  output$renderFigure <- renderUI({
    withSpinner(girafeOutput('figure',width='100%',height=paste0(100*plotHeight(),'px')))
  })
}


# ui function ------
ui <- dashboardPage(
  
  

  dashboardHeader(title="Nonclinical Summary Tool",titleWidth = 250),
 

  
  
  dashboardSidebar(width = 250,
                   sidebarMenuOutput('menu'),
                   tags$head(
                     tags$style(
                       HTML(".sidebar {height: 94vh; overflow-y: auto;}")
                     )
                   )
                   
  ),
  
  
  
  dashboardBody(
    

    # tags$head(
    #   tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
    # ),

    fluidRow(
      column(2,
             uiOutput('humanDosing')
      ),
      column(2,
             conditionalPanel(
               'input.clinDosing != null && input.clinDosing != ""',
               selectInput('SMbasis','Base Exposure Margin on:',c('HED','Cmax','AUC'))
             )
      ),
      column(4,
             uiOutput('displayStudies')
      ),
      
      column(4, 
             uiOutput('displayFindings'))
    ),
    conditionalPanel(
      condition='input.selectData!="blankData.rds" && input.clinDosing != null && input.clinDosing != ""',
      tabsetPanel(
        
        
        tabPanel('Figure',
                 
                 
               
                
                 fluidRow(
                   
                   column(2,
                          actionButton('refreshPlot','Refresh Plot')),
                  column(3, 
                         selectInput("NOAEL_choices", "Filter NOAEL:", choices = c("ALL", "Less than or equal to NOAEL", "Greater than NOAEL"),
                             selected = "ALL")),
                  column(3, 
                         radioButtons("dose_sm", "Display Units:", choices = list("Show Dose Only"=1,
                                                                           "Show Dose with SM"= 2,
                                                                           "Notes" =3))),
                  column(3, 
                         sliderInput("plotheight", "Adjust Plot Height:", min = 1, max = 15, value = 4))),
                 br(),
                 # <<<<<<< HEAD
                 # withSpinner(girafeOutput('figure')),
                 uiOutput('renderFigure'),
                 br(),
                 hr(style = "border-top: 1px dashed black"),
                 fluidRow(
                   column(9,
                          tableOutput("table_note"),
                          h4("Click on button below to export the table in a docx file"),
                          downloadButton("down_notes", "Docx file download")))),
        # =======
        #                  # withSpinner(girafeOutput('figure'))),
        #                  uiOutput('renderFigure')
        #                  ),
        # >>>>>>> shinyappsIO
        
        
  
        
      tabPanel("Clinical Relevance Table",
               DT::dataTableOutput('table_01'),
               br(),
               hr(style = "border-top: 1px dashed black"),
               h4("Click on button below to export the table in a docx file"),
               downloadButton("down_01_doc", "Docx file download"),
               br()
      ),
      tabPanel("Key Findings Table",
               DT::dataTableOutput('table_02'),
               br(),
               hr(style = "border-top: 1px dashed black"),
               h4("Click on button below to export the table in a docx file"),
               downloadButton("down_02_doc", "Docx file download"),
               br()
               
               
      ),
      
      tabPanel("Safety Margin Table",
               DT::dataTableOutput('table_03'),
               br(),
               hr(style = "border-top: 1px dashed black"),
               h4("Click on button below to export the table in a docx file"),
               downloadButton("down_03_doc", "Docx file download"),
               br()
               
      ),
      
    
      
      tabPanel("All Tables", 
               br(),
               p("All three table can be downloaded in single docx file. Click button below to download."),
               downloadButton("down_all", "Docx file download")),
      
      tabPanel("Download Program Data",
               br(),
               h4("Download Program Data in RDS format:"),
               br(),
               p("Program Data can be downloaded in RDS format to share with others"),
               
               uiOutput("download_rds"),
               downloadButton("down_btn", "Download Program Data"),
               br(),
               hr(style = "border-top: 1px dashed black"),
               
               h4("Upload Program Data in RDS format:"),
               fileInput("upload_rds", "Upload", accept = c(".rds"), multiple = F))
  ))))



# app running function ----

shinyApp(ui = ui, server = server)
