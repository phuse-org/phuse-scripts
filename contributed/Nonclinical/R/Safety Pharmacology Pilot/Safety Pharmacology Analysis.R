library(tools)
library(parsedate)
library(reshape2)
library(ggplot2)
library(shiny)
library(DT)
library(shinycssloaders)
library(stringr)
library(httr)
library(SASxport)
library(Hmisc)
library(DT)

#!!!!!!!! Add a tab with text description of the algorithm !!!!!!!!#

source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')

dataPath <- 'data/send/CDISC-Safety-Pharmacology-POC'

DOIs <- c('cv','eg','vs')
domainColumnsNoINT <- c('TEST','TESTCD','STRESN','STRESU','NOMDY','TPTNUM','ELTM','ELTMN','TPTREF')
domainColumnsINT <- c(domainColumnsNoINT,'EVLINT','STINT','ENINT','EVLINTN')

max_tests <- 100

values <- reactiveValues()
values$nTests <- max_tests

if (file.exists('~/passwordGitHub.R')) {
  source('~/passwordGitHub.R')
  Authenticate <- TRUE
} else {
  Authenticate <- FALSE
}

server <- function(input, output,session) {
  
  loadData <- reactive({
    if (Authenticate==T) {
      Data <- load.GitHub.xpt.files(studyDir=dataPath,authenticate=T,User=userGitHub,Password=passwordGitHub)
    } else {
      Data <- load.GitHub.xpt.files(studyDir=dataPath,authenticate = F)
    }
    subjects <- unique(Data$dm$USUBJID)
    elementLevels <- levels(Data$se$ELEMENT)
    for (domain in DOIs) {
      sexData <- Data$dm[,c('USUBJID','SEX')]
      elementData <- Data$se[,c('USUBJID','SESTDTC','ELEMENT')]
      Data[[domain]] <- merge(Data[[domain]],sexData,by='USUBJID')
      Data[[domain]] <- merge(Data[[domain]],elementData,by.x=c('USUBJID',paste0(toupper(domain),'RFTDTC')),by.y=c('USUBJID','SESTDTC'))
      Data[[domain]]$SEX <- factor(Data[[domain]]$SEX,levels=c('M','F'))
      ELTM <- Data[[domain]][[paste0(toupper(domain),'ELTM')]]
      ELTMnum <- sapply(ELTM,DUR_to_seconds)/3600
      Data[[domain]][[paste0(toupper(domain),'ELTM')]] <- paste(ELTMnum,'h')
      orderedELTM <- Data[[domain]][[paste0(toupper(domain),'ELTM')]][order(Data[[domain]][[paste0(toupper(domain),'TPTNUM')]])]
      orderedLevelsELTM <- unique(orderedELTM)
      Data[[domain]][[paste0(toupper(domain),'ELTM')]] <- factor(Data[[domain]][[paste0(toupper(domain),'ELTM')]],levels=orderedLevelsELTM)
      Data[[domain]][[paste0(toupper(domain),'ELTMN')]] <- ELTMnum
      if (length(grep('INT',colnames(Data[[domain]])))>=2) {
        STINT <- Data[[domain]][[paste0(toupper(domain),'STINT')]]
        STINTnum <- sapply(STINT,DUR_to_seconds)/3600
        ENINT <- Data[[domain]][[paste0(toupper(domain),'ENINT')]]
        ENINTnum <- sapply(ENINT,DUR_to_seconds)/3600
        Data[[domain]][[paste0(toupper(domain),'EVLINT')]] <- paste0(STINTnum,' to ',ENINTnum,' h')
        orderedEVLINT <- Data[[domain]][[paste0(toupper(domain),'EVLINT')]][order(Data[[domain]][[paste0(toupper(domain),'TPTNUM')]])]
        orderedLevelsEVLINT <- unique(orderedEVLINT)
        Data[[domain]][[paste0(toupper(domain),'EVLINT')]] <- factor(Data[[domain]][[paste0(toupper(domain),'EVLINT')]],levels=orderedLevelsEVLINT)
        Data[[domain]][[paste0(toupper(domain),'EVLINTN')]] <- rowMeans(cbind(STINTnum,ENINTnum))
      }
    }
    return(Data)
  })
  
  filterSex <- reactive({
    Data <- loadData()
    for (domain in DOIs) {
      if (input$sex == 'Males Only') {
        index <- which(Data[[domain]][['SEX']]=='M')
        Data[[domain]] <- Data[[domain]][index,]
      } else if (input$sex == 'Females Only') {
        index <- which(Data[[domain]][['SEX']]=='F')
        Data[[domain]] <- Data[[domain]][index,]
      }
    }
    return(Data)
  })
  
  getIndividualTables <- reactive({
    req(input$DOIs)
    Data <- filterSex()
    individualTables <- list()
    for (domain in input$DOIs) {
      if (length(grep('INT',colnames(Data[[domain]])))>=2) {
        domainColumns <- domainColumnsINT
        INTflag <- T
      } else {
        domainColumns <- domainColumnsNoINT
        INTflag <- F
      }
      testDataColumns <- c('USUBJID',paste0(toupper(domain),domainColumns),'ELEMENT','SEX')
      testDataColumns <- testDataColumns[testDataColumns %in% colnames(Data[[domain]])]
      testCDs <- unique(Data[[domain]][[paste0(toupper(domain),'TESTCD')]])
      for (testCD in testCDs) {
        if (exists('testData')) rm(testData)
        testData <- Data[[domain]][which(Data[[domain]][[paste0(toupper(domain),'TESTCD')]]==testCD),testDataColumns]
        colnames(testData)[(seq(length(domainColumns))+1)] <- domainColumns
        if (INTflag == T) {
          testIndividualData <- dcast(testData,TEST+ELEMENT+SEX+NOMDY+USUBJID~EVLINT,value.var = 'STRESN')
        } else {
          testIndividualData <- dcast(testData,TEST+ELEMENT+SEX+NOMDY+USUBJID~ELTM,value.var = 'STRESN')
        }
        testIndividualData <- testIndividualData[order(testIndividualData$ELEMENT,testIndividualData$SEX,testIndividualData$NOMDY,testIndividualData$USUBJID,decreasing=F),]
        individualTables[[paste(toupper(domain),testCD,sep='_')]] <- testIndividualData
      }
    }
    return(individualTables)
  })
  
  getMeanTables <- reactive({
    req(input$DOIs)
    Data <- filterSex()
    meanTables <- list()
    for (domain in input$DOIs) {
      if (length(grep('INT',colnames(Data[[domain]])))>=2) {
        domainColumns <- domainColumnsINT
        INTflag <- T
      } else {
        domainColumns <- domainColumnsNoINT
        INTflag <- F
      }
      testDataColumns <- c('USUBJID',paste0(toupper(domain),domainColumns),'ELEMENT','SEX')
      testDataColumns <- testDataColumns[testDataColumns %in% colnames(Data[[domain]])]
      testCDs <- unique(Data[[domain]][[paste0(toupper(domain),'TESTCD')]]) # this will be user-defined
      for (testCD in testCDs) {
        if (exists('testData')) rm(testData)
        testData <- Data[[domain]][which(Data[[domain]][[paste0(toupper(domain),'TESTCD')]]==testCD),testDataColumns]
        colnames(testData)[(seq(length(domainColumns))+1)] <- domainColumns
        subjectElement <- paste(testData$USUBJID,testData$ELEMENT,sep='_')
        testData <- cbind(testData,subjectElement)
        if (INTflag == T) {
          meanTestData <- dcast(testData,TEST+ELEMENT+SEX~EVLINT,value.var='STRESN',mean)
        } else {
          meanTestData <- dcast(testData,TEST+ELEMENT+SEX~ELTM,value.var='STRESN',mean)
        }
        meanTestData <- meanTestData[order(meanTestData$ELEMENT,meanTestData$SEX,decreasing=F),]
        meanTables[[paste(toupper(domain),testCD,sep='_')]] <- meanTestData
      }
    }
    return(meanTables)
  })
  
  observe({
    req(input$DOIs)
    Data <- loadData()
    domains <- input$DOIs
    n <- 0
    for (domain in domains) {
      n <- n + length(unique(Data[[domain]][[paste0(toupper(domain),'TEST')]]))
    }
    values$nTests <- n
  })
  
  output$tables <- renderUI({
    req(input$DOIs)
    table_output_list <- lapply(seq(values$nTests), function(i) {
      tableName <- paste("table", i, sep="")
      DT::dataTableOutput(tableName)
    })
    do.call(tagList, table_output_list)
  })
  
  for (i in seq(max_tests)) {
    local({
      my_i <- i
      tableName <- paste("table", my_i, sep="")
      
      output[[tableName]] <- DT::renderDataTable({
        datatable({
          if (my_i <= values$nTests) {
            if (input$summary=='Individuals') {
              individualTables <- getIndividualTables()
              individualTable <- individualTables[[my_i]]
            } else if (input$summary=='Group Means') {
              meanTables <- getMeanTables()
              meanTable <- meanTables[[my_i]]
            }
          }
        },options=list(autoWidth=T,scrollX=T,pageLength=100,paging=F,searching=F,
                       columnDefs=list(list(className='dt-center',width='100px',targets='_all'))),
        rownames=F)
      })
    })
  }
  
  getTestData <- reactive({
    req(input$DOIs)
    Data <- filterSex()
    testDataList <- list()
    for (domain in input$DOIs) {
      if (length(grep('INT',colnames(Data[[domain]])))>=2) {
        domainColumns <- domainColumnsINT
        INTflag <- T
      } else {
        domainColumns <- domainColumnsNoINT
        INTflag <- F
      }
      testDataColumns <- c('USUBJID',paste0(toupper(domain),domainColumns),'ELEMENT','SEX')
      testDataColumns <- testDataColumns[testDataColumns %in% colnames(Data[[domain]])]
      testCDs <- unique(Data[[domain]][[paste0(toupper(domain),'TESTCD')]]) # this will be user-defined
      for (testCD in testCDs) {
        if (exists('testData')) rm(testData)
        testData <- Data[[domain]][which(Data[[domain]][[paste0(toupper(domain),'TESTCD')]]==testCD),testDataColumns]
        colnames(testData)[(seq(length(domainColumns))+1)] <- domainColumns
        subjectElement <- paste(testData$USUBJID,testData$ELEMENT,sep='_')
        testData <- cbind(testData,subjectElement)
        testDataList[[paste(toupper(domain),testCD,sep='_')]] <- testData
      }
    }
    return(testDataList)
  })
  
  getMeanTestData <- reactive({
    req(input$DOIs)
    Data <- filterSex()
    meanTestDataList <- list()
    for (domain in input$DOIs) {
      if (length(grep('INT',colnames(Data[[domain]])))>=2) {
        domainColumns <- domainColumnsINT
        INTflag <- T
      } else {
        domainColumns <- domainColumnsNoINT
        INTflag <- F
      }
      testDataColumns <- c('USUBJID',paste0(toupper(domain),domainColumns),'ELEMENT','SEX')
      testDataColumns <- testDataColumns[testDataColumns %in% colnames(Data[[domain]])]
      testCDs <- unique(Data[[domain]][[paste0(toupper(domain),'TESTCD')]]) # this will be user-defined
      for (testCD in testCDs) {
        if (exists('testData')) rm(testData)
        testData <- Data[[domain]][which(Data[[domain]][[paste0(toupper(domain),'TESTCD')]]==testCD),testDataColumns]
        colnames(testData)[(seq(length(domainColumns))+1)] <- domainColumns
        sexElement <- paste(testData$SEX,testData$ELEMENT,sep='_')
        if (INTflag == T) {
          meanTables <- dcast(testData,TEST+sexElement+ELEMENT+SEX~EVLINTN,value.var='STRESN',mean)
        } else {
          meanTables <- dcast(testData,TEST+sexElement+ELEMENT+SEX~ELTMN,value.var='STRESN',mean)
        }
        meanTestData <- melt(meanTables,id=c('TEST','sexElement','ELEMENT','SEX'))
        meanTestDataList[[paste(toupper(domain),testCD,sep='_')]] <- meanTestData
      }
    }
    return(meanTestDataList)
  })
  
  output$plots <- renderUI({
    req(input$DOIs)
    plot_output_list <- lapply(seq(values$nTests), function(i) {
      plotName <- paste("plot", i, sep="")
      plotOutput(plotName,height='600px')
    })
    do.call(tagList, plot_output_list)
  })
  
  for (i in seq(max_tests)) {
    local({
      my_i <- i
      plotName <- paste("plot", my_i, sep="")
      
      output[[plotName]] <- renderPlot({
        pointSize <- 3
        colorPalette <- c('black','blue','purple','red')
        if (my_i <= values$nTests) {
          if (input$summary=='Individuals') {
            testDataList <- getTestData()
            testData <- testDataList[[my_i]]
            print(head(testData))
            if (length(grep('INT',colnames(testData)))>=2) {
              p <- ggplot(testData,aes(x=EVLINTN,y=STRESN,group=subjectElement,color=ELEMENT,shape=USUBJID))
            } else {
              p <- ggplot(testData,aes(x=ELTMN,y=STRESN,group=subjectElement,color=ELEMENT,shape=USUBJID))
            }
            p <- p + geom_point(size=pointSize) + geom_line() + labs(title=testData$TEST[1],x='Time (h)',y=paste0(testData$TESTCD[1],' (',testData$STRESU[1],')')) +
              scale_color_discrete(name = "Dose Group") + scale_shape_discrete('Subject')
          } else if (input$summary=='Group Means') {
            testDataList <- getTestData()
            testData <- testDataList[[my_i]]
            meanTestDataList <- getMeanTestData()
            meanTestData <- meanTestDataList[[my_i]]
            p <- ggplot(meanTestData,aes(x=as.numeric(levels(variable)[variable]),y=value,group=sexElement,color=ELEMENT,shape=SEX)) + 
              geom_point(size=pointSize) + geom_line() + labs(title=meanTestData$TEST[1],x='Time (h)',y=paste0(testData$TESTCD[1],' (',testData$STRESU[1],')')) +
              scale_color_discrete(name = "Dose Group") + scale_shape_discrete(name = 'Sex')
          }
          p <- p + theme_classic() + 
            theme(text=element_text(size=16),
                  axis.title.y=element_text(margin = margin(t=0,r=10,b=0,l=0)),
                  axis.title.x=element_text(margin = margin(t=10,r=,b=0,l=0)),
                  plot.title=element_text(hjust=0.5,margin=margin(t=0,r=0,b=10,l=0))) + 
            scale_color_manual(values=colorPalette)
          p
        }
      })
    })
  }
  
  output$CV <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      CV <- Data$cv
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$DM <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      DM <- Data$dm
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$DS <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      DS <- Data$ds
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$EG <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      EG <- Data$eg
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$EX <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      EX <- Data$ex
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$SE <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      SE <- Data$se
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$TA <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      TA <- Data$ta
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$TE <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      TE <- Data$te
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$TS <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      TS <- Data$ts
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$TX <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      TX <- Data$tx
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
  output$VS <- DT::renderDataTable({
    datatable({
      Data <- loadData()
      VS <- Data$vs
    },options=list(autoWidth=T,scrollX=F,pageLength=10,paging=T,searching=F,
                   columnDefs=list(list(className='dt-center',targets='_all'))),
    rownames=F)
  })
  
}

