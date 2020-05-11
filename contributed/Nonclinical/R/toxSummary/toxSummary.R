library(shiny)
library(ggplot2)
library(stringr)
library(htmltools)
library(shinydashboard)

# Bugs:

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


'%ni%' <- Negate('%in%')

# Save configuration of blankData.rds below for later:

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

speciesConversion <- c(6.2,1.8,3.1,3.1)
names(speciesConversion) <- c('Rat','Dog','Monkey','Rabbit')

clinDosingOptions <- c('Start Dose','MRHD','Custom Dose')

server <- function(input,output,session) {
  
  output$selectData <- renderUI({
    datasets <- c('blankData.rds',grep('.rds',list.files('Applications/',full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    names(datasets)[which(datasets=='blankData.rds')] <- 'New Program'
    if (is.null(values$selectData)) {
      selectInput('selectData','Select Program:',datasets,selected='blankData.rds')
    } else {
      selectInput('selectData','Select Program:',datasets,selected=values$selectData)
    }
  })
  
  output$studyName <- renderUI({
    req(input$selectData)
    if (input$selectData!='blankData.rds') {
      HTML(paste(
        p(HTML(paste0('<h4>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<u>Selected Study</u></h4><h4>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
                      (basename(unlist(strsplit(input$selectData,'.rds')))),'</h4>')
        ))
      ))
    }
  })
  
  getData <- reactive({
    input$refreshPlot
    req(input$selectData)
    input$selectStudy
    Data <- readRDS(input$selectData)
  })
  
  observe({
    req(input$selectData)
    if (input$selectData == 'blankData.rds') {
      values$Application <- paste0('Applications/',input$newApplication,'.rds')
    } else {
      values$Application <- input$selectData
    }
  })
  
  observeEvent(input$saveData,{
    Data <- getData()
    saveRDS(Data,values$Application)
    datasets <- c('blankData.rds',grep('.rds',list.files('Applications/',full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    names(datasets)[which(datasets=='blankData.rds')] <- 'New Program'
    selectInput('selectData','Select Program:',datasets)
    updateSelectInput(session,'selectData',choices=datasets,selected=values$Application)
  })
  
  observeEvent(input$deleteData,{
    file.remove(values$Application)
    datasets <- c('blankData.rds',grep('.rds',list.files('Applications/',full.names = T),value=T))
    names(datasets) <- basename(unlist(strsplit(datasets,'.rds')))
    names(datasets)[which(datasets=='blankData.rds')] <- 'New Program'
    selectInput('selectData','Select Program:',datasets)
    updateSelectInput(session,'selectData',choices=datasets,selected='blankData.rds')
  })
  
  output$selectStudy <- renderUI({
    req(input$selectData)
    input$selectData
    isolate(Data <- getData())
    studyList <- names(Data[['Nonclinical Information']])
    selectInput('selectStudy','Select Study:',choices=studyList)
  })
  
  observeEvent(input$selectData,ignoreNULL = T,{
    Data <- getData()
    clinData <- Data[['Clinical Information']]
    if (clinData$MgKg==F) {
      updateNumericInput(session,'HumanWeight',value = clinData$HumanWeight)
    }
    clinDosing <- NULL
    for (dose in clinDosingOptions) {
      if (!is.null(clinData[[dose]][[gsub(' ','',dose)]])) {
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
  
  observeEvent(input$selectStudy,ignoreNULL = T,{
    Data <- getData()
    studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
    updateSelectInput(session,'Species',selected=studyData$Species)
    updateTextInput(session,'Duration',value=studyData$Duration)
    updateNumericInput(session,'nDoses',value=studyData$nDoses)
    updateNumericInput(session,'nFindings',value=studyData$nFindings)
  })
  
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
        findingList[[i]] <- list(Finding=input[[paste0('Finding',i)]],
                                 Reversibility = input[[paste0('Reversibility',i)]],
                                 FindingDoses = input[[paste0('FindingDoses',i)]]
        )
      }
    } else {
      findingList[[1]] <- NULL
    }
    
    Data <- getData()
    studyName <- paste(input$Species,input$Duration,sep=': ')
    Data[['Nonclinical Information']][[studyName]] <- list(
      Species = input$Species,
      Duration = input$Duration,
      nDoses = input$nDoses,
      Doses = doseList,
      nFindings = input$nFindings,
      Findings = findingList
    )
    
    saveRDS(Data,values$Application)
    
    studyList <- names(Data[['Nonclinical Information']])
    updateSelectInput(session,'selectStudy',choices=studyList,selected=studyName)
    input$refreshPlot
  })
  
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
  })
  
  observeEvent(input$deleteStudy,{
    Data <- getData()
    studyIndex <- which(names(Data[['Nonclinical Information']])==input$selectStudy)
    restIndex <- seq(length(names(Data[['Nonclinical Information']])))[-studyIndex]
    restNames <- names(Data[['Nonclinical Information']])[restIndex]
    Data[['Nonclinical Information']] <- Data[['Nonclinical Information']][restNames]
    saveRDS(Data,values$Application)
    studyList <- names(Data[['Nonclinical Information']])
    updateSelectInput(session,'selectStudy',choices=studyList,selected='New Study')
  })
  
  output$studyTitle <- renderText({
    paste(input$Species,input$Duration,sep=': ')
  })
  
  output$displayStudies <- renderUI({
    req(input$clinDosing)
    input$selectData
    input$selectStudy
    isolate(Data <- getData())
    studyList <- names(Data[['Nonclinical Information']])
    studyList <- studyList[-which(studyList=='New Study')]
    addUIDep(selectizeInput('displayStudies',label='Select Studies to Display:',choices=studyList,
                            selected=studyList,
                            multiple=TRUE,width='100%',options=list(plugins=list('drag_drop','remove_button'))))
  })
  
  output$Doses <- renderUI({
    req(input$selectStudy)
    if (input$selectStudy=='New Study') {
      lapply(1:(4*input$nDoses), function(i) {
        I <- ceiling(i/4)
        if (i %% 4 == 1) {
          numericInput(paste0('dose',I),paste0('Dose ',I,' (mg/kg/day):'),NULL)
        } else if (i %% 4 == 2) {
          checkboxInput(paste0('NOAEL',I),'NOAEL?',value=F)
        }
        else if (i %% 4 == 3) {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              numericInput(paste0('Cmax',I),paste0('Dose ',I,' Cmax (ng/mL):'),NULL))
        } else {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              numericInput(paste0('AUC',I),paste0('Dose ',I,' AUC (ng*h/mL):'),NULL))
        }
      })
    } else {
      Data <- getData()
      studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
      lapply(1:(4*input$nDoses), function(i) {
        I <- ceiling(i/4)
        doseName <- names(studyData$Doses)[I]
        if (i %% 4 == 1) {
          textInput(paste0('dose',I),paste0('Dose ',I,' (mg/kg/day):'),studyData$Doses[[doseName]][['Dose']])
        } else if (i %% 4 == 2) {
          checkboxInput(paste0('NOAEL',I),'NOAEL?',value=studyData$Doses[[doseName]][['NOAEL']])
        }
        else if (i %% 4 == 3) {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              numericInput(paste0('Cmax',I),paste0('Dose ',I,' Cmax (ng/mL):'),studyData$Doses[[doseName]][['Cmax']]))
        } else {
          div(style="display: inline-block;vertical-align:top; width: 115px;",
              numericInput(paste0('AUC',I),paste0('Dose ',I,' AUC (ng*h/mL):'),studyData$Doses[[doseName]][['AUC']]))
        }
      })
    }
  })
  
  output$Findings <- renderUI({
    req(input$selectStudy)
    if (input$selectStudy=='New Study') {
      if (input$nFindings>0) {
        numerator <- 2 + input$nDoses
        lapply(1:(numerator*input$nFindings), function(i) {
          I <- ceiling(i/numerator)
          if (i %% numerator == 1) {
            textInput(paste0('Finding',I),paste0('Finding ',I,':'))
          } else if (i %% numerator == 2) {
            radioButtons(paste0('Reversibility',I),'Reversibility:',
                         choiceNames=c('Reversible [Rev]','Not Reversible [NR]','Partially Reversible [PR]','Not Assessed'),
                         choiceValues=c('[Rev]','[NR]','[PR]',''))
          } else {
            lapply(1:input$nDoses, function(j) {
              if ((i %% numerator == 2+j)|((i %% numerator == 0)&(j==input$nDoses))) {
                selectInput(inputId = paste0('Severity',I,'_',j),label = paste0('Select Severity at Dose ',j,' (',input[[paste0('dose',j)]],' mg/kg/day)'),
                            choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'))
              }
            })
            
            
          }
            # } else if (i %% numerator == 4) {
          #   selectInput(inputId = paste0('Severity',I,'_2'),label = paste0('Select Severity at Dose ',I),
          #               choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'))
          # } else {
          #   selectInput(inputId = paste0('Severity',I,'_3'),label = paste0('Select Severity at Dose ',I),
          #               choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'))
          # }
          
          
          
          # else {
          #   doseLevels <- NULL
          #   for (i in seq(input$nDoses)) {
          #     if (i %% numerator == 2+i)
          #     doseLevel <- input[[paste0('dose',i)]]
          #     if (is.null(doseLevel)) {
          #       doseLevels[i] <- ''
          #     } else {
          #       doseLevels[i] <- doseLevel
          #     }
          #   }
            # checkboxGroupInput(paste0('FindingDoses',I),'Dose Levels:',
            #                    choiceNames = paste(doseLevels,'mg/kg/day'),
            #                    choiceValues = doseLevels,
            #                    selected = NULL)
          # }
        })
      }
    } else {
      Data <- getData()
      studyData <- Data[['Nonclinical Information']][[input$selectStudy]]
      if (input$nFindings>0) {
        numerator <- 2 + input$nDoses
        lapply(1:(3*input$nFindings), function(i) {
          I <- ceiling(i/numerator)
          if (i %% numerator == 1) {
            textInput(paste0('Finding',I),paste0('Finding ',I,':'),studyData$Findings[[paste0('Finding',I)]]$Finding)
          } else if (i %% numerator == 2) {
            radioButtons(paste0('Reversibility',I),'Reversibility:',
                         choiceNames=c('Reversible [Rev]','Not Reversible [NR]','Partially Reversible [PR]','Not Assessed'),
                         choiceValues=c('[Rev]','[NR]','[PR]',''),
                         selected=studyData$Findings[[paste0('Finding',I)]]$Reversibility)
          } else {
            for (j in seq(input$nDoses)) {
              print(i%%numerator)
              print(j+2)
              if ((i %% numerator == 2+j)|(i%%numerator==0)) {
                print('worked!')
                selectInput(paste0('Severity',I,'_',j),paste0('Select Severity at Dose ',I),
                            choices = c('Absent','Present','Minimal','Mild','Moderate','Marked','Severe'))
                break
              }
            }
          }
         
               # } else {
          #   doseLevels <- NULL
          #   for (i in seq(input$nDoses)) {
          #     doseLevel <- input[[paste0('dose',i)]]
          #     if (is.null(doseLevel)) {
          #       doseLevels[i] <- ''
          #     } else {
          #       doseLevels[i] <- doseLevel
          #     }
          #   }
          #   checkboxGroupInput(paste0('FindingDoses',I),'Dose Levels:',
          #                      choiceNames = paste(doseLevels,'mg/kg/day'),
          #                      choiceValues = doseLevels,
          #                      selected = studyData$Findings[[paste0('Finding',I)]]$FindingDoses)
          # }
        })
      }
    }
  })
  
  getPlotData <- reactive({
    Data <- getData()
    plotData <- data.frame(Study=NA,Dose=NA,Cmax=NA,AUC=NA,NOAEL=NA,doseFindings=NA)
    count <- 1
    for (Study in names(Data[['Nonclinical Information']])) {
      if (Study != 'New Study') {
        studyData <- Data[['Nonclinical Information']][[Study]]
        Doses <- NULL
        Cmaxs <- NULL
        AUCs <- NULL
        NOAELs <- NULL
        for (i in seq(studyData$nDoses)) {
          Doses[i] <- studyData$Doses[[paste0('Dose',i)]][['Dose']]
          Cmaxs[i] <- studyData$Doses[[paste0('Dose',i)]][['Cmax']]
          AUCs[i] <- studyData$Doses[[paste0('Dose',i)]][['AUC']]
          NOAELs[i] <- studyData$Doses[[paste0('Dose',i)]][['NOAEL']]
        }
        Findings <- NULL
        Reversible <- NULL
        FindingDoses <- NULL
        if (studyData$nFindings>0) {
          for (i in seq(studyData$nFindings)) {
            Findings[i] <- studyData$Findings[[paste0('Finding',i)]][['Finding']]
            Reversible[i] <- studyData$Findings[[paste0('Finding',i)]][['Reversibility']]
            FindingDoses[i] <- paste(studyData$Findings[[paste0('Finding',i)]][['FindingDoses']],collapse='|')
          }
        }
        for (Dose in Doses) {
          index <- which(Doses==Dose)
          Cmax <- Cmaxs[index]
          AUC <- AUCs[index]
          NOAEL <- NOAELs[index]
          findingFlag <- F
          doseFindings <- ''
          for (Finding in Findings) {
            findingIndex <- which(Findings==Finding)
            doseFindingDoses <- unlist(strsplit(FindingDoses[findingIndex],'|',fixed = T))
            if (Dose %in% doseFindingDoses) {
              if (doseFindings == '') {
                doseFindings <- paste0(Finding,' ',Reversible[findingIndex])
              } else {
                doseFindings <- paste0(doseFindings,'\n',Finding,' ',Reversible[findingIndex])
              }
            }
          }
          plotData[count,] <- c(Study,Dose,Cmax,AUC,NOAEL,doseFindings)
          count <- count + 1
          findingFlag <- T
        }
      }
    }
    plotData <- plotData[which(plotData$Study %in% input$displayStudies),]
    return(plotData)
  })
  
  output$humanDosing <- renderUI({
    req(input$clinDosing)
    Data <- getData()
    clinDosingNames <- input$clinDosing
    names(clinDosingNames) <- clinDosingNames
    if (length(clinDosingNames)>0) {
      for (clinDose in input$clinDosing) {
        if (Data[['Clinical Information']][['MgKg']]==F) {
          names(clinDosingNames)[which(clinDosingNames==clinDose)] <- paste0(clinDose,': (',Data[['Clinical Information']][[clinDose]][[paste0(unlist(strsplit(clinDose,' ')),collapse='')]],' mg)')
        } else {
          names(clinDosingNames)[which(clinDosingNames==clinDose)] <- paste0(clinDose,': (',Data[['Clinical Information']][[clinDose]][[paste0(unlist(strsplit(clinDose,' ')),'MgKg',collapse='')]],' mg/kg)')
        }
      }
    }
    selectInput('humanDosing','Select Human Dose:',choices=clinDosingNames)
  })
  
  calculateSM <- reactive({
    Data <- getData()
    plotData <- getPlotData()
    SM <- NULL
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
          humanDose <- Data[['Clinical Information']][[input$humanDosing]][[humanDoseName]]
          HED <- Dose/speciesConversion[[Species]]
          if (input$MgKg==F) {
            HED <- HED*Data[['Clinical Information']][['HumanWeight']]
          }
        } else {
          humanDose <- Data[['Clinical Information']][[input$humanDosing]][[paste0(humanDoseName,input$SMbasis)]]
          HED <- Dose
        }
        SM[i] <- HED/humanDose
      }
    }
    plotData <- cbind(plotData,SM)
    return(plotData)
  })
  
  output$table <- renderTable({
    plotData <- calculateSM()
    plotData
  })
  
  plotHeight <- function() {
    plotData <- calculateSM()
    nStudies <- length(unique(plotData$Study))
    plotHeight <- 100+200*nStudies
  }
  
  output$figure <- renderPlot({
    plotData <- calculateSM()
    if (nrow(plotData)>0) {
      plotData$Study <- factor(plotData$Study,levels=rev(input$displayStudies))
      plotData$DoseLabel <- factor(paste(plotData$Dose,'mg/kg/day'),levels=unique(paste(plotData$Dose,'mg/kg/day'))[order(unique(as.numeric(plotData$Dose),decreasing=F))])
      maxFindings <- 1
      for (doseFinding in plotData$doseFindings) {
        nFindings <- str_count(doseFinding,'\n')
        if (nFindings > maxFindings) {
          maxFindings <- nFindings
        }
      }
      maxFindings <- maxFindings + 1
      p <- ggplot(plotData,aes(y=SM,x=Study,label=DoseLabel)) + #label=paste(Dose,'mg/kg/day'))) +
        geom_label(aes(fill=NOAEL),
                   color='white',
                   label.padding=unit(0.5,'lines'),
                   fontface='bold',
                   position = ggstance::position_dodge2v(height = .4,preserve='single',padding=0)) +
        # for position need to modivy position_dodge2v code so that it n (groups) = 1 for all cases
        geom_text(aes(label=doseFindings),
                  nudge_x = -.08*maxFindings) +
        # geom_text_repel(aes(label=doseFindings),
        #                 direction='y',nudge_y = -.2) +
        scale_fill_manual(values=c(rgb(0,0,0),'#239B56')) +
        scale_y_log10(limits=c(min(plotData$SM/2),max(plotData$SM*2))) +
        labs(y='Safety Margin',x='Study',title='Summary of Toxicology Studies') +
        theme_classic(base_size=18) +
        theme(plot.title=element_text(hjust=0.5)) +
        guides(fill='none') + coord_flip() + geom_bar(aes(y=SM,x=doseFinding),stat='identity')
      p
    }
  },height=plotHeight)
  
  observe({
    req(input$selectData)
    values$selectData <- input$selectData
  })
  
  output$menu <- renderMenu({
    if (!is.null(input$selectData)) {
      if (input$selectData=='blankData.rds') {
        sidebarMenu(id='menu',
                    menuItem('Data Selection',icon=icon('database'),startExpanded = T,
                             uiOutput('selectData'),
                             conditionalPanel('input.selectData=="blankData.rds"',
                                              textInput('newApplication','Enter Tox Progam Name:')
                             ),
                             actionButton('saveData','Open New Program',icon=icon('plus-circle')),
                             br()
                    ),
                    br(),
                    uiOutput('studyName'),
                    br(),
                    br()
        )
      } else {
        sidebarMenu(id='menu',
                    menuItem('Data Selection',icon=icon('database'),startExpanded = T,
                             uiOutput('selectData'),
                             conditionalPanel('input.selectData=="blankData.rds"',
                                              textInput('newApplication','Enter Tox Program Name:')
                             ),
                             actionButton('deleteData','Delete Program',icon=icon('minus-circle')),
                             br()
                    ),
                    hr(),
                    uiOutput('studyName'),
                    hr(),
                    menuItem('Clinical Data',icon=icon('user'),
                             checkboxGroupInput('clinDosing','Clinical Dosing:',clinDosingOptions),
                             conditionalPanel('condition=input.MgKg==false',
                                              numericInput('HumanWeight','*Human Weight (kg):',value=60)
                             ),
                             checkboxInput('MgKg','Dosing in mg/kg?',value=F),
                             conditionalPanel(
                               condition='input.clinDosing.includes("Start Dose")',
                               h4('Start Dose Information:'),
                               conditionalPanel(condition='input.MgKg==true',
                                                numericInput('StartDoseMgKg','*Start Dose (mg/kg/day):',value=NULL)
                               ),
                               conditionalPanel(condition='input.MgKg==false',
                                                numericInput('StartDose','*Start Dose (mg/day):',value = NULL)
                               ),
                               numericInput('StartDoseCmax','Start Dose Cmax (ng/mL):',value=NULL),
                               numericInput('StartDoseAUC','Start Dose AUC (ng*h/mL):',value=NULL)
                             ),
                             conditionalPanel(
                               condition='input.clinDosing.includes("MRHD")',
                               h4('MRHD Information:'),
                               conditionalPanel(condition='input.MgKg==true',
                                                numericInput('MRHDMgKG','*MRHD (mg/kg):',value=NULL)
                               ),
                               conditionalPanel(condition='input.MgKg==false',
                                                numericInput('MRHD','*MRHD (mg):',value = NULL)
                               ),
                               numericInput('MRHDCmax','MRHD Cmax (ng/mL):',value=NULL),
                               numericInput('MRHDAUC','MRHD AUC (ng*h/mL):',value=NULL)
                             ),
                             conditionalPanel(
                               condition='input.clinDosing.includes("Custom Dose")',
                               h4('Custom Dose Information:'),
                               conditionalPanel(condition='input.MgKg==true',
                                                numericInput('CustomDoseMgKG','*Custom Dose (mg/kg):',value=NULL)
                               ),
                               conditionalPanel(condition='input.MgKg==false',
                                                numericInput('CustomDose','*Custom Dose (mg):',value = NULL)
                               ),
                               numericInput('CustomDoseCmax','Custom Dose Cmax (ng/mL):',value=NULL),
                               numericInput('CustomDoseAUC','Custom Dose AUC (ng*h/mL):',value=NULL)
                             ),
                             actionButton('saveClinicalInfo','Save Clinical Information',icon=icon('plus-circle')),
                             br()
                    ),                   
                    menuItem('Nonclinical Data',icon=icon('flask'),tabName = 'Nonclinical Info',
                             uiOutput('selectStudy'),
                             actionButton('saveStudy','Save Study',icon=icon('plus-circle')),
                             actionButton('deleteStudy','Remove Study',icon=icon('minus-circle')),
                             
                             h4('Study Name:'),
                             verbatimTextOutput('studyTitle'),
                             
                             selectInput('Species','*Select Species:',choices=names(speciesConversion)),
                             textInput('Duration','*Study Duration/Description:'),
                             numericInput('nDoses','Number of Dose Levels:',value=3,step=1,min=1),
                             uiOutput('Doses'),
                             numericInput('nFindings','Number of Findings:',value=0,step=1,min=0),
                             uiOutput('Findings'),
                             br()
                    ),
                    hr(),
                    h6('* Indicates Required Fields')
                    
        )
      }
    } else {
      sidebarMenu(id='menu',
                  menuItem('Data Selection',icon=icon('database'),startExpanded = T,
                           uiOutput('selectData'),
                           conditionalPanel('input.selectData=="blankData.rds"',
                                            textInput('newApplication','Enter Tox Program Name:')
                           ),
                           actionButton('saveData','Open New Program',icon=icon('plus-circle')),
                           br()
                  ),
                  br(),
                  uiOutput('studyName'),
                  br(),
                  br()
      )
    }
  })
}

ui <- dashboardPage(
  
  dashboardHeader(title="Nonclinical Summary Tool",titleWidth = 250),
  
  dashboardSidebar(width = 250,
                   sidebarMenuOutput('menu')
  ),
  
  dashboardBody(
    fluidRow(
      column(4,
             uiOutput('humanDosing')
      ),
      column(4,
             conditionalPanel(
               'input.clinDosing != null && input.clinDosing != ""',
               selectInput('SMbasis','Base Safety Margin on:',c('HED','Cmax','AUC'))
             )
      ),
      column(4,
             uiOutput('displayStudies')
      )
    ),
    conditionalPanel(
      condition='input.selectData!="blankData.rds"',
      tabsetPanel(
        tabPanel('Figure',
                 actionButton('refreshPlot','Refresh Plot'),
                 br(),
                 plotOutput('figure')
        ),
        tabPanel('Table',
                 tableOutput('table')
        )
      )
    )
  )
)



shinyApp(ui = ui, server = server)