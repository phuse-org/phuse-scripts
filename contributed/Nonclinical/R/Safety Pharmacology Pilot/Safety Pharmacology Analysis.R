library(tools)
library(parsedate)
library(reshape2)
library(ggplot2)
library(shiny)
library(DT)
library(shinycssloaders)
library(httr)
library(Hmisc)
library(DT)
library(xml2)
library(xslt)

GitHubPath <- 'https://raw.githubusercontent.com/phuse-org/phuse-scripts/master'
dataPath <- 'data/send/CDISC-Safety-Pharmacology-POC'
functionPath <- 'contributed/Nonclinical/R/Functions/Functions.R'

source(paste(GitHubPath,functionPath,sep='/'))

DOIs <- c('cv','eg','vs')
domainColumnsNoINT <- c('TEST','TESTCD','STRESN','STRESU','NOMDY','TPTNUM','ELTM','ELTMN','TPTREF')
domainColumnsINT <- c(domainColumnsNoINT,'EVLINT','STINT','ENINT','EVLINTN')

values <- reactiveValues()

if (file.exists('~/passwordGitHub.R')) {
  source('~/passwordGitHub.R')
  Authenticate <- TRUE
} else {
  Authenticate <- FALSE
}

server <- function(input, output,session) {
  
  loadData <- reactive({
    withProgress({
      if (Authenticate==T) {
        Data <- load.GitHub.xpt.files(studyDir=dataPath,authenticate=T,User=userGitHub,Password=passwordGitHub,showProgress=T)
      } else {
        Data <- load.GitHub.xpt.files(studyDir=dataPath,authenticate=F,showProgress=T)
      }
      setProgress(value=1,message='Processing Data...')
      values$domainNames <- toupper(names(Data))
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
    })
    return(Data)
  })
  
  output$tests <- renderUI({
    req(input$DOIs)
    Data <- loadData()
    Tests <- NULL
    for (domain in input$DOIs) {
      testNames <- levels(Data[[domain]][[paste0(toupper(domain),'TEST')]])[unique(Data[[domain]][[paste0(toupper(domain),'TEST')]])]
      Tests <- c(Tests,testNames)
    }
    checkboxGroupInput('tests','Tests of Interest:',Tests,Tests)
  })
  
  output$doses <- renderUI({
    Data <- loadData()
    doses <- NULL
    for (domain in DOIs) {
      doses <- unique(c(doses,levels(Data[[domain]][['ELEMENT']])[Data[[domain]][['ELEMENT']]]))
    }
    dosesN <- as.numeric(lapply(strsplit(doses,' '),`[[`,1))
    doses <- doses[order(dosesN)]
    checkboxGroupInput('doses','Filter by Dose Level:',choices=doses,selected=doses)
  })
  
  output$subjects <- renderUI({
    Data <- loadData()
    subjects <- NULL
    for (domain in DOIs) {
      subjects <- unique(c(subjects,levels(Data[[domain]][['USUBJID']])[Data[[domain]][['USUBJID']]]))
    }
    checkboxGroupInput('subjects','Filter by Subject:',choices=subjects,selected=subjects)
  })
  
  output$days <- renderUI({
    Data <- loadData()
    days <- NULL
    for (domain in DOIs) {
      days <- unique(c(days,Data[[domain]][[paste0(toupper(domain),'NOMDY')]]))
    }
    checkboxGroupInput('days','Filter by Day:',choices=days,selected=days)
  })
  
  filterData <- reactive({
    Data <- loadData()
    for (domain in DOIs) {
      testIndex <- which(levels(Data[[domain]][[paste0(toupper(domain),'TEST')]])[Data[[domain]][[paste0(toupper(domain),'TEST')]]] 
                         %in% input$tests)
      sexIndex <- which(Data[[domain]][['SEX']] %in% input$sex)
      doseIndex <- which(Data[[domain]][['ELEMENT']] %in% input$doses)
      subjectIndex <- which(Data[[domain]][['USUBJID']] %in% input$subjects)
      dayIndex <- which(Data[[domain]][[paste0(toupper(domain),'NOMDY')]] %in% input$days)
      index <- Reduce(intersect,list(testIndex,sexIndex,doseIndex,subjectIndex,dayIndex))
      Data[[domain]] <- Data[[domain]][index,]
    }
    return(Data)
  })
  
  getIndividualTables <- reactive({
    req(input$DOIs)
    Data <- filterData()
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
    Data <- filterData()
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
        groupElement <- paste(testData$USUBJID,testData$ELEMENT,sep='_')
        testData <- cbind(testData,groupElement)
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
    req(input$tests)
    values$nTests <- length(input$tests)
  })
  
  observe({
    req(input$DOIs)
    if (input$summary=='Individual Subjects') {
      values$table <- getIndividualTables()
    } else if (input$summary=='Group Means') {
      values$table <- getMeanTables()
    }
  })
  
  output$tables <- renderUI({
    req(input$DOIs)
    table_output_list <- lapply(seq(values$nTests), function(i) {
      tableName <- paste0('table',i)
      DT::dataTableOutput(tableName)
    })
    do.call(tagList, table_output_list)
  })
  
  observe({
    lapply(seq(values$nTests),function(i) {
      output[[paste0('table',i)]] <- DT::renderDataTable({
        datatable({
          Table <- values$table[[i]]
        },options=list(autoWidth=T,scrollX=T,pageLength=100,paging=F,searching=F,#),
                       columnDefs=list(list(className='dt-center',width='100px',
                                            targets=seq(0,(ncol(values$table[[i]])-1))))),
        rownames=F)
      })
    })
  })
  
  getTestData <- reactive({
    req(input$DOIs)
    Data <- filterData()
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
        if (input$plotBy=='Subject') {
          groupElement <- paste(testData$USUBJID,testData$ELEMENT,sep='_')
        } else if (input$plotBy=='Day') {
          groupElement <- paste(testData$NOMDY,testData$ELEMENT,sep='_')
        }
        testData <- cbind(testData,groupElement)
        testDataList[[paste(toupper(domain),testCD,sep='_')]] <- testData
      }
    }
    return(testDataList)
  })
  
  getMeanTestData <- reactive({
    req(input$DOIs)
    Data <- filterData()
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
  
  observe({
    lapply(seq(values$nTests),function(i) {
      output[[paste0('plot',i)]] <- renderPlot({
        pointSize <- 3
        colorPalette <- c('black','blue','purple','red')
        # if (i <= values$nTests) {
          if (input$summary=='Individual Subjects') {
            testDataList <- getTestData()
            testData <- testDataList[[i]]
            testData$NOMDY <- factor(as.character(testData$NOMDY),levels=(as.character(unique(testData$NOMDY)[order(unique(testData$NOMDY))])))
            if (length(grep('INT',colnames(testData)))>=2) {
              if (input$plotBy == 'Subject') {
                p <- ggplot(testData,aes(x=EVLINTN,y=STRESN,group=groupElement,color=ELEMENT,shape=USUBJID)) + scale_shape_discrete('Subject')
              } else if (input$plotBy == 'Day') {
                p <- ggplot(testData,aes(x=EVLINTN,y=STRESN,group=groupElement,color=ELEMENT,shape=NOMDY)) + scale_shape_discrete('Day')
              }
            } else {
              if (input$plotBy == 'Subject') {
                p <- ggplot(testData,aes(x=ELTMN,y=STRESN,group=groupElement,color=ELEMENT,shape=USUBJID)) + scale_shape_discrete('Subject')
              } else if (input$plotBy == 'Day') {
                p <- ggplot(testData,aes(x=ELTMN,y=STRESN,group=groupElement,color=ELEMENT,shape=NOMDY)) + scale_shape_discrete('Day')
              }
            }
            p <- p + geom_point(size=pointSize) + geom_line() + labs(title=testData$TEST[1],x='Time (h)',y=paste0(testData$TESTCD[1],' (',testData$STRESU[1],')')) +
              scale_color_discrete(name = "Dose Group")# + scale_shape_discrete('Subject')
          } else if (input$summary=='Group Means') {
            testDataList <- getTestData()
            testData <- testDataList[[i]]
            meanTestDataList <- getMeanTestData()
            meanTestData <- meanTestDataList[[i]]
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
        # }
      })
    })
  })
  
  output$SENDdomains <- renderUI({
    nTabs <- length(values$domainNames)
    myTabs <- lapply(seq_len(nTabs),function(i) {
      tabPanel(values$domainNames[i],
               DT::dataTableOutput(paste0('datatable_',i))
      )
    })
    do.call(tabsetPanel,myTabs)
  })
  
  observe({
    lapply(seq(values$domainNames),function(i) {
      output[[paste0('datatable_',i)]] <- DT::renderDataTable({
        datatable({
          Data <- loadData()
          rawTable <- Data[[tolower(values$domainNames[i])]]
        },options=list(autoWidth=T,scrollX=T,pageLength=10,paging=T,searching=T,
                     columnDefs=list(list(className='dt-center',targets='_all'))),
        rownames=F)
      })
    })
  })
  
  output$define <- renderUI({
    doc <- read_xml(paste(GitHubPath,dataPath,'define.xml',sep='/'))
    style <- read_xml(paste(GitHubPath,dataPath,'define2-0-0.xsl',sep='/'))
    html <- xml_xslt(doc,style)
    cat(as.character(html),file='www/temp.html')
    define <- tags$iframe(src='temp.html', height='700', width='100%')
    define
  })
  
}

ui <- shinyUI(
  fluidPage(titlePanel(title='CDISC-SEND Safety Pharmacology Proof-of-Concept Pilot',
                       windowTitle = 'CDISC-SEND Safety Pharmacology Proof-of-Concept Pilot'),br(),
            sidebarLayout(
              sidebarPanel(width=3,
                           checkboxGroupInput('DOIs','Domains of Interest:',choiceNames=toupper(DOIs),choiceValues=DOIs,selected=DOIs),
                           uiOutput('tests'),
                           radioButtons('summary','Display:',c('Group Means','Individual Subjects')),
                           checkboxGroupInput('sex','Filter by Sex:',list(Male='M',Female='F'),selected=c('M','F')),
                           uiOutput('doses'),
                           uiOutput('subjects'),
                           uiOutput('days'),
                           conditionalPanel(condition='input.summary=="Individual Subjects"',
                                            radioButtons('plotBy','Plot by:',c('Subject','Day'))
                           )
              ),
              mainPanel(width=9,
                        tabsetPanel(
                          tabPanel('Tables',
                                   withSpinner(uiOutput('tables'),type=5)
                          ),
                          tabPanel('Figures',
                                   withSpinner(uiOutput('plots'),type=5)
                          ),
                          tabPanel('Source Data',
                                   tabsetPanel(
                                     tabPanel('SEND Domains',
                                              withSpinner(uiOutput('SENDdomains'),type=5)
                                     ),
                                     tabPanel('DEFINE',
                                              withSpinner(htmlOutput('define'),type=5)
                                     ),
                                     tabPanel('README',
                                              column(11,
                                                     includeMarkdown('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/send/CDISC-Safety-Pharmacology-POC/readme.txt')
                                              )
                                     )
                                   )
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
                                          br(),br(),
                                          h4('The source code for this R Shiny application is also publicly availalble at:'),
                                          tags$a(href='https://github.com/phuse-org/phuse-scripts/tree/master/contributed/Nonclinical/R/Safety%20Pharmacology%20Pilot',
                                                 'https://github.com/phuse-org/phuse-scripts/tree/master/contributed/Nonclinical/R/Safety%20Pharmacology%20Pilot'),
                                          br(),br()
                                   )
                          )
                        )
              )
            )
  )
)

# Run Shiny App
shinyApp(ui = ui, server = server)