ui <- shinyUI(
  fluidPage(titlePanel(title='CDISC-SEND Safety Pharmacology Proof-of-Concept Pilot',
                       windowTitle = 'CDISC-SEND Safety Pharmacology Proof-of-Concept Pilot'),br(),
    sidebarLayout(
      sidebarPanel(width=3,
                   checkboxGroupInput('DOIs','Domains of Interest:',choiceNames=toupper(DOIs),choiceValues=DOIs,selected=DOIs),
                   radioButtons('summary','Display:',c('Group Means','Individuals')),
                   conditionalPanel(condition='input.summary="Group Means"',
                                    radioButtons('sex','Sex:',c('Males and Females','Males Only','Females Only'))
                   )
      ),
      mainPanel(width=9,
        tabsetPanel(
          tabPanel('Tables',
                   withSpinner(uiOutput('tables'),type=5)
                   # withSpinner(uiOutput('tables'),type=5)
          ),
          tabPanel('Plots',
                   withSpinner(uiOutput('plots'),type=5)
          ),
          tabPanel('Algorithm Description',
                   column(11,
                          h4('A Latin square experimental design is used to control variation in an experiment across 
                             two blocking factors, in this case: subject and time.  In a traditional Latin square safety 
                             pharmacology study, several findings e.g., heart rate, QT duration, temperature, are recorded 
                             in each dog for a couple of hours predose and then for an extended period of time, e.g. 24 
                             hours, following a single dose of the investigational therapy or vehicle.  Doses are typically 
                             followed by a one-week washout period.  As shown in the example Latin square study design 
                             below, each dog receives a single dose of each treatment level throughout the course of 
                             the study, but no two dogs receive the same treatment on the same day:'),
                          br(),
                          HTML('<center><img src="Latin Square.png"></center>'),
                          br(),
                          br(),
                          h4('This type of study design was modeled in the proof-of-concept SEND dataset by describing the 
                             treatment level in the ELEMENT field of the subject elements (SE) domain.  As each ELEMENT 
                             began at the time of dosing, treatment effects can be observed by matching, for each subject, 
                             the start time of each ELEMENT (SESTDTC) with the reference dose time (--RFTDTC) of each finding 
                             record. The following example of SQL code demonstrates the logic of this operation:'),
                          br(),
                          h4('SELECT * FROM CV, SE'),
                          h4('JOIN CV, SE'),
                          h4('ON CV.USUBJID = SE.USUBJID'),
                          h4('AND CV.CVRFTDTC = SE.SESTDTC'),
                          br(),
                          h4('Tables were created for each type of finding (--TEST) in each of the finding domains by 
                             pivoting the table on the field encoding the duration of time elapsed between dosing and 
                             each observation (--ELTM). If the finding of interest was collected over an interval of 
                             time, then the start (--STINT) and end (ENINT) times of the recording interval for each 
                             record were used to represent the recording interval in the place of the elapsed time point. 
                             The order of time points/intervals was set chronologically using the --TPTNUM variable.
                             Mean values were calculated for each dosing group (ELEMENT) within each sex (SEX) for each 
                             time point or interval of observation. Plots were generated using the same method, except 
                             observations recorded over an interval of time were represented on the x-axis at the 
                             mid-point of the interval.'),
                          br(),
                          h4('The proof-of-concept dataset used here was created by CDISC and is publicly available at:'),
                          tags$a(href='https://github.com/phuse-org/phuse-scripts/tree/master/data/send/CDISC-Safety-Pharmacology-POC',
                                 'https://github.com/phuse-org/phuse-scripts/tree/master/data/send/CDISC-Safety-Pharmacology-POC'),
                          br(),br()
                   )
          ),
          tabPanel('Raw SEND Data',
                   tabsetPanel(
                     tabPanel('CV',
                              withSpinner(DT::dataTableOutput('CV'),type=5)
                     ),
                     tabPanel('DM',
                              withSpinner(DT::dataTableOutput('DM'),type=5)
                              ),
                     tabPanel('DS',
                              withSpinner(DT::dataTableOutput('DS'),type=5)
                     ),
                     tabPanel('EG',
                              withSpinner(DT::dataTableOutput('EG'),type=5)
                     ),
                     tabPanel('EX',
                              withSpinner(DT::dataTableOutput('EX'),type=5)
                     ),
                     tabPanel('SE',
                              withSpinner(DT::dataTableOutput('SE'),type=5)
                     ),
                     tabPanel('TA',
                              withSpinner(DT::dataTableOutput('TA'),type=5)
                     ),
                     tabPanel('TE',
                              withSpinner(DT::dataTableOutput('TE'),type=5)
                     ),
                     tabPanel('TS',
                              withSpinner(DT::dataTableOutput('TS'),type=5)
                     ),
                     tabPanel('TX',
                              withSpinner(DT::dataTableOutput('TX'),type=5)
                     ),
                     tabPanel('VS',
                              withSpinner(DT::dataTableOutput('VS'),type=5)
                     ),
                     tabPanel('README',
                              pre(includeText('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/send/CDISC-Safety-Pharmacology-POC/readme.txt'))
                     )
                     # tabPanel('define.xml'
                     #          
                     # )
                   )
                   )
        )
      )
    )
  )
)

# Run Shiny App
shinyApp(ui = ui, server = server)