# This application can be run for free on a public server at the following address:
# https://phuse-nonclinical-scripts.shinyapps.io/LBapp/

# Ideas for improvement:
#  - Add subcategory tree (backlog--requires tree package)
#  - Fix transformations on change from baseline (maybe not?)
#  - Add filter to individual plot by animal ID (backlog requires tree package)
#  - Two-way hierarchical clustering
#  - Handle Time-Points within Days

# Recent Improvements Made:
# Plotting Multiple Days and Centering Z-score at Zero (Vaishnavi Methuku)

# Bugs to fix:
# PCA not always displaying data points
# Reloading datasets after visiting another dataset sometimes causes errors

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
library(DT)
library(gplots)

# Get App Directory
HOME <- getwd()

# Functions
convertMenuItem <- function(mi,tabName) {
  mi$children[[1]]$attribs['data-toggle']="tab"
  mi$children[[1]]$attribs['data-value'] = tabName
  mi
}

addUIDep <- function(x) {
  jqueryUIDep <- htmlDependency("jqueryui", "1.10.4", c(href="shared/jqueryui/1.10.4"),
                                script = "jquery-ui.min.js",
                                stylesheet = "jquery-ui.min.css")
  
  attachDependencies(x, c(htmlDependencies(x), list(jqueryUIDep)))
}

gpairs_lower <- function(g){
  g$plots <- g$plots[-(1:g$nrow)]
  g$yAxisLabels <- g$yAxisLabels[-1]
  g$nrow <- g$nrow -1
  
  g$plots <- g$plots[-(seq(g$ncol, length(g$plots), by = g$ncol))]
  g$xAxisLabels <- g$xAxisLabels[-g$ncol]
  g$ncol <- g$ncol - 1
  
  g
}

ggbiplot <- function(pcobj, choices = 1:2, scale = 1, pc.biplot = TRUE, 
                     obs.scale = 1 - scale, var.scale = scale, 
                     groups = NULL, groupName='Groups', shape = NULL, label = NULL, color_ramp=NULL, ellipse = FALSE, ellipse.prob = 0.68, 
                     labels = NULL, labels.size = 3, alpha = 1, 
                     var.axes = TRUE, 
                     circle = FALSE, circle.prob = 0.69, 
                     varname.size = 3, varname.adjust = 1.5, 
                     varname.abbrev = FALSE, ...)
{
  library(ggplot2)
  library(plyr)
  library(scales)
  library(grid)
  
  stopifnot(length(choices) == 2)
  
  # Recover the SVD
  if(inherits(pcobj, 'prcomp')){
    nobs.factor <- sqrt(nrow(pcobj$x) - 1)
    d <- pcobj$sdev
    u <- sweep(pcobj$x, 2, 1 / (d * nobs.factor), FUN = '*')
    v <- pcobj$rotation
  } else if(inherits(pcobj, 'princomp')) {
    nobs.factor <- sqrt(pcobj$n.obs)
    d <- pcobj$sdev
    u <- sweep(pcobj$scores, 2, 1 / (d * nobs.factor), FUN = '*')
    v <- pcobj$loadings
  } else if(inherits(pcobj, 'PCA')) {
    nobs.factor <- sqrt(nrow(pcobj$call$X))
    d <- unlist(sqrt(pcobj$eig)[1])
    u <- sweep(pcobj$ind$coord, 2, 1 / (d * nobs.factor), FUN = '*')
    v <- sweep(pcobj$var$coord,2,sqrt(pcobj$eig[1:ncol(pcobj$var$coord),1]),FUN="/")
  } else if(inherits(pcobj, "lda")) {
    nobs.factor <- sqrt(pcobj$N)
    d <- pcobj$svd
    u <- predict(pcobj)$x/nobs.factor
    v <- pcobj$scaling
    d.total <- sum(d^2)
  } else {
    stop('Expected a object of class prcomp, princomp, PCA, or lda')
  }
  
  # Scores
  choices <- pmin(choices, ncol(u))
  df.u <- as.data.frame(sweep(u[,choices], 2, d[choices]^obs.scale, FUN='*'))
  
  # Directions
  v <- sweep(v, 2, d^var.scale, FUN='*')
  df.v <- as.data.frame(v[, choices])
  
  names(df.u) <- c('xvar', 'yvar')
  names(df.v) <- names(df.u)
  
  if(pc.biplot) {
    df.u <- df.u * nobs.factor
  }
  
  # Scale the radius of the correlation circle so that it corresponds to 
  # a data ellipse for the standardized PC scores
  r <- sqrt(qchisq(circle.prob, df = 2)) * prod(colMeans(df.u^2))^(1/4)
  
  # Scale directions
  v.scale <- rowSums(v^2)
  df.v <- r * df.v / sqrt(max(v.scale))
  
  # Change the labels for the axes
  if(obs.scale == 0) {
    u.axis.labs <- paste('standardized PC', choices, sep='')
  } else {
    u.axis.labs <- paste('PC', choices, sep='')
  }
  
  # Append the proportion of explained variance to the axis labels
  u.axis.labs <- paste(u.axis.labs, 
                       sprintf('(%0.1f%% explained var.)', 
                               100 * pcobj$sdev[choices]^2/sum(pcobj$sdev^2)))
  
  # Score Labels
  if(!is.null(labels)) {
    df.u$labels <- labels
  }
  
  # Grouping variable
  if(!is.null(groups)) {
    df.u$groups <- groups
  }
  
  # Shape variable
  if (!is.null(shape)) {
    df.u$shape <- shape
  }
  
  # Shape variable
  if (!is.null(label)) {
    df.u$label <- label
  }
  
  # Variable Names
  if(varname.abbrev) {
    df.v$varname <- abbreviate(rownames(v))
  } else {
    df.v$varname <- rownames(v)
  }
  
  # Variables for text label placement
  df.v$angle <- with(df.v, (180/pi) * atan(yvar / xvar))
  df.v$hjust = with(df.v, (1 - varname.adjust * sign(xvar)) / 2)
  
  # Base plot
  g <- ggplot(data = df.u, aes(x = xvar, y = yvar)) + 
    xlab(u.axis.labs[1]) + ylab(u.axis.labs[2]) + coord_equal()
  
  if(var.axes) {
    # Draw circle
    if(circle) 
    {
      theta <- c(seq(-pi, pi, length = 50), seq(pi, -pi, length = 50))
      circle <- data.frame(xvar = r * cos(theta), yvar = r * sin(theta))
      g <- g + geom_path(data = circle, color = muted('white'), 
                         size = 1/2, alpha = 1/3)
    }
    
    # Draw directions
    g <- g +
      geom_segment(data = df.v,
                   aes(x = 0, y = 0, xend = xvar, yend = yvar),
                   arrow = arrow(length = unit(1/2, 'picas')), 
                   color = muted('red'))
  }
  
  # Draw either labels or points
  if(!is.null(df.u$labels)) {
    if(!is.null(df.u$groups)) {
      if (!is.null(df.u$shape)) {
        g <- g + geom_text(aes(label = labels, color = groups, shape = shape), 
                           size = labels.size)
      } else {
        g <- g + geom_text(aes(label = labels, color = groups), 
                           size = labels.size)
      }
    } else {
      g <- g + geom_text(aes(label = labels), size = labels.size)      
    }
  } else {
    if(!is.null(df.u$groups)) {
      if (!is.null(df.u$shape)) {
        if (!is.null(df.u$label)) {
          g <- g + geom_point(aes(color = groups, shape = shape,label=label), alpha = alpha, size=3) +
            scale_color_manual(name=groupName,values=color_ramp) + scale_shape_manual(name='Treatment,Sex',values=c(19,17))
        } else {
          g <- g + geom_point(aes(color = groups, shape = shape), alpha = alpha, size=3) +
            scale_color_manual(name=groupName,values=color_ramp) + scale_shape_manual(name='Treatment,Sex',values=c(19,17))
        }
      } else {
        g <- g + geom_point(aes(color = groups), alpha = alpha)
      }
    } else {
      g <- g + geom_point(alpha = alpha)      
    }
  }
  
  # Overlay a concentration ellipse if there are groups
  if(!is.null(df.u$groups) && ellipse) {
    theta <- c(seq(-pi, pi, length = 50), seq(pi, -pi, length = 50))
    circle <- cbind(cos(theta), sin(theta))
    
    ell <- ddply(df.u, 'groups', function(x) {
      if(nrow(x) <= 2) {
        return(NULL)
      }
      sigma <- var(cbind(x$xvar, x$yvar))
      mu <- c(mean(x$xvar), mean(x$yvar))
      ed <- sqrt(qchisq(ellipse.prob, df = 2))
      data.frame(sweep(circle %*% chol(sigma) * ed, 2, mu, FUN = '+'), 
                 groups = x$groups[1])
    })
    names(ell)[1:2] <- c('xvar', 'yvar')
    g <- g + geom_path(data = ell, aes(color = groups, group = groups))
  }
  
  # Label the variable axes
  if(var.axes) {
    g <- g + 
      geom_text(data = df.v, 
                aes(label = varname, x = xvar, y = yvar, 
                    angle = angle, hjust = hjust), 
                color = 'darkred', size = varname.size)
  }
  # Change the name of the legend for groups
  # if(!is.null(groups)) {
  #   g <- g + scale_color_brewer(name = deparse(substitute(groups)), 
  #                               palette = 'Dark2')
  # }
  
  # TODO: Add a second set of axes
  
  return(g)
}

signif_df <- function(df, digits) {
  nums <- vapply(df, is.numeric, FUN.VALUE = logical(1))
  
  df[,nums] <- round(df[,nums], digits = 10)
  df[,nums] <- signif(df[,nums], digits = digits)
  
  (df)
}

# Check if app is running on local windows laptop or linux shiny server
homePath <- getwd()
if (substr(homePath,1,2)=='C:') {
  Local <- T
} else {
  Local <- F
}

# Set this flag to download latest version of functions from PhUSE GitHub
Update <- F

# Source Functions
if (Local == T) {
  if (Update==T) {
    download.file('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R','Functions/Functions.R')
    download.file('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/groupSEND.R','Functions/groupSEND.R')
  }
  
  # Get GitHub Password (if possible)
  if (file.exists('~/passwordGitHub.R')) {
    source('~/passwordGitHub.R')
    Authenticate <- TRUE
  } else {
    Authenticate <- FALSE
  }
}
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/groupSEND.R')

# Set Local GitHub Repo
GitHubPath <- '~/PhUSE/Git/phuse-scripts/data/send'
DatasetsPath <- 'Datasets'

# Setup Plot Color Ramp
my_color_palette <- colorRampPalette(c('green','red'),space = "Lab")

# Set Reactive Values
values <- reactiveValues()
values$path <- NULL
values$selectedTests <- NULL
values$dayOrder <- NULL
values$treatmentOrder <- NULL
values$testDictionaryCodes <- NULL
values$testDictionaryTests <- NULL
values$testDictionaryUnits <- NULL
values$day <- NULL
values$treatment <- NULL

# Set Heights and Widths
sidebarWidth <- '300px'
plotHeight <- '575px'

# Set Number of Significant Figures Places to Display in Tables
nSigFigs <- 3

# Set Maximum Number of Tests to Plot
max_plots <- 100

server <- function(input, output, session) {
  #options(shiny.maxRequestSize=1000*1024^2)
  
  # Store Client Data Regarding Height and Width of Plot Containers
  cdata <- session$clientData
  
  output$dataSource <- renderUI({
    if (Local == T) {
      selectInput('dataSource','Select Data Source:', c('GitHub'))
    # } else {
    #   selectInput('dataSource','Select Data Source:',c('Datasets'))
    }
  })
  
  # Create Drop Down to Select Studies from PhUSE GitHub Repo
  output$selectStudy <- renderUI({
    req(input$dataSource)
    if (input$dataSource == 'GitHub') {
      if (Authenticate == TRUE) {
        Req <- GET(paste('https://api.github.com/repos/phuse-org/phuse-scripts/contents/data/send'),
                   authenticate(userGitHub,passwordGitHub))
      } else {
        Req <- GET(paste('https://api.github.com/repos/phuse-org/phuse-scripts/contents/data/send'))
      }
      contents <- content(Req,as='parsed')
      GitHubStudies <- NULL
      for (i in seq(length(contents))) {
        GitHubStudies[i] <- strsplit(contents[[i]]$path,'/send/')[[1]][2]
      }
    } else if (input$dataSource == 'Datasets') {
      #print(getwd())
      if(grepl('Datasets', getwd(), fixed = TRUE)) {
        #setwd(paste('..', .Platform$file.sep, '..', sep = ''))
        setwd(HOME)
      }        
      #print(getwd())
      GitHubStudies <- list.dirs('Datasets',full.names=F,recursive=F)
    }
    selectInput('selectStudy',label='Select Study:',choices = GitHubStudies,selected='PDS')
  })
  
  # COMMENTED OUT FOR NOW unitl I allow local file upload
  #
  # # Handle Study Selection
  # observeEvent(ignoreNULL = TRUE,eventExpr = input$chooseBWfile,
  #              handlerExpr = {
  #                if (input$chooseBWfile >= 1) {
  #                  File <- file.choose()
  # 
  #                  # If file was chosen, update
  #                  if (length(File>0)) {
  #                    path <- dirname(File)
  # 
  #                    # save for next run if good one selected
  #                    if (dir.exists(path)) {
  #                      values$path <- path
  #                    }
  #                  }
  #                }
  #              }
  # )
  # 
  # # Print Current Study Folder Location
  # output$bwFilePath <- renderText({
  #   req(values$path)
  #   values$path
  # })
  
  # Load Dataset
  loadData <- reactive({
    req(input$selectStudy)
    if (input$dataSource=='GitHub') {
      values$path <- paste0('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/send/',input$selectStudy)
    } else if (input$dataSource=='Datasets') {
      values$path <- paste0(HOME,'/Datasets/',input$selectStudy)
    }
    path <- values$path
    
    withProgress({
      if (input$dataSource=='Datasets') {
        print(path)
        setwd(path)
        if (length(list.files(pattern='*.xpt'))>0) {
          Dataset <- load.xpt.files(domainsOfInterest = c('dm','ex','tx','pp','ta','se','ds','lb'),showProgress=T)
        } else if (length(list.files(pattern='*.csv'))>0) {
          Dataset <- load.csv.files(showProgress=T)
        } else {
          stop('No .xpt or .csv files to load!')
        }
      } else if (input$dataSource=='GitHub') {
        if (Local == T) {
          StudyDir <- paste0('data/send/',input$selectStudy)
          if (Authenticate==T) {
            Dataset <- load.GitHub.xpt.files(studyDir=StudyDir,showProgress=T,
                                             authenticate=TRUE,User=userGitHub,Password=passwordGitHub)
          } else {
            Dataset <- load.GitHub.xpt.files(studyDir=StudyDir,showProgress=T)
          }
        } else {
          StudyDir <- paste0('Datasets/',input$selectStudy)
          setwd(StudyDir)
          if (length(list.files(pattern='*.xpt'))>0) {
            Dataset <- load.xpt.files(showProgress=T)
          } else if (length(list.files(pattern='*.csv'))>0) {
            Dataset <- load.csv.files(showProgress=T)
          } else {
            stop('No .xpt or .csv files to load!')
          }
        }
      }
      
      setProgress(value=1,message='Processing Data...')
      isolate({
        testCodes <- levels(Dataset$lb$LBTESTCD)
        for (i in seq(length(testCodes))) {
          values$testDictionaryCodes[i] <- testCodes[i]
          index <- which(Dataset$lb$LBTESTCD==testCodes[i])[1]
          values$testDictionaryTests[i] <- levels(Dataset$lb$LBTEST[index])[Dataset$lb$LBTEST[index]]
          values$testDictionaryUnits[i] <- levels(Dataset$lb$LBSTRESU[index])[Dataset$lb$LBSTRESU[index]]
        }
      })
      groupedData <- groupSEND(Dataset,'lb')
      #print(groupedData)
      index <- which((groupedData$LBSTRESU!='')&(is.null(groupedData$LBSTRESU)==F))
      groupedData <- groupedData[index,]
      groupedData$CATTEST <- paste(substr(groupedData$LBCAT,1,4),groupedData$LBTESTCD,sep='_')
      print(head(groupedData))
      for (subject in unique(groupedData$USUBJID)) {
        index <- which(groupedData$USUBJID==subject)

        testTable <- table(groupedData$LBTESTCD[index])
        testTable1 <- table(groupedData$LBSPEC[index])
        testTable2 <- table(groupedData$LBDTC[index])
        maxTest <- unique(groupedData$LBSTRESC[index])
        #lbstresTable <- unique(groupedData$LBSTRESC[index])
        # print('lbstresTable')
        # print(lbstresTable)
        overTestIndex <- which(testTable>maxTest)
        overTests <- names(testTable[overTestIndex])
      for (test in overTests) {
        testIndex <- which(groupedData$LBTESTCD==test)
        groupedData <- groupedData[testIndex,]
       }
      }
      
       for (subject in unique(groupedData$USUBJID)) {
         #print(head(groupedData))
         # print(subject)
         index <- which(groupedData$USUBJID==subject)
         testTable <- table(groupedData$CATTEST[index])
         maxTest <- length(unique(groupedData$VISITDY[index]))
         # print(maxTest)
         # print(index)
         overTestIndex <- which(testTable>maxTest)
         overTests <- names(testTable[overTestIndex])
          #print(overTests)
          for (test in overTests) {
            testIndex <- which(groupedData$CATTEST==test)
            groupedData <- groupedData[-testIndex,]
          }
        }

      
      for (test in unique(groupedData$CATTEST)) {
        index <- which(groupedData$CATTEST==test)
        if ((length(which(is.na(groupedData$LBSTRESN[index])==T))>(length(index)*.5))|
            (length(index)==1)){
          groupedData <- groupedData[-index,]
        }
      }
      testDays <- sort(as.numeric(unique(groupedData$VISITDY)),decreasing=F)
      for (i in seq(length(testDays))) {
        if (i > 1) {
          if (testDays[i]==(testDays[i-1]+1)) {
            index <- which(groupedData$VISITDY==testDays[i])
            groupedData$VISITDY[index] <- testDays[i-1]
          }
        }
      }
      values$dayOrder <- as.character(sort(as.numeric(unique(groupedData$VISITDY))))
      doses <- paste0(' ',levels(factor(groupedData$Dose)))
      DoseN <- NULL
      for(i in seq(length(doses))){
        DoseN[i] <- as.numeric(unlist(strsplit(doses[i],' '))[2])
      }
      doses <- doses[order(DoseN)]
      treatmentOrder <- NULL
      for (dose in doses) {
        treatmentOrder[length(treatmentOrder)+1] <- grep(dose,levels(factor(groupedData$TreatmentDose)),value=T)
      }
      values$treatmentOrder <- treatmentOrder
    },
      message='Loading Data...')
     return(groupedData)
  })
  
  # Display Test Categories
  output$testCategories <- renderUI({
    Data <- loadData()
    #print("************load data *********")
    #print(Data)
    testCategories <- sort(unique(Data$LBCAT))
    checkboxGroupInput('testCategories','Select Test Categories:',testCategories,selected=testCategories[1])
  })
  
  # Display Test Selection
  output$tests <- renderUI({
    # req(input$testCategories)
    Data <- loadData()
    index <- which(Data$LBCAT %in% input$testCategories)
    Data <- Data[index,]
    tests <- levels(factor(Data$LBTESTCD))
    for (test in tests) {
      index <- which(Data$LBTESTCD==test)
      uniqueTests <- unique(Data$CATTEST[index])
      if (length(uniqueTests)>1) {
        count <- 1
        for (uniqueTest in uniqueTests) {
          if (count == 1) {
            tests[which(tests==test)] <- uniqueTest
          } else {
            tests[length(tests)+1] <- uniqueTest
          }
          count <- count + 1
        }
      }
    }
    if (!is.null(values$selectedTests)) {
      values$selectedTests <- tests
    }
    if (is.null(input$testCategories)) {
      values$selectedTests <- tests
    }
    addUIDep(selectizeInput('tests',label='Select Tests to Visualize:',choices=tests,
                            selected=values$selectedTests,
                            multiple=TRUE,width='100%',options=list(plugins=list('drag_drop','remove_button'))))
  })
  
  # Clear All Functionality
  observeEvent(ignoreNULL=TRUE,eventExpr=input$clearTests,
               handlerExpr={values$selectedTests <- NULL})
  
  # Display All Functionality
  observeEvent(ignoreNULL=TRUE,eventExpr=input$displayTests,
               handlerExpr={values$selectedTests <- 'all'})
  
  # Display Day Selection
  output$day <- renderUI({
    Data <- loadData()
    dayList <- as.list(c(unique(Data$VISITDY)))
    checkboxGroupInput('day',label='Select Day:',choices=dayList,selected=dayList)
  })
  
  # Display Treatment Selection
  output$treatment <- renderUI({
    Data <- loadData()
    treatmentList <- as.list(c(unique(Data$TreatmentDose)))
    checkboxGroupInput('treatment',label='Select Treatment:',choices=treatmentList,selected=treatmentList)
  })
  
  # Track Day and Treatment Selections
  observe({
    values$day <- input$day
    values$treatment <- input$treatment
  })
  
  # Display Control Group Selection
  output$selectControl <- renderUI({
    req(values$treatmentOrder)
    radioButtons('selectControl','Select Control Group:',choices=values$treatmentOrder)
  })
  
  # Transform Data
  transformData <- reactive({
    Data <- loadData()
    if (!is.null(values$day)) {
      dayIndex <- which(Data$VISITDY %in% as.numeric(values$day))
    }
    if (!is.null(values$treatment)) {
      treatmentIndex <- which(Data$TreatmentDose %in% values$treatment)
      if (!is.null(values$day)) {
        index <- intersect(dayIndex,treatmentIndex)
      } else {
        index <- treatmentIndex
      }
    } else {
      if (!is.null(values$day)) {
        index <- dayIndex
      }
    }
    if ((!is.null(values$day))|(!is.null(values$treatment))) {
      Data <- Data[index,]
    }
    Data <- Data[which(Data$LBCAT %in% input$testCategories),]
    tests <- input$tests
    CATTESTs <- grep('_',tests,value = T)
    CATTESTindex <- which(Data$CATTEST %in% CATTESTs)
    TESTCDs <- grep('_',tests,value=T,invert = T)
    TESTCDindex <- which(Data$LBTESTCD %in% TESTCDs)
    Data$CATTEST[TESTCDindex] <- levels(Data$LBTESTCD[TESTCDindex])[Data$LBTESTCD[TESTCDindex]]
    testIndex <- union(CATTESTindex,TESTCDindex)
    Data <- Data[testIndex,]
    #print(head(Data))
    Data <- dcast(Data,USUBJID+TreatmentDose+Sex+VISITDY~CATTEST,value.var='LBSTRESN')
    #print(head(Data))
    colnames(Data)[1:4] <- c('ID','Treatment','Sex','Day')
    parameterCols <- colnames(Data)[5:ncol(Data)]
    if (input$changeFromBaseline==T) {
      baselineDay <- sort(Data$Day,decreasing = F)[1]
      baselineDataIndex <- which(Data$Day==baselineDay)
      baselineData <- Data[baselineDataIndex,]
      count <- 0
      for (id in levels(Data$ID)) {
        index <- which(Data$ID==id)
        tmpData <- Data[index,]
        baselineIndex <- which(tmpData$Day==baselineDay)
        notBaselineIndex <- which(tmpData$Day!=baselineDay)
        for (i in notBaselineIndex) {
          count <- count + 1
          if (count == 1) {
            transformedData <- tmpData[i,]
          } else {
            transformedData[count,] <- tmpData[i,]
          }
          for (col in parameterCols) {
            transformedData[count,col] <- tmpData[i,col]-tmpData[baselineIndex,col]
          }
        }
      }
      Data <- transformedData
    }
    transformedData <- Data
    if (input$transformation == 'none') {
      return(transformedData)
    } else {
      if ((input$transformation %in% c('percentChange','zScore'))&(input$changeFromBaseline==F)) {
        #print(input$transformation)
        #print(input$selectControl)
        if (is.null(input$selectControl)) {
          index <- which(Data$Treatment==values$treatmentOrder[1])
        } else {
          index <- which(Data$Treatment==input$selectControl)
        }
      } else {
        index <- seq(nrow(Data))
      }
      for (col in parameterCols) {
        for (i in seq(nrow(Data))) {
          if ((input$transformation=='percentChange')&(input$changeFromBaseline==T)) {
            sex <- Data$Sex[i]
            sexIndex <- which(baselineData$Sex==sex)
            treatment <- Data$Treatment[i]
            treatmentIndex <- which(baselineData$Treatment==treatment)
            Index <- intersect(sexIndex,treatmentIndex)
          } else {
            sex <- Data$Sex[i]
            sexIndex <- which(Data$Sex[index]==sex)
            day <- Data$Day[i]
            dayIndex <- which(Data$Day[index]==day)
            Index <- index[intersect(sexIndex,dayIndex)]
          }
          if (input$transformation=='zScore') {
            if ((sd(Data[Index,col],na.rm=T) > 0) & (!is.na(sd(Data[Index,col],na.rm=T)))) {
              controlMean <- mean(Data[Index,col],na.rm=T)
              transformedData[i,col] <- (Data[i,col]-controlMean)/sd(Data[Index,col],na.rm=T)
            } else {
              transformedData[i,col] <- NA
            }
          } else {
            if (input$changeFromBaseline==T) {
              transformedData[i,col] <- Data[i,col]/mean(baselineData[Index,col])*100
            } else {
              controlMean <- mean(Data[Index,col],na.rm=T)
              transformedData[i,col] <- (Data[i,col]-controlMean)/controlMean*100
            }
          }
        }
      }
      return(transformedData)
    }
    return(transformedData)
  })
  
  # Process Data
  longData <- reactive({
    Data <- transformData()
    DataLong <- melt(Data,id=c('Treatment','ID','Sex','Day'))
    parameterIndex <- which(DataLong$variable %in% input$tests)
    DataLong <- DataLong[parameterIndex,]
    DataLong$variable <- factor(DataLong$variable,levels=input$tests)
    if (input$sex != '') {
      DataLong <- DataLong[which(DataLong$Sex==input$sex),]
      DataLong$Sex <- factor(DataLong$Sex,levels = input$sex)
    }

    if (input$filterBy=='Day') {
      if (length(input$day) != 1) {
        treatmentDay <- paste(DataLong$Treatment,DataLong$Day)
        treatmentDayOrder <- NULL
        for (treatment in values$treatmentOrder) {
          for (day in values$dayOrder) {
            treatmentDayOrder <- c(treatmentDayOrder,paste(treatment,day))
          }
        }
         DataLong$Treatment <- factor(treatmentDay,levels=treatmentDayOrder)
        treatmentLevels <- treatmentDayOrder
        treatmentLevelsSplit <- strsplit(x = treatmentLevels,split = ' ')
        treatmentTable <- table(unlist(lapply(lapply(treatmentLevelsSplit,head,-1),paste,collapse=' ')))
        for (i in seq(length(input$tests))) {
          for (j in seq(length(treatmentTable))) {
            treatmentDay <- c(treatmentDay,paste(rep(' ',j),collapse=''))
            newRow <- cbind(paste(rep(' ',j),collapse=''),levels(DataLong$ID)[1],levels(DataLong$Sex)[1],DataLong$Day[1],input$tests[i],NA)
            colnames(newRow) <- colnames(DataLong)
            if (j > 1) {
              newRows <- rbind(newRows,newRow)
            } else {
              newRows <- newRow
            }
          }
          DataLong <- rbind(DataLong,newRows)
        }
        DataLong$value <- as.numeric(DataLong$value)
        print(treatmentTable)
        treatmentTableLength <- length(treatmentTable)
        for (i in seq(treatmentTableLength)) {
          if (i == 1) {
            newTreatmentLevels <- c(treatmentLevels[seq(treatmentTable[i])])
            treatmentTableCount <- treatmentTable[i]
          } else {
            newTreatmentLevels <- c(newTreatmentLevels,paste(rep(' ',i),collapse=''),treatmentLevels[seq((treatmentTableCount+1),(treatmentTableCount+treatmentTable[i]))])
            treatmentTableCount <- treatmentTableCount + treatmentTable[i]
          }
          print(newTreatmentLevels)
        }
        #DataLong$Treatment <- factor(treatmentDay,levels=c(treatmentLevels[seq(treatmentTable[1])],'',treatmentLevels[seq((treatmentTable[1]+1),(treatmentTable[1]+treatmentTable[2]))]))
        print(newTreatmentLevels)
        DataLong$Treatment <- factor(treatmentDay,levels=newTreatmentLevels)
        print(levels(DataLong$Treatment))
      } else {
        variableOrder <- NULL
        for (i in seq(nrow(DataLong))) {
          variableOrder[i] <- which(input$tests==DataLong$variable[i])
        }
        DataLong <- DataLong[order(variableOrder),]
        DataLong$Treatment <- factor(DataLong$Treatment,levels=values$treatmentOrder)
      }
    }
    if (input$filterBy=='Treatment') {
      if (length(input$treatment) != 1) {
        dayTreatment <- paste(DataLong$Day,DataLong$Treatment)
        dayTreatmentOrder <- NULL
        for (day in values$dayOrder) {
          for (treatment in values$treatmentOrder) {
            dayTreatmentOrder <- c(dayTreatmentOrder,paste(day,treatment))
          }
        }
        # DataLong$Day <- factor(dayTreatment,levels=dayTreatmentOrder)
        dayLevels <- dayTreatmentOrder
        dayLevelsSplit <- strsplit(x = dayLevels,split = ' ')
        dayTable <- table(unlist(lapply(dayLevelsSplit,`[[`,1)))
        for (i in seq(length(input$tests))) {
          for (j in seq(length(dayTable))) {
            dayTreatment <- c(dayTreatment,paste(rep(' ',j),collapse=''))
            newRow <- cbind(DataLong$Treatment[1],levels(DataLong$ID)[1],levels(DataLong$Sex)[1],paste(rep(' ',j),collapse=''),input$tests[i],NA)
            colnames(newRow) <- colnames(DataLong)
            if (j > 1) {
              newRows <- rbind(newRows,newRow)
            } else {
              newRows <- newRow
            }
          }
          DataLong <- rbind(DataLong,newRows)
        }
        DataLong$value <- as.numeric(DataLong$value)
        dayTableLength <- length(dayTable)
        for (i in seq(dayTableLength)) {
          if (i == 1) {
            newDayLevels <- c(dayLevels[seq(dayTable[i])])
            dayTableCount <- dayTable[i]
          } else {
            newDayLevels <- c(newDayLevels,paste(rep(' ',i),collapse=''),dayLevels[seq((dayTableCount+1),(dayTableCount+dayTable[i]))])
            dayTableCount <- dayTableCount + dayTable[i]
          }
        }
        # DataLong$Day <- factor(dayTreatment,levels=c(dayLevels[seq(dayTable[1])],'',dayLevels[seq((dayTable[1]+1),(dayTable[1]+dayTable[2]))]))
        DataLong$Day <- factor(dayTreatment,levels=newDayLevels)
        DataLong$Treatment <- factor(DataLong$Treatment, levels = values$treatmentOrder)
      } else {
        variableOrder <- NULL
        for (i in seq(nrow(DataLong))) {
          variableOrder[i] <- which(input$tests==DataLong$variable[i])
        }
        DataLong$ID <- as.factor(paste(DataLong$Day,DataLong$ID))
        DataLong <- DataLong[order(variableOrder,DataLong$Day),]
        DataLong$Day <- factor(DataLong$Day,levels=values$dayOrder)
      }
    }
    return(DataLong)
  })
  
  # Display Individual Animal Data Table
  output$individualTable <- DT::renderDataTable({
    if (!is.null(input$tests)) {
      # longData <- longData()
      # tmp <- NULL
      # if (input$filterBy=='Day') {
      #   groupBy <- 'Treatment'
      #   if (length(unique(longData$Day))!=1) {
      #     for (i in seq(nrow(longData))) {
      #       Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
      #       tmp[i] <- paste(Tmp[-length(Tmp)],collapse=' ')
      #     }
      #   } else {
      #     tmp <- longData[[groupBy]]
      #   }
      #   longData[[groupBy]] <- factor(tmp,levels=values$treatmentOrder)
      #   longData[[groupBy]] <- as.factor(tmp)
      # } else {
      #   groupBy <- 'Day'
      #   for (i in seq(nrow(longData))) {
      #     Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
      #     tmp[i] <- Tmp[1]
      #   }
      #   longData[[groupBy]] <- as.factor(tmp)
      # }
      # Data <- dcast(longData,Treatment+ID+Sex+Day~variable)
      # IDindex <- which(colnames(Data)=='ID')
      # groupByIndex <- which(colnames(Data)==groupBy)
      # notIndex <- which((colnames(Data)!='ID')&(colnames(Data)!=groupBy))
      # index <- c(IDindex,groupByIndex,notIndex)
      # Data <- Data[,index]
      # Data <- Data[order(Data[[groupBy]]),]
      Data <- transformData()
      Data <- signif_df(Data,digits=nSigFigs)
      Data
    }
  },options=list(autoWidth=T,scrollX=T,pageLength=10,paging=T,searching=T,
                 columnDefs=list(list(className='dt-center',width='100px',targets=seq(0,3)))),
  rownames=F)
  
  # Display Group Mean Data Table
  output$meanTable <- DT::renderDataTable({
    if (!is.null(input$tests)) {
      longData <- longData()
      tmp <- NULL
      if (input$filterBy=='Day') {
        groupBy <- 'Treatment'
        if (length(unique(longData$Day))!=1) {
          for (i in seq(nrow(longData))) {
            Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
            tmp[i] <- paste(Tmp[-length(Tmp)],collapse=' ')
          }
        } else {
          tmp <- longData[[groupBy]]
        }
        longData[[groupBy]] <- factor(tmp,levels=values$treatmentOrder)
      } else {
        groupBy <- 'Day'
        for (i in seq(nrow(longData))) {
          Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
          tmp[i] <- Tmp[1]
        }
        longData[[groupBy]] <- as.factor(tmp)
      }
      ############################
      meanData <- createMeansTable(longData,'value',c('variable','Treatment','Sex','Day'))
      colnames(meanData)[1] <- 'Test'
      groupByIndex <- which(colnames(meanData)==groupBy)
      notGroupByIndex <- which(colnames(meanData)!=groupBy)
      index <- c(notGroupByIndex[1],groupByIndex,notGroupByIndex[2:length(notGroupByIndex)])
      meanData <- meanData[,index]
      meanData <- meanData[order(meanData$Test,meanData[[groupBy]]),]
      colnames(meanData) <- c('Test',colnames(meanData)[2:(length(colnames(meanData))-4)],'Mean','Standard Deviation','Standard Error of Mean','N')
      meanData <- signif_df(meanData,digits=nSigFigs)
      meanData
    }
  },options=list(autoWidth=T,scrollX=T,pageLength=10,paging=T,searching=T,
                 columnDefs=list(list(className='dt-center',width='100px',targets=seq(0,7)))),
  rownames=F)
  
  # Display Bar Graph Figure
  output$barPlot <- renderPlot({
    if (!is.null(input$tests)) {
      Data <- longData()
      if (input$sex != '') {
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Sex','Day'))
      } else {
        Data$Sex <- 'M & F' 
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Sex','Day'))
      }
      if (input$filterBy=='Treatment') {
        groupBy <- 'Day'
        notGroupBy <- 'Treatment'
      } else {
        groupBy <- 'Treatment'
        notGroupBy <- 'Day'
      }
      
      groups2display <- levels(meanData[[groupBy]])
      for (group in groups2display) {
        index <- which(groups2display==group)
        if (group %ni% meanData[[groupBy]]) {
          groups2display <- groups2display[-index]
        }
      }
      splitGroup <- strsplit(groups2display,' ')
      xLabels <- NULL
      for (item in splitGroup) {
        print(item)
        if (length(item)>0) {
          if (groupBy=='Day') {
            xLabels <- c(xLabels,item[1])
          } else {
            xLabels <- c(xLabels,paste(item[-length(item)],collapse=' '))
          }
        } else {
          xLabels <- c(xLabels,'')
        }
      }
      print(xLabels)
      uLabels <- unique(xLabels[grep('[[:alnum:]]',xLabels)])
      for (u in uLabels) {
        index <- which(xLabels==u)
        if (length(index)>1) {
          middlePoint <- floor(ceiling(length(index))/2)
          xLabels[index] <- ''
          if (groupBy=='Day') {
            xLabels[index[middlePoint]] <- paste('Day:',u)
          } else {
            xLabels[index[middlePoint]] <- u
          }
        } else {
          if (groupBy=='Day') {
            xLabels[index] <- paste('Day:',u)
          } else {
            xLabels[index] <- u
          }
        }
      }
      print(xLabels)
      
      N <- length(unique(Data[[notGroupBy]]))
      my_color_ramp <- my_color_palette(N)
      p <- ggplot(data=meanData,aes(x=get(groupBy),y=value_mean,group=get(groupBy),fill=get(notGroupBy), colour= Sex)) +
        geom_bar(position = position_dodge(), stat = 'identity') +
        facet_grid(. ~ variable,scales = 'free') + xlab('Test') + guides(fill=guide_legend(notGroupBy)) +
        scale_x_discrete(breaks=groups2display,labels=xLabels) +
        scale_fill_manual(name=groupBy,values=my_color_ramp) + theme(text = element_text(size=18)) + 
        scale_colour_manual(name='Sex', values='black')
      if (input$filterBy=='Day') {
        p <- p + theme(axis.text.x = element_text(angle = 90))
      }
      if (input$barErrorbars!='none') {
        p <- p + geom_errorbar(aes(ymin=value_mean-get(paste('value',input$barErrorbars,sep='_')),
                                   ymax=value_mean+get(paste('value',input$barErrorbars,sep='_'))),
                               size=.3,width=0.8,position=position_dodge(.9))
      }
      if (input$transformation == 'percentChange') {
        p <- p + ylab('Percent Change from Control Mean (%)')
      } else if (input$transformation == 'zScore') {
        p <- p + ylab('Z-Score')
      } else {
        p <- p + ylab('Raw Value')
      }
      if (input$filterBy=='Treatment') {
        if (length(unique(Data$Treatment))==1) {
          p <- p + ggtitle(paste0('Treatment: ',unique(Data$Treatment)))
        }
      } else {
        if (length(unique(Data$Day))==1) {
          p <- p + ggtitle(paste0('Day: ',unique(Data$Day)))
        }
      }
      print(p)
    }
  })
  
  # Display Point Plot Figure
  output$pointPlot <- renderPlot({
    if (!is.null(input$tests)) {
      Data <- longData()
      if (input$sex == '') {
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Sex','Day'))
      } else {
        #Data$Sex <- 'M & F'
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Sex','Day'))
      }
      if (input$filterBy=='Treatment') {
        groupBy <- 'Day'
        notGroupBy <- 'Treatment'
      } else {
        groupBy <- 'Treatment'
        notGroupBy <- 'Day'
      }
      
      groups2display <- levels(meanData[[groupBy]])
      for (group in groups2display) {
        index <- which(groups2display==group)
        if (group %ni% meanData[[groupBy]]) {
          groups2display <- groups2display[-index]
        }
      }
      splitGroup <- strsplit(groups2display,' ')
      xLabels <- NULL
      for (item in splitGroup) {
        print(item)
        if (length(item)>0) {
          if (groupBy=='Day') {
            xLabels <- c(xLabels,item[1])
          } else {
            xLabels <- c(xLabels,paste(item[-length(item)],collapse=' '))
          }
        } else {
          xLabels <- c(xLabels,'')
        }
      }
      #print(xLabels)
      uLabels <- unique(xLabels[grep('[[:alnum:]]',xLabels)])
      for (u in uLabels) {
        index <- which(xLabels==u)
        if (length(index)>1) {
          middlePoint <- floor(ceiling(length(index))/2)
          xLabels[index] <- ''
          if (groupBy=='Day') {
            xLabels[index[middlePoint]] <- paste('Day:',u)
          } else {
            xLabels[index[middlePoint]] <- u
          }
        } else {
          if (groupBy=='Day') {
            xLabels[index] <- paste('Day:',u)
          } else {
            xLabels[index] <- u
          }
        }
      }
      #print(xLabels)
      N <- length(unique(Data[[notGroupBy]]))
      my_color_ramp <- my_color_palette(N)
      if (input$sex == '') {
        p <- ggplot(data=meanData,aes(x=get(groupBy),y=value_mean,group=get(groupBy),fill=get(notGroupBy),shape=Sex))
      } else {
        p <- ggplot(data=meanData,aes(x=get(groupBy),y=value_mean,group=get(groupBy),fill=get(notGroupBy)))
      }
      p <- p + geom_point(size=3,position=position_dodge(.9),aes(y=value_mean,colour=get(notGroupBy), shape=Sex)) + 
        facet_grid(. ~ variable,scales = 'free') + xlab('Test') + guides(fill=guide_legend(groupBy)) +
        scale_x_discrete(breaks=groups2display,labels=xLabels) + 
        scale_colour_manual(name=groupBy,values=my_color_ramp) + theme(text = element_text(size=18))
      
      if (input$pointErrorbars!='none') {
        p <- p + geom_errorbar(aes(ymin=value_mean-get(paste('value',input$pointErrorbars,sep='_')),
                                   ymax=value_mean+get(paste('value',input$pointErrorbars,sep='_'))),
                               size=.3,width=0.8,position=position_dodge(.9))
      }
      if (input$transformation == 'percentChange') {
        p <- p + ylab('Percent Change from Control Mean (%)')
      } else if (input$transformation == 'zScore') {
        p <- p + ylab('Z-Score')
      } else {
        p <- p + ylab('Raw Value')
      }
      if (input$filterBy=='Treatment') {
        if (length(unique(Data$Treatment))==1) {
          p <- p + ggtitle(paste0('Treatment: ',unique(Data$Treatment)))
        }
      } else {
        if (length(unique(Data$Day))==1) {
          p <- p + ggtitle(paste0('Day: ',unique(Data$Day)))
        }
      }
      print(p)
    }
  })
  
  # Display Mean Line Plot Figure
  # output$meanLinePlot <- renderPlot({
  #   if (!is.null(input$tests)) {
  #     Data <- longData()
  #     if (input$sex == '') {
  #       meanData <- createMeansTable(Data,'value',c('variable','Treatment','Sex','Day'))
  #     } else {
  #       meanData <- createMeansTable(Data,'value',c('variable','Treatment','Day'))
  #     }
  #     if (input$filterBy=='Treatment') {
  #       groupBy <- 'Day'
  #     } else {
  #       groupBy <- 'Treatment'
  #     }
  #     N <- length(unique(Data[[groupBy]]))
  #     my_color_ramp <- my_color_palette(N)
  #     if (input$sex == '') {
  #       p <- ggplot(data=meanData,aes(x=variable,y=value_mean,group=interaction(get(groupBy),Sex),colour=get(groupBy),shape=Sex))
  #     } else {
  #       p <- ggplot(data=meanData,aes(x=variable,y=value_mean,group=get(groupBy),colour=get(groupBy)))
  #     }
  #     p <- p + geom_point(size=3) + geom_line() + xlab('Test') + scale_colour_manual(name=groupBy,values=my_color_ramp) + 
  #       theme(text = element_text(size=18))
  #     if (input$lineErrorbars!='none') {
  #       p <- p + geom_errorbar(aes(ymin=value_mean-get(paste('value',input$lineErrorbars,sep='_')),
  #                                  ymax=value_mean+get(paste('value',input$lineErrorbars,sep='_'))),
  #                              size=.3,width=0.3)
  #     }
  #     if (input$transformation == 'percentChange') {
  #       p <- p + ylab('Percent Change from Control Mean (%)')
  #     } else if (input$transformation == 'zScore') {
  #       p <- p + ylab('Z-Score')
  #     } else {
  #       p <- p + ylab('Raw Value')
  #     }
  #     if (input$filterBy=='Day') {
  #       if (length(unique(Data$Treatment))==1) {
  #         p <- p + ggtitle(paste0('Treatment: ',unique(Data$Treatment)))
  #       }
  #     } else {
  #       if (length(unique(Data$Day))==1) {
  #         p <- p + ggtitle(paste0('Day: ',unique(Data$Day)))
  #       }
  #     }
  #     print(p)
  #   }
  # })
  
  # Display Mean Line Plot Figures
  output$meanPlots <- renderUI({
    plot_output_list <- lapply(seq(length(input$tests)), function(i) {
      meanPlotname <- paste("meanPlot", i, sep="")
      plotOutput(meanPlotname, height = as.numeric(unlist(strsplit(plotHeight,'px'))), width = '100%')
    })
    do.call(tagList, plot_output_list)
  })
  
  # Create Mean Line Plot Figures
  for (i in 1:max_plots) {
    local({
      my_i <- i
      meanPlotname <- paste("meanPlot", my_i, sep="")
      
      output[[meanPlotname]] <- renderPlot({
        if (!is.null(input$tests)) {
          Data <- transformData()
          if (input$sex != '') {
            sexIndex <- which(Data$Sex==input$sex)
            Data <- Data[sexIndex,]
          }
          test <- input$tests[my_i]
          if (input$sex == '') {
            meanData <- createMeansTable(Data,test,c('Treatment','Sex','Day'))
          } else {
            meanData <- createMeansTable(Data,test,c('Treatment','Sex','Day'))
          }
          N <- length(unique(meanData$Treatment))
          my_color_ramp <- my_color_palette(N)
          testName <- values$testDictionaryTests[which(values$testDictionaryCodes==test)]
          testUnit <- values$testDictionaryUnits[which(values$testDictionaryCodes==test)]
          testNameUnit <- paste0(testName,' (',testUnit,')')
          if (input$sex == '') {
            p <- ggplot(data=meanData,aes(x=Day,y=get(paste(test,'mean',sep='_')),group=interaction(Treatment,Sex),colour=Treatment,shape=Sex))
          } else {
            p <- ggplot(data=meanData,aes(x=Day,y=get(paste(test,'mean',sep='_')),group=Treatment,colour=Treatment, shape=Sex))
          }
          p <- p + geom_point(size=3) + geom_line() + ggtitle(testNameUnit) + scale_colour_manual(name='Treatment',values=my_color_ramp) +
            theme(text = element_text(size=18)) + xlab('Day')
          if (input$lineErrorbars!='none') {
            p <- p + geom_errorbar(aes(ymin=get(paste(test,'mean',sep='_'))-get(paste(test,input$lineErrorbars,sep='_')),
                                       ymax=get(paste(test,'mean',sep='_'))+get(paste(test,input$lineErrorbars,sep='_'))),
                                   size=.3,width=0.3)
          }
          if (input$transformation == 'percentChange') {
            p <- p + ylab('Percent Change from Control Mean (%)')
          } else if (input$transformation == 'zScore') {
            p <- p + ylab('Z-Score')
          } else {
            p <- p + ylab(paste0('Raw Value'))
          }
          print(p)
        }
      })
    })
  }
  
  # Display Individual Line Plot Figure
  # output$linePlot <- renderPlotly({
  #   if (!is.null(input$tests)) {
  #     Data <- longData()
  #     if (input$filterBy=='Treatment') {
  #       groupBy <- 'Day'
  #     } else {
  #       groupBy <- 'Treatment'
  #     }
  #     N <- length(unique(Data[[groupBy]]))
  #     my_color_ramp <- my_color_palette(N)
  #     if (input$sex == '') {
  #       p <- ggplot(data=Data,aes(x=variable,y=value,group=ID,colour=get(groupBy),shape=Sex,label=ID))
  #     } else {
  #       p <- ggplot(data=Data,aes(x=variable,y=value,group=ID,colour=get(groupBy),label=ID))
  #     }
  #     p <- p + geom_point(size=3) + geom_path() + xlab('Test') + scale_colour_manual(name=groupBy,values=my_color_ramp) +
  #       theme(text = element_text(size=18))
  #     print(p)
  #     if (input$transformation == 'percentChange') {
  #       p <- p + ylab('Percent Change from Control Mean (%)')
  #     } else if (input$transformation == 'zScore') {
  #       p <- p + ylab('Z-Score')
  #     } else {
  #       p <- p + ylab('Raw Value')
  #     }
  #     if (input$filterBy=='Treatment') {
  #       if (length(unique(Data$Treatment))==1) {
  #         p <- p + ggtitle(paste0('Treatment: ',unique(Data$Treatment)))
  #       }
  #     } else {
  #       if (length(unique(Data$Day))==1) {
  #         p <- p + ggtitle(paste0('Day: ',unique(Data$Day)))
  #       }
  #     }
  #     p <- ggplotly(p,tooltip='label')
  #     p$elementId <- NULL
  #     p
  #   }
  # })
  
  # Display Individual Line Plot Figures
  output$plots <- renderUI({
    plot_output_list <- lapply(seq(length(input$tests)), function(i) {
      plotname <- paste("plot", i, sep="")
      plotlyOutput(plotname, height = as.numeric(unlist(strsplit(plotHeight,'px'))), width = '100%')
    })
    do.call(tagList, plot_output_list)
  })
  
  # Create Individual Line Plot Figures
  for (i in 1:max_plots) {
    local({
      my_i <- i
      plotname <- paste("plot", my_i, sep="")
      
      output[[plotname]] <- renderPlotly({
        if (!is.null(input$tests)) {
          Data <- transformData()
          if (input$sex != '') {
            sexIndex <- which(Data$Sex==input$sex)
            Data <- Data[sexIndex,]
          }
          test <- input$tests[my_i]
          Data$Treatment <- factor(Data$Treatment,levels=values$treatmentOrder)
          if (input$filterBy=='Treatment') {
            groupBy <- 'Day'
          } else {
            groupBy <- 'Treatment'
          }
          N <- length(unique(Data$Treatment))
          my_color_ramp <- my_color_palette(N)
          testName <- values$testDictionaryTests[which(values$testDictionaryCodes==test)]
          testUnit <- values$testDictionaryUnits[which(values$testDictionaryCodes==test)]
          testNameUnit <- paste0(testName,' (',testUnit,')')
          if (input$sex == '') {
            p <- ggplot(data=Data,aes(x=Day,y=get(paste(test,sep='_')),group=ID,colour=Treatment,shape=Sex,label=ID))
          } else {
            p <- ggplot(data=Data,aes(x=Day,y=get(paste(test,sep='_')),group=ID,colour=Treatment,label=ID, shape=Sex))
          }
          p <- p + geom_point(size=2)+geom_path() + ggtitle(testNameUnit) + scale_colour_manual(name=groupBy,values=my_color_ramp) +
            theme(text = element_text(size=12)) + xlab('Day')
          if (input$transformation == 'percentChange') {
            p <- p + ylab('Percent Change from Control Mean (%)')
          } else if (input$transformation == 'zScore') {
            p <- p + ylab('Z-Score')
          } else {
            p <- p + ylab(paste0('Raw Value'))
          }
          p <- ggplotly(p,tooltip='label')
          p$elementId <- NULL
          p
        }
      })
    })
  }
  
  # Display Box Plot Figure
  output$boxPlot <- renderPlot({
    if (!is.null(input$tests)) {
      Data <- longData()
      if (input$filterBy=='Treatment') {
        groupBy <- 'Day'
        notGroupBy <- 'Treatment'
      } else {
        groupBy <- 'Treatment'
        notGroupBy <- 'Day'
      }
      
      groups2display <- levels(Data[[groupBy]])
      for (group in groups2display) {
        index <- which(groups2display==group)
        if (group %ni% Data[[groupBy]]) {
          groups2display <- groups2display[-index]
        }
      }
      splitGroup <- strsplit(groups2display,' ')
      xLabels <- NULL
      for (item in splitGroup) {
        print(item)
        if (length(item)>0) {
          if (groupBy=='Day') {
            xLabels <- c(xLabels,item[1])
          } else {
            xLabels <- c(xLabels,paste(item[-length(item)],collapse=' '))
          }
        } else {
          xLabels <- c(xLabels,'')
        }
      }
      #print(xLabels)
      uLabels <- unique(xLabels[grep('[[:alnum:]]',xLabels)])
      for (u in uLabels) {
        index <- which(xLabels==u)
        if (length(index)>1) {
          middlePoint <- floor(ceiling(length(index))/2)
          xLabels[index] <- ''
          if (groupBy=='Day') {
            xLabels[index[middlePoint]] <- paste('Day:',u)
          } else {
            xLabels[index[middlePoint]] <- u
          }
        } else {
          if (groupBy=='Day') {
            xLabels[index] <- paste('Day:',u)
          } else {
            xLabels[index] <- u
          }
        }
      }
      #print(xLabels)
      N <- length(unique(Data[[notGroupBy]]))
      my_color_ramp <- my_color_palette(N)
      p <- ggplot(data=Data,aes(x=get(groupBy),y=value,group=get(groupBy),fill=get(notGroupBy),colour=Sex, sep= '_')) +
        geom_boxplot() + scale_fill_manual(name=groupBy,values=my_color_ramp) +
        facet_grid(. ~ variable,scales = 'free') + xlab('Test') + guides(fill=guide_legend(notGroupBy)) +
        scale_x_discrete(breaks=groups2display,labels=xLabels) + 
        scale_colour_manual(name='Sex', values='black')+
        theme(text = element_text(size=18))
      if (input$transformation == 'percentChange') {
        p <- p + ylab('Percent Change from Control Mean (%)')
      } else if (input$transformation == 'zScore') {
        p <- p + ylab('Z-Score')
      } else {
        p <- p + ylab('Raw Value')
      }
      if (input$filterBy=='Treatment') {
        if (length(unique(Data$Treatment))==1) {
          p <- p + ggtitle(paste0('Treatment: ',unique(Data$Treatment)))
        }
      } else {
        if (length(unique(Data$Day))==1) {
          p <- p + ggtitle(paste0('Day: ',unique(Data$Day)))
        }
      }
      print(p)
    }
  })
  
  # Display Box Plot with Individual Subject Data Points
  output$boxPlotly <- renderPlotly({
    if (!is.null(input$tests)) {
      Data <- longData()
      if (input$filterBy=='Treatment') {
        groupBy <- 'Day'
        notGroupBy <- 'Treatment'
      } else {
        groupBy <- 'Treatment'
        notGroupBy <- 'Day'
      }
      
      groups2display <- levels(Data[[groupBy]])
      for (group in groups2display) {
        index <- which(groups2display==group)
        if (group %ni% Data[[groupBy]]) {
          groups2display <- groups2display[-index]
        }
      }
      splitGroup <- strsplit(groups2display,' ')
      xLabels <- NULL
      for (item in splitGroup) {
        print(item)
        if (length(item)>0) {
          if (groupBy=='Day') {
            xLabels <- c(xLabels,item[1])
          } else {
            xLabels <- c(xLabels,paste(item[-length(item)],collapse=' '))
          }
        } else {
          xLabels <- c(xLabels,'')
        }
      }
      #print(xLabels)
      uLabels <- unique(xLabels[grep('[[:alnum:]]',xLabels)])
      for (u in uLabels) {
        index <- which(xLabels==u)
        if (length(index)>1) {
          middlePoint <- floor(ceiling(length(index))/2)
          xLabels[index] <- ''
          if (groupBy=='Day') {
            xLabels[index[middlePoint]] <- paste('Day:',u)
          } else {
            xLabels[index[middlePoint]] <- u
          }
        } else {
          if (groupBy=='Day') {
            xLabels[index] <- paste('Day:',u)
          } else {
            xLabels[index] <- u
          }
        }
      }
      #print(xLabels)
      N <- length(unique(Data[[notGroupBy]]))
      my_color_ramp <- my_color_palette(N)
      p <- ggplot(data=Data,aes(x=get(groupBy),y=value,group=get(groupBy),fill=get(notGroupBy),label=ID)) +
        geom_boxplot(outlier.shape='') +facet_grid(. ~ variable,scales = 'free') + xlab('Test') + guides(fill=guide_legend(notGroupBy)) +
        scale_x_discrete(breaks=groups2display,labels=xLabels)  + scale_fill_manual(name=groupBy,values=my_color_ramp) +
        geom_point(aes(fill=get(notGroupBy),shape=Sex),size=2.5,position=position_jitterdodge()) +
        theme(text = element_text(size=18))
      if (input$transformation == 'percentChange') {
        p <- p + ylab('Percent Change from Control Mean (%)')
      } else if (input$transformation == 'zScore') {
        p <- p + ylab('Z-Score')
      } else {
        p <- p + ylab('Raw Value')
      }
      if (input$filterBy=='Day') {
        if (length(unique(Data$Treatment))==1) {
          p <- p + ggtitle(paste0('Treatment: ',unique(Data$Treatment)))
        }
      } else {
        if (length(unique(Data$Day))==1) {
          p <- p + ggtitle(paste0('Day: ',unique(Data$Day)))
        }
      }
      p <- ggplotly(p,height=800,width=cdata$output_boxPlotly_width,tooltip='label') %>% layout(boxmode='group')
      if (input$sex=='') {
        for (i in seq(length(p$x$data)/3)) {
          p$x$data[[i]]$marker$`opacity` <- 0
        }
      } else {
        for (i in seq(length(p$x$data)/2)) {
          p$x$data[[i]]$marker$`opacity` <- 0
        }
      }
      p$elementId <- NULL
      p
    }
  })

  output$heatMap <- renderPlot({

  })
    
  output$scatterPlot <- renderPlot({
    if (!is.null(input$tests)) {
      longData <- longData()
      tmp <- NULL
      if (input$filterBy=='Day') {
        groupBy <- 'Treatment'
        if (length(unique(longData$Day))!=1) {
          for (i in seq(nrow(longData))) {
            Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
            tmp[i] <- paste(Tmp[-length(Tmp)],collapse=' ')
          }
        } else {
          tmp <- longData[[groupBy]]
        }
        longData[[groupBy]] <- factor(tmp,levels=values$treatmentOrder)
        longData[[groupBy]] <- as.factor(tmp)
      } else {
        groupBy <- 'Day'
        for (i in seq(nrow(longData))) {
          Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
          tmp[i] <- Tmp[1]
        }
        longData[[groupBy]] <- as.factor(tmp)
      }
      Data <- dcast(longData,Treatment+ID+Sex+Day~variable)
      IDindex <- which(colnames(Data)=='ID')
      groupByIndex <- which(colnames(Data)==groupBy)
      notIndex <- which((colnames(Data)!='ID')&(colnames(Data)!=groupBy))
      index <- c(IDindex,groupByIndex,notIndex)
      Data <- Data[,index]
      Data <- Data[order(Data[[groupBy]]),]
      Data <- Data[,c(input$tests,'Day','Treatment','Sex','ID')]
      if (input$filterBy=='Treatment') {
        Data$Treatment <- factor(Data$Treatment,levels=values$treatmentOrder)
      } else {
        Data$Day <- factor(Data$Day,levels=values$dayOrder)
      }
      N <- length(values$treatmentOrder)
      my_color_ramp <- my_color_palette(N)
      p <- ggpairs(Data,aes(colour=Treatment,shape=Sex,label=ID),columns=(1:length(input$tests)), legend = 1,
                   lower=list(continuous = wrap('points',size=3)),upper='blank',diag='blank',switch='both')
      for(i in 1:p$nrow) {
        for(j in 1:p$ncol){
          p[i,j] <- p[i,j] + 
            scale_color_manual(values=my_color_ramp[which(values$treatmentOrder %in% unique(Data$Treatment))])  
        }
      }
      p <- gpairs_lower(p)
      #p <- p + theme(legend.position = c(0.8,0.2))
      #p <- ggplotly(p,height=as.numeric(unlist(strsplit(plotHeight,'px'))),width=as.numeric(unlist(strsplit(plotHeight,'px')))*1.5,tooltip='label')   %>% layout(margin=list(r=300), showlegend=TRUE, legend=list(x=100,y=0.5))
      #p$elementId <- NULL
      p
    }
  })
  
  output$PCA <- renderPlot({
    req(input$tests)
    longData <- longData()
    print(head(longData))
    print(table(longData$Day))
    tmp <- NULL
    if (input$filterBy=='Treatment') {
      groupBy <- 'Day'
      if (length(unique(longData$Day))!=1) {
        for (i in seq(nrow(longData))) {
          Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
          tmp[i] <- paste(Tmp[-length(Tmp)],collapse=' ')
        }
      } else {
        tmp <- longData[[groupBy]]
      }
      longData[[groupBy]] <- factor(tmp,levels=values$treatmentOrder)
      longData[[groupBy]] <- as.factor(tmp)
    } else {
      groupBy <- 'Treatment'
      for (i in seq(nrow(longData))) {
        Tmp <- strsplit(as.character(longData[i,groupBy]),' ')[[1]]
        tmp[i] <- Tmp[1]
      }
      longData[[groupBy]] <- as.factor(tmp)
    }
    print(table(longData$Day))
    Data <- dcast(longData,Treatment+ID+Sex+Day~variable,fun.aggregate = mean)
    print(Data)
    if (groupBy=='Day') {
      Data$Treatment <- factor(Data$Treatment,levels=values$treatmentOrder)
    } else {
      Data$Day <- factor(Data$Day,levels=values$dayOrder)
    }
    N <- length(values$treatmentOrder)
    my_color_ramp <- my_color_palette(N)
    pData <- Data[,input$tests]
    print(head(pData))
    rowIndex <- NULL
    for (i in seq(nrow(pData))) {
      naFlag <- F
      for (j in seq(ncol(pData))) {
        if (is.na(pData[i,j])) {
          naFlag <- T
        }
      }
      if (naFlag == F) {
        rowIndex <- c(rowIndex,i)
      }
    }
    print(head(pData))
    pData <- pData[rowIndex,]
    print(head(pData))
    pData.pca <- prcomp(pData,scale. = TRUE)
    Groups <- factor(Data$Treatment[rowIndex],levels=values$treatmentOrder)
    Shape <- Data$Sex[rowIndex]
    Label <- Data$ID[rowIndex]
    
    p <- ggbiplot(pData.pca,obs.scale=1,var.scale=1,groups=Groups,groupName='Treatment',shape=Shape,label=Label,
                  color_ramp=my_color_ramp,ellipse=input$ellipse,ellipse.prob = input$ellipseConf/100,circle=F) +
      theme(text=element_text(size=15))
  
    print(head(pData))
    #p <- ggplotly(p,height=as.numeric(unlist(strsplit(plotHeight,'px'))),width=as.numeric(unlist(strsplit(plotHeight,'px')))*1.25+300,tooltip='label')
    #p$elementId <- NULL
    print(p)
  })
  
  observe({
    if (input$changeFromBaseline==T) {
      isolate(updateRadioButtons(session,'transformation',choiceNames=c('Percent Change from Baseline','Z-Score','None'),
                                 choiceValues=c('percentChange','zScore','none'),selected=input$transformation))
    } else if (input$changeFromBaseline==F) {
      isolate(updateRadioButtons(session,'transformation',choiceNames=c('Percent Change from Control','Z-Score','None'),
                                 choiceValues=c('percentChange','zScore','none'),selected=input$transformation))
    }
  })
  
}

ui <- dashboardPage(
  
  dashboardHeader(title='LB Visualizations',titleWidth=sidebarWidth),
  
  dashboardSidebar(
    
    # Add Scroll Bar to sidebarMenu
    tags$head(
      tags$style(
        HTML(".sidebar {height: 94vh; overflow-y: auto;}")
      )
    ),
    
    width=sidebarWidth,
    sidebarMenu(id='sidebar',
                menuItem('Figures',icon=icon('area-chart'),startExpanded=T,
                         convertMenuItem(menuItem('Box Plot',tabName='boxPlot',icon=icon('cube'),startExpanded = T,
                                                  menuSubItem(icon=NULL,
                                                              checkboxInput('addPoints','Add Individual Data Points?',value=F)                                                       )
                         ),'boxPlot'),
                         convertMenuItem(menuItem('Bar Graph',tabName='barPlot',icon=icon('bar-chart'),
                                                  menuSubItem(icon=NULL,
                                                              radioButtons('barErrorbars',label='Select Type of Error Bars:',
                                                                           choices=list('None'='none','Standard Deviation'='sd','Standard Error of Mean'='se'),
                                                                           selected='se')                                                       )
                         ),'barPlot'),
                         convertMenuItem(menuItem('Point Plot',tabName='pointPlot',icon=icon('genderless'),
                                                  menuSubItem(icon=NULL,
                                                              radioButtons('pointErrorbars',label='Select Type of Error Bars:',
                                                                           choices=list('None'='none','Standard Deviation'='sd','Standard Error of Mean'='se'),
                                                                           selected='se')                                                       )
                         ),'pointPlot'),
                         convertMenuItem(menuItem(text=tags$b('Line Graph',tags$br(),'(Group Means)'),tabName='meanLinePlot',icon=icon('line-chart'),
                                                  menuSubItem(icon=NULL,
                                                              radioButtons('lineErrorbars',label='Select Type of Error Bars:',
                                                                           choices=list('None'='none','Standard Deviation'='sd','Standard Error of Mean'='se'),
                                                                           selected='se')                                                       )
                         ),'meanLinePlot'),
                         menuItem(text=tags$b('Line Graph',tags$br(),'(Individuals)'),tabName='linePlot',icon=icon('random')),
                         menuItem('Scatter Plots',tabName='scatterPlot',icon=icon('braille')),
                         #menuItem('Heat Map',tabName='heatMap',icon=icon('th')),
                         convertMenuItem(menuItem('PCA',tabName='PCA',icon=icon('codepen'),
                                                  menuSubItem(icon=NULL,
                                                              checkboxInput('ellipse','Show Treatment Group Ellipses?',value=F)
                                                  ),
                                                  conditionalPanel(condition='input.ellipse==true',
                                                                   numericInput('ellipseConf','Percent Confidence:',min=0,max=100,value=95,step=5)
                                                  )
                         ),'PCA')
                          
                ),
                menuItem('Tables',icon=icon('table'),startExpanded=T,
                         menuSubItem('Group Means',tabName='meanTable',icon=icon('th-list')),
                         menuSubItem('Individual Data',tabName='individualTable',icon=icon('th')
                         )
                ),
                menuItem('Select Dataset',icon=icon('database'),startExpanded=T,
                         uiOutput('dataSource'),
                         uiOutput('selectStudy'),
                         h5('Study Folder Location:'),
                         verbatimTextOutput('bwFilePath')
                ),
                menuItem('Select Tests',icon=icon('flask'),startExpanded=T,
                         withSpinner(uiOutput('testCategories'),type=7,proxy.height='200px'),
                         withSpinner(uiOutput('tests'),type=7,proxy.height='200px'),
                         actionButton('clearTests',label='Clear All'),
                         actionButton('displayTests',label='Display All')
                ),
                menuItem('Filters',icon=icon('filter'),startExpanded=T,
                         radioButtons('filterBy',label='Sort by Treatment or Day?',choices=c('Treatment','Day'),selected='Treatment'),
                         withSpinner(uiOutput('day'),type=7,proxy.height='200px'),
                         withSpinner(uiOutput('treatment'),type=7,proxy.height='200px'),
                         radioButtons('sex',label='Select Sex:',choices=list(Male='M',Female='F',Both=''),selected=''),
                         checkboxInput('changeFromBaseline','Calculate Change from Baseline?',value=F),
                         radioButtons('transformation',label='Select Transformation:',selected='zScore',
                                      choiceNames=c('Percent Change from Control','Z-Score','None'),
                                      choiceValues=c('percentChange','zScore','none')),
                         conditionalPanel(condition='input.changeFromBaseline==false & (input.transformation=="percentChange" || input.transformation=="zScore" )',
                                          uiOutput('selectControl')
                         )
                ),
                menuItem('Source Code',icon=icon('code'),href='http://10.192.49.11:8083/root/ClinPathApp/blob/master/app.R'),
                menuItem('White Paper',icon=icon('file-alt'),href='https://www.lexjansen.com/phuse-us/2019/dv/DV03.pdf')
    )
  ),
  
  dashboardBody(
    
    tags$script(HTML("$('body').addClass('sidebar-mini');")),
    # treeview not working properly
    tags$script(HTML("$('body').addClass('treeview');")),
    tabItems(
      tabItem(tabName='individualTable',
              h3('Individual Subject Data Table:'),
              withSpinner(DT::dataTableOutput('individualTable'),type=1)
      ),
      tabItem(tabName='meanTable',
              h3('Group Means Data Table:'),
              withSpinner(DT::dataTableOutput('meanTable'),type=1)
      ),
      
      tabItem(tabName='barPlot',
              h3('Bar Graph:'),
              withSpinner(plotOutput('barPlot',height=plotHeight),type=1)
      ),
      tabItem(tabName='pointPlot',
              h3('Point Plot:'),
              withSpinner(plotOutput('pointPlot',height=plotHeight),type=1)
      ),
      tabItem(tabName='meanLinePlot',
              # conditionalPanel(
              #   # condition='(input.filterBy=="Day" & input.day.length==1) | (input.filterBy=="Treatment" & input.treatment.length==1)',#!="All Treatments")',
              #   condition='values.day.length==1',
              #   h3('Cannot Plot Line Graph of Group Means for Only One Day!')
              #   # withSpinner(plotOutput('meanLinePlot',height=plotHeight),type=1)
              # ),
              # conditionalPanel(
              #   # condition='(input.filterBy=="Day" & input.day.length>1) | (input.filterBy=="Treatment" & input.treatment.length>1)',#=="All Treatments")',
              #   condition='values.day.length!=1',
              #   h3('Line Plots of Group Means:'),
              uiOutput('meanPlots')
              # )
      ),
      tabItem(tabName='linePlot',
              # conditionalPanel(
              #   # condition='(input.filterBy=="Day" & input.day!="All Days") | (input.filterBy=="Treatment" &input.treatment!="All Treatments")',
              #   condition="(typeof input.day !== 'undefined' && input.day > 0 && input.day.length==1)",
              #   h3('Line Plot of Individual Subjects:'),
              #   withSpinner(plotlyOutput('linePlot',height=plotHeight),type=1)
              # ),
              # conditionalPanel(
              #   # condition='(input.filterBy=="Day" & input.day=="All Days") | (input.filterBy=="Treatment" &input.treatment=="All Treatments")',
              #   condition="(typeof input.day !== 'undefined' && input.day.length!=1)",
              #   h3('Line Plots of Individual Subjects:'),
              uiOutput('plots')
              # ),
              # conditionalPanel(
              # condition="(typeof input.day === 'undefined')",
              # h3('Select Filter by Day to Initialize Plot!')
              # )
      ),
      tabItem(tabName='boxPlot',
              h3('Box and Whisker Plot:'),
              conditionalPanel(condition='input.addPoints==false',
                               withSpinner(plotOutput('boxPlot',height=plotHeight),type=1)
              ),
              conditionalPanel(condition='input.addPoints==true',
                               withSpinner(plotlyOutput('boxPlotly',height=plotHeight),type=1)
              )
      ),
      tabItem(tabName='scatterPlot',
              h3('Scatter Plots:'),
              withSpinner(plotOutput('scatterPlot',height=plotHeight),type=1)
      ),
     
      tabItem(tabName='PCA',
              h3('Principal Component Analysis:'),
              withSpinner(plotOutput('PCA'),type=1)
    )
  )))
  


# Run Shiny App
shinyApp(ui = ui, server = server)
