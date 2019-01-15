# This application can be run for free on a public server at the following address:
# https://phuse-nonclinical-scripts.shinyapps.io/LBapp/

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
  
  df[,nums] <- signif(df[,nums], digits = digits)
  
  (df)
}

# Source Functions
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')
# source('~/PhUSE/Repo/trunk/contributed/Nonclinical/R/Functions/Functions.R')
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/groupSEND.R')
# source('~/PhUSE/Repo/trunk/contributed/Nonclinical/R/Functions/groupSEND.R')

# Get GitHub Password (if possible)
if (file.exists('~/passwordGitHub.R')) {
  source('~/passwordGitHub.R')
  Authenticate <- TRUE
} else {
  Authenticate <- FALSE
}

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

# Set Heights and Widths
sidebarWidth <- '300px'
plotHeight <- '800px'

# Set Number of Significant Figures Places to Display in Tables
nSigFigs <- 3

# Set Maximum Number of Tests to Plot
max_plots <- 100

server <- function(input, output, session) {
  
  # Create Drop Down to Select Studies from PhUSE GitHub Repo
  output$selectGitHubStudy <- renderUI({
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
    selectInput('selectGitHubStudy',label='Select Study from PhUSE GitHub:',choices = GitHubStudies,selected='PDS')
  })
  
  # Handle Study Selection
  observeEvent(ignoreNULL = TRUE,eventExpr = input$chooseBWfile,
               handlerExpr = {
                 if (input$chooseBWfile >= 1) {
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
  })
  
  # Load Dataset
  loadData <- reactive({
    req(input$selectGitHubStudy)
    if (input$dataSource=='GitHub') {
      values$path <- paste0('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/send/',input$selectGitHubStudy)
    }
    path <- values$path
    
    withProgress({
      if (input$dataSource=='local') {
        setwd(path)
        if (length(list.files(pattern='*.xpt'))>0) {
          Dataset <- load.xpt.files(showProgress=T)
        } else if (length(list.files(pattern='*.csv'))>0) {
          Dataset <- load.csv.files(showProgress=T)
        } else {
          stop('No .xpt or .csv files to load!')
        }
      } else if (input$dataSource=='GitHub') {
        StudyDir <- paste0('data/send/',input$selectGitHubStudy)
        if (Authenticate==T) {
          Dataset <- load.GitHub.xpt.files(studyDir=StudyDir,showProgress=T,
                                           authenticate=TRUE,User=userGitHub,Password=passwordGitHub)
        } else {
          Dataset <- load.GitHub.xpt.files(studyDir=StudyDir,showProgress=T)
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
      index <- which((groupedData$LBSTRESU!='')&(is.null(groupedData$LBSTRESU)==F))
      groupedData <- groupedData[index,]
      groupedData$CATTEST <- paste(substr(groupedData$LBCAT,1,4),groupedData$LBTESTCD,sep='_')
      for (subject in unique(groupedData$USUBJID)) {
        index <- which(groupedData$USUBJID==subject)
        testTable <- table(groupedData$CATTEST[index])
        maxTest <- length(unique(groupedData$VISITDY[index]))
        overTestIndex <- which(testTable>maxTest)
        overTests <- names(testTable[overTestIndex])
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
      treatmentOrder <- NULL
      for (dose in doses) {
        treatmentOrder[length(treatmentOrder)+1] <- grep(dose,levels(factor(groupedData$TreatmentDose)),value=T)
      }
      values$treatmentOrder <- treatmentOrder
    },message='Loading Data...')
    return(groupedData)
  })
  
  # Display Test Categories
  output$testCategories <- renderUI({
    Data <- loadData()
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
    dayList <- as.list(c(unique(Data$VISITDY),'All Days'))
    radioButtons('day',label='Select Day:',choices=dayList,selected='All Days')
  })
  
  # Display Treatment Selection
  output$treatment <- renderUI({
    Data <- loadData()
    treatmentList <- as.list(c(unique(Data$TreatmentDose),'All Treatments'))
    radioButtons('treatment',label='Select Treatment:',choices=treatmentList,selected='All Treatments')
  })
  
  # Display Control Group Selection
  output$selectControl <- renderUI({
    req(values$treatmentOrder)
    radioButtons('selectControl','Select Control Group:',choices=values$treatmentOrder)
  })
  
  # Transform Data
  transformData <- reactive({
    Data <- loadData()
    Data <- Data[which(Data$LBCAT %in% input$testCategories),]
    tests <- input$tests
    CATTESTs <- grep('_',tests,value = T)
    CATTESTindex <- which(Data$CATTEST %in% CATTESTs)
    TESTCDs <- grep('_',tests,value=T,invert = T)
    TESTCDindex <- which(Data$LBTESTCD %in% TESTCDs)
    Data$CATTEST[TESTCDindex] <- levels(Data$LBTESTCD[TESTCDindex])[Data$LBTESTCD[TESTCDindex]]
    testIndex <- union(CATTESTindex,TESTCDindex)
    Data <- Data[testIndex,]
    Data <- dcast(Data,USUBJID+TreatmentDose+Sex+VISITDY~CATTEST,value.var='LBSTRESN')
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
      if ((input$transformation=='percentChange')&(input$changeFromBaseline==F)) {
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
            if (input$transformation=='zScore') {
              sex <- Data$Sex[i]
              Index <- which(Data$Sex==sex)
            } else {
              sex <- Data$Sex[i]
              sexIndex <- which(Data$Sex[index]==sex)
              day <- Data$Day[i]
              dayIndex <- which(Data$Day[index]==day)
              Index <- index[intersect(sexIndex,dayIndex)]
            }
          }
          if (input$transformation=='zScore') {
            if (sd(Data[Index,col],na.rm=T) > 0) {
              transformedData[i,col] <- (Data[i,col]-mean(Data[Index,col],na.rm=T))/sd(Data[Index,col],na.rm=T)
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
    }
    if (input$groupBy=='Treatment') {
      if (input$day=='All Days') {
        treatmentDay <- paste(DataLong$Treatment,DataLong$Day)
        treatmentDayOrder <- NULL
        for (treatment in values$treatmentOrder) {
          for (day in values$dayOrder) {
            treatmentDayOrder <- c(treatmentDayOrder,paste(treatment,day))
          }
        }
        DataLong$Treatment <- factor(treatmentDay,levels=treatmentDayOrder)
      } else {
        DataLong <- DataLong[which(DataLong$Day==as.numeric(input$day)),]
        variableOrder <- NULL
        for (i in seq(nrow(DataLong))) {
          variableOrder[i] <- which(input$tests==DataLong$variable[i])
        }
        DataLong <- DataLong[order(variableOrder),]
        DataLong$Treatment <- factor(DataLong$Treatment,levels=values$treatmentOrder)
      }
    }
    if (input$groupBy=='Day') {
      if (input$treatment=='All Treatments') {
        dayTreatment <- paste(DataLong$Day,DataLong$Treatment)
        dayTreatmentOrder <- NULL
        for (day in values$dayOrder) {
          for (treatment in values$treatmentOrder) {
            dayTreatmentOrder <- c(dayTreatmentOrder,paste(day,treatment))
          }
        }
        DataLong$Day <- factor(dayTreatment,levels=dayTreatmentOrder)
      } else {
        DataLong <- DataLong[which(DataLong$Treatment==input$treatment),]
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
      longData <- longData()
      tmp <- NULL
      for (i in seq(nrow(longData))) {
        tmp[i] <- strsplit(as.character(longData[i,input$groupBy]),' ')[[1]][1]
      }
      if (input$groupBy=='Treatment') {
        longData[[input$groupBy]] <- factor(tmp,levels=values$treatmentOrder)
      } else {
        longData[[input$groupBy]] <- as.factor(tmp)
      }
      Data <- dcast(longData,Treatment+ID+Sex+Day~variable)
      IDindex <- which(colnames(Data)=='ID')
      groupByIndex <- which(colnames(Data)==input$groupBy)
      notIndex <- which((colnames(Data)!='ID')&(colnames(Data)!=input$groupBy))
      index <- c(IDindex,groupByIndex,notIndex)
      Data <- Data[,index]
      Data <- Data[order(Data[[input$groupBy]]),]
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
      if (input$groupBy=='Treatment') {
        for (i in seq(nrow(longData))) {
          Tmp <- strsplit(as.character(longData[i,input$groupBy]),' ')[[1]]
          tmp[i] <- paste(Tmp[-length(Tmp)],collapse=' ')
        }
        longData[[input$groupBy]] <- factor(tmp,levels=values$treatmentOrder)
        longData[[input$groupBy]] <- as.factor(tmp)
      } else {
        for (i in seq(nrow(longData))) {
          Tmp <- strsplit(as.character(longData[i,input$groupBy]),' ')[[1]]
          tmp[i] <- Tmp[1]
        }
        longData[[input$groupBy]] <- as.factor(tmp)
      }
      if (input$sex == '') {
        meanData <- createMeansTable(longData,'value',c('variable','Treatment','Sex','Day'))
      } else {
        meanData <- createMeansTable(longData,'value',c('variable','Treatment','Day'))
      }
      colnames(meanData)[1] <- 'Test'
      groupByIndex <- which(colnames(meanData)==input$groupBy)
      notGroupByIndex <- which(colnames(meanData)!=input$groupBy)
      index <- c(notGroupByIndex[1],groupByIndex,notGroupByIndex[2:length(notGroupByIndex)])
      meanData <- meanData[,index]
      meanData <- meanData[order(meanData$Test,meanData[[input$groupBy]]),]
      colnames(meanData) <- c('Test',colnames(meanData)[2:(length(colnames(meanData))-3)],'Mean','Standard Deviation','Standard Error of Mean')
      meanData <- signif_df(meanData,digits=nSigFigs)
      meanData
    }
  },options=list(autoWidth=T,scrollX=T,pageLength=10,paging=T,searching=T,
                 columnDefs=list(list(className='dt-center',width='100px',targets=seq(0,5)))),
  rownames=F)
  
  # Display Box Plot Figure
  output$boxPlot <- renderPlot({
    if (!is.null(input$tests)) {
      Data <- longData()
      N <- length(unique(Data[[input$groupBy]]))
      my_color_ramp <- my_color_palette(N)
      p <- ggplot(data=Data,aes(x=variable,y=value,fill=get(input$groupBy))) +
        geom_boxplot() + xlab('Test') + scale_fill_manual(name=input$groupBy,values=my_color_ramp) +
        theme(text = element_text(size=18))
      if (input$transformation == 'percentChange') {
        p <- p + ylab('Percent Change from Control Mean (%)')
      } else if (input$transformation == 'zScore') {
        p <- p + ylab('Z-Score')
      } else {
        p <- p + ylab('Raw Value')
      }
      print(p)
    }
  })
  
  # Display Bar Graph Figure
  output$barPlot <- renderPlot({
    if (!is.null(input$tests)) {
      Data <- longData()
      if (input$sex != '') {
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Sex','Day'))
      } else {
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Day'))
      }
      N <- length(unique(Data[[input$groupBy]]))
      my_color_ramp <- my_color_palette(N)
      p <- ggplot(data=meanData,aes(x=variable,y=value_mean,fill=get(input$groupBy))) +
        geom_bar(position=position_dodge(),colour='black',stat='identity',size=.3) + xlab('Test') + 
        scale_fill_manual(name=input$groupby,values=my_color_ramp) + theme(text = element_text(size=18))
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
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Day'))
      }
      N <- length(unique(Data[[input$groupBy]]))
      my_color_ramp <- my_color_palette(N)
      if (input$sex == '') {
        p <- ggplot(data=meanData,aes(x=variable,y=value_mean,colour=get(input$groupBy),group=get(input$groupBy),shape=Sex))
      } else {
        p <- ggplot(data=meanData,aes(x=variable,y=value_mean,colour=get(input$groupBy),group=get(input$groupBy)))
      }
      p <- p + geom_point(size=3,position=position_dodge(.9),aes(y=value_mean,colour=get(input$groupBy))) + xlab('Test') + 
        scale_colour_manual(name=input$groupby,values=my_color_ramp) + theme(text = element_text(size=18))
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
      print(p)
    }
  })
  
  # Display Mean Line Plot Figure
  output$meanLinePlot <- renderPlot({
    if (!is.null(input$tests)) {
      Data <- longData()
      if (input$sex == '') {
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Sex','Day'))
      } else {
        meanData <- createMeansTable(Data,'value',c('variable','Treatment','Day'))
      }
      N <- length(unique(Data[[input$groupBy]]))
      my_color_ramp <- my_color_palette(N)
      if (input$sex == '') {
        p <- ggplot(data=meanData,aes(x=variable,y=value_mean,group=interaction(get(input$groupBy),Sex),colour=get(input$groupBy),shape=Sex))
      } else {
        p <- ggplot(data=meanData,aes(x=variable,y=value_mean,group=get(input$groupBy),colour=get(input$groupBy)))
      }
      p <- p + geom_point(size=3) + geom_line() + xlab('Test') + scale_colour_manual(name=input$groupby,values=my_color_ramp) + 
        theme(text = element_text(size=18))
      if (input$lineErrorbars!='none') {
        p <- p + geom_errorbar(aes(ymin=value_mean-get(paste('value',input$lineErrorbars,sep='_')),
                                   ymax=value_mean+get(paste('value',input$lineErrorbars,sep='_'))),
                               size=.3,width=0.3)
      }
      if (input$transformation == 'percentChange') {
        p <- p + ylab('Percent Change from Control Mean (%)')
      } else if (input$transformation == 'zScore') {
        p <- p + ylab('Z-Score')
      } else {
        p <- p + ylab('Raw Value')
      }
      print(p)
    }
  })
  
  # Display Mean Line Plot Figures
  output$meanPlots <- renderUI({
    plot_output_list <- lapply(seq(length(input$tests)), function(i) {
      meanPlotname <- paste("meanPlot", i, sep="")
      withSpinner(plotOutput(meanPlotname, height = 800, width = '100%'),type=1)
    })
    do.call(tagList, plot_output_list)
  })
  
  # Create Mean Line Plot Figures
  for (i in 1:max_plots) {
    local({
      my_i <- i
      meanPlotname <- paste("meanPlot", my_i, sep="")
      
      output[[meanPlotname]] <- renderPlot({
        Data <- transformData()
        if (input$sex != '') {
          sexIndex <- which(Data$Sex==input$sex)
          Data <- Data[sexIndex,]
        }
        test <- input$tests[my_i]
        if (input$sex == '') {
          meanData <- createMeansTable(Data,test,c('Treatment','Sex','Day'))
        } else {
          meanData <- createMeansTable(Data,test,c('Treatment','Day'))
        }
        N <- length(unique(meanData$Treatment))
        my_color_ramp <- my_color_palette(N)
        testName <- values$testDictionaryTests[which(values$testDictionaryCodes==test)]
        testUnit <- values$testDictionaryUnits[which(values$testDictionaryCodes==test)]
        testNameUnit <- paste0(testName,' (',testUnit,')')
        if (input$sex == '') {
          p <- ggplot(data=meanData,aes(x=Day,y=get(paste(test,'mean',sep='_')),group=interaction(Treatment,Sex),colour=Treatment,shape=Sex))
        } else {
          p <- ggplot(data=meanData,aes(x=Day,y=get(paste(test,'mean',sep='_')),group=Treatment,colour=Treatment))
        }
        p <- p + geom_point(size=3) + geom_line() + ggtitle(testNameUnit) + scale_colour_manual(name=input$groupby,values=my_color_ramp) +
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
      })
    })
  }
  
  # Display Individual Line Plot Figure
  output$linePlot <- renderPlotly({
    if (!is.null(input$tests)) {
      Data <- longData()
      N <- length(unique(Data[[input$groupBy]]))
      my_color_ramp <- my_color_palette(N)
      if (input$sex == '') {
        p <- ggplot(data=Data,aes(x=variable,y=value,group=ID,colour=get(input$groupBy),shape=Sex,label=ID))
      } else {
        p <- ggplot(data=Data,aes(x=variable,y=value,group=ID,colour=get(input$groupBy),label=ID))
      }
      p <- p + geom_point(size=3) + geom_path() + xlab('Test') + scale_colour_manual(name=input$groupby,values=my_color_ramp) +
        theme(text = element_text(size=18))
      print(p)
      if (input$transformation == 'percentChange') {
        p <- p + ylab('Percent Change from Control Mean (%)')
      } else if (input$transformation == 'zScore') {
        p <- p + ylab('Z-Score')
      } else {
        p <- p + ylab('Raw Value')
      }
      p <- ggplotly(p,tooltip='label')
      p$elementId <- NULL
      p
    }
  })
  
  # Display Individual Line Plot Figures
  output$plots <- renderUI({
    plot_output_list <- lapply(seq(length(input$tests)), function(i) {
      plotname <- paste("plot", i, sep="")
      withSpinner(plotlyOutput(plotname, height = 800, width = '100%'),type=1)
    })
    do.call(tagList, plot_output_list)
  })
  
  # Create Individual Line Plot Figures
  for (i in 1:max_plots) {
    local({
      my_i <- i
      plotname <- paste("plot", my_i, sep="")
      
      output[[plotname]] <- renderPlotly({
        Data <- transformData()
        if (input$sex != '') {
          sexIndex <- which(Data$Sex==input$sex)
          Data <- Data[sexIndex,]
        }
        test <- input$tests[my_i]
        Data$Treatment <- factor(Data$Treatment,levels=values$treatmentOrder)
        N <- length(unique(Data$Treatment))
        my_color_ramp <- my_color_palette(N)
        testName <- values$testDictionaryTests[which(values$testDictionaryCodes==test)]
        testUnit <- values$testDictionaryUnits[which(values$testDictionaryCodes==test)]
        testNameUnit <- paste0(testName,' (',testUnit,')')
        if (input$sex == '') {
          p <- ggplot(data=Data,aes(x=Day,y=get(test),group=ID,colour=Treatment,shape=Sex,label=ID))
        } else {
          p <- ggplot(data=Data,aes(x=Day,y=get(test),group=ID,colour=Treatment,label=ID))
        }
        p <- p + geom_point(size=3)+geom_path() + ggtitle(testNameUnit) + scale_colour_manual(name=input$groupby,values=my_color_ramp) +
          theme(text = element_text(size=18)) + xlab('Day')
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
      })
    })
  }
  
  output$scatterPlot <- renderPlotly({
    if (!is.null(input$tests)) {
      longData <- longData()
      tmp <- NULL
      if (input$groupBy=='Treatment') { # this is cutting off the last character when a day is selected!
        for (i in seq(nrow(longData))) {
          Tmp <- strsplit(as.character(longData[i,input$groupBy]),' ')[[1]]
          tmp[i] <- paste(Tmp[-length(Tmp)],collapse=' ')
        }
        longData[[input$groupBy]] <- factor(tmp,levels=values$treatmentOrder)
        longData[[input$groupBy]] <- as.factor(tmp)
      } else {
        for (i in seq(nrow(longData))) {
          Tmp <- strsplit(as.character(longData[i,input$groupBy]),' ')[[1]]
          tmp[i] <- Tmp[1]
        }
        longData[[input$groupBy]] <- as.factor(tmp)
      }
      Data <- dcast(longData,Treatment+ID+Sex+Day~variable)
      IDindex <- which(colnames(Data)=='ID')
      groupByIndex <- which(colnames(Data)==input$groupBy)
      notIndex <- which((colnames(Data)!='ID')&(colnames(Data)!=input$groupBy))
      index <- c(IDindex,groupByIndex,notIndex)
      Data <- Data[,index]
      Data <- Data[order(Data[[input$groupBy]]),]
      Data <- Data[,c(input$tests,'Day','Treatment','Sex','ID')]
      if (input$groupBy=='Day') {
        Data$Treatment <- factor(Data$Treatment,levels=values$treatmentOrder)
      } else {
        Data$Day <- factor(Data$Day,levels=values$dayOrder)
      }
      print(head(Data))
      N <- length(unique(Data$Treatment))
      my_color_ramp <- my_color_palette(N)
      p <- ggpairs(Data,aes(colour=Treatment,shape=Sex,label=ID),columns=(1:length(input$tests)),legend=1,
                   lower=list(continuous = wrap('points',size=3)),upper='blank',diag='blank',switch='both')
      for(i in 1:p$nrow) {
        for(j in 1:p$ncol){
          p[i,j] <- p[i,j] + 
            scale_color_manual(values=my_color_ramp)  
        }
      }
      p <- gpairs_lower(p)
      p <- ggplotly(p,tooltip='label') %>% layout(height=800,width=1000)
      p$elementId <- NULL
      p
    }
  })
  
  output$PCA <- renderPlotly({
    req(input$tests)
    longData <- longData()
    tmp <- NULL
    if (input$groupBy=='Treatment') {
      for (i in seq(nrow(longData))) {
        Tmp <- strsplit(as.character(longData[i,input$groupBy]),' ')[[1]]
        tmp[i] <- paste(Tmp[-length(Tmp)],collapse=' ')
      }
      longData[[input$groupBy]] <- factor(tmp,levels=values$treatmentOrder)
      longData[[input$groupBy]] <- as.factor(tmp)
    } else {
      for (i in seq(nrow(longData))) {
        Tmp <- strsplit(as.character(longData[i,input$groupBy]),' ')[[1]]
        tmp[i] <- Tmp[1]
      }
      longData[[input$groupBy]] <- as.factor(tmp)
    }
    Data <- dcast(longData,Treatment+ID+Sex+Day~variable)
    if (input$groupBy=='Day') {
      Data$Treatment <- factor(Data$Treatment,levels=values$treatmentOrder)
    } else {
      Data$Day <- factor(Data$Day,levels=values$dayOrder)
    }
    N <- length(unique(Data$Treatment))
    my_color_ramp <- my_color_palette(N)
    pData <- Data[,input$tests]
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
    pData <- pData[rowIndex,]
    pData.pca <- prcomp(pData,scale. = TRUE)
    Groups <- Data$Treatment[rowIndex]
    Shape <- Data$Sex[rowIndex]
    Label <- Data$ID[rowIndex]
    p <- ggbiplot(pData.pca,obs.scale=1,var.scale=1,groups=Groups,groupName='Treatment',shape=Shape,label=Label,
                  color_ramp=my_color_ramp,ellipse=input$ellipse,ellipse.prob = input$ellipseConf/100,circle=F) +
      theme(text=element_text(size=18))
    p <- ggplotly(p,tooltip='label') %>% layout(height=800,width=1200)
    p$elementId <- NULL
    p
  })
  
}

ui <- dashboardPage(
  
  dashboardHeader(title='LB Visualizations',titleWidth=sidebarWidth),
  
  dashboardSidebar(width=sidebarWidth,
                   sidebarMenu(id='sidebar',
                     menuItem('Tables',icon=icon('table'),startExpanded=T,
                              menuSubItem('Group Means',tabName='meanTable',icon=icon('th-list'),selected=T),
                              menuSubItem('Individuals',tabName='individualTable',icon=icon('th'))
                     ),
                     menuItem('Figures',icon=icon('area-chart'),startExpanded=T,
                              menuItem('Box Plot',tabName='boxPlot',icon=icon('cube')),
                              convertMenuItem(menuItem('Bar Graph',tabName='barPlot',icon=icon('bar-chart'),
                                                       menuSubItem(icon=NULL,
                                                                   radioButtons('barErrorbars',label='Select Type of Error Bars:',
                                                                                choices=list('None'='none','Standard Deviation'='sd','Standard Error of Mean'='se'),
                                                                                selected='se')                                                       )
                              ),'barPlot'),
                              convertMenuItem(menuItem('Point Graph',tabName='pointPlot',icon=icon('genderless'),
                                                       menuSubItem(icon=NULL,
                                                                   radioButtons('pointErrorbars',label='Select Type of Error Bars:',
                                                                                choices=list('None'='none','Standard Deviation'='sd','Standard Error of Mean'='se'),
                                                                                selected='se')                                                       )
                              ),'pointPlot'),
                              convertMenuItem(menuItem(text=tags$b('Line Plot',tags$br(),'(Group Means)'),tabName='meanLinePlot',icon=icon('line-chart'),
                                                       menuSubItem(icon=NULL,
                                                                   radioButtons('lineErrorbars',label='Select Type of Error Bars:',
                                                                                choices=list('None'='none','Standard Deviation'='sd','Standard Error of Mean'='se'),
                                                                                selected='se')                                                       )
                              ),'meanLinePlot'),
                              menuItem(text=tags$b('Line Plot',tags$br(),'(Individuals)'),tabName='linePlot',icon=icon('random')),
                              menuItem('Scatter Plots',tabName='scatterPlot',icon=icon('braille')),
                              convertMenuItem(menuItem('PCA',tabName='PCA',icon=icon('codepen'),
                                                       menuSubItem(icon=NULL,
                                                                   checkboxInput('ellipse','Show Treatment Group Ellipses?',value=F)
                                                       ),
                                                       conditionalPanel(condition='input.ellipse==true',
                                                                        numericInput('ellipseConf','Percent Confidence:',min=0,max=100,value=95,step=5)
                                                       )
                              ),'PCA')
                     ),
                     menuItem('Select Dataset',icon=icon('database'),startExpanded=T,
                              selectInput('dataSource','Select Data Source:',c('GitHub')),
                              conditionalPanel(
                                condition = 'input.dataSource=="GitHub"',
                                uiOutput('selectGitHubStudy')
                              ),
                              conditionalPanel(
                                condition = 'input.dataSource=="local"',
                                actionButton('chooseBWfile','Choose a BW Domain File')
                              ),
                              h5('Study Folder Location:'),
                              verbatimTextOutput('bwFilePath')
                     ),
                     menuItem('Select Tests',icon=icon('flask'),startExpanded=T,
                              withSpinner(uiOutput('testCategories'),type=7,proxy.height='200px'),
                              withSpinner(uiOutput('tests'),type=7,proxy.height='200px'),
                              actionButton('clearTests',label='Clear All'),
                              actionButton('displayTests',label='Display All')
                     ),
                     menuItem('Settings',icon=icon('cogs'),startExpanded=T,
                              selectInput('groupBy',label='Group by Treatment or Day?',choices=c('Treatment','Day'),selected='Day'),
                              conditionalPanel(
                                condition = 'input.groupBy == "Treatment"',
                                withSpinner(uiOutput('day'),type=7,proxy.height='200px')
                              ),
                              conditionalPanel(
                                condition = 'input.groupBy == "Day"',
                                withSpinner(uiOutput('treatment'),type=7,proxy.height='200px')
                              ),
                              radioButtons('sex',label='Select Sex:',choices=list(Male='M',Female='F',Both=''),selected=''),
                              checkboxInput('changeFromBaseline','Calculate Change from Baseline?',value=F),
                              conditionalPanel(condition='input.changeFromBaseline==false',
                                               radioButtons('transformation',label='Select Transformation:',selected='zScore',
                                                            choiceNames=c('Percent Change from Control','Z-Score','None'),
                                                            choiceValues=c('percentChange','zScore','none'))
                              ),
                              conditionalPanel(condition='input.changeFromBaseline==true',
                                               radioButtons('transformation',label='Select Transformation:',selected='zScore',
                                                            choiceNames=c('Percent Change from Baseline','Z-Score','None'),
                                                            choiceValues=c('percentChange','zScore','none'))
                              ),
                              conditionalPanel(condition='input.changeFromBaseline==false & input.transformation=="percentChange"',
                                               uiOutput('selectControl')
                              )
                     )
                   )
  ),
  
  dashboardBody(
    
    tags$script(HTML("$('body').addClass('sidebar-mini');")),
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
      tabItem(tabName='boxPlot',
              h3('Box and Whisker Plot:'),
              withSpinner(plotOutput('boxPlot',height=plotHeight),type=1)
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
              conditionalPanel(
                condition='(input.groupBy=="Treatment" & input.day!="All Days") | (input.groupBy=="Day" &input.treatment!="All Treatments")',
                h3('Line Plot of Group Means:'),
                withSpinner(plotOutput('meanLinePlot',height=plotHeight),type=1)
              ),
              conditionalPanel(
                condition='(input.groupBy=="Treatment" & input.day=="All Days") | (input.groupBy=="Day" &input.treatment=="All Treatments")',
                h3('Line Plots of Group Means:'),
                uiOutput('meanPlots')
              )
      ),
      
      tabItem(tabName='linePlot',
              conditionalPanel(
                condition='(input.groupBy=="Treatment" & input.day!="All Days") | (input.groupBy=="Day" &input.treatment!="All Treatments")',
                h3('Line Plot of Individual Subjects:'),
                withSpinner(plotlyOutput('linePlot',height=plotHeight),type=1)
              ),
              conditionalPanel(
                condition='(input.groupBy=="Treatment" & input.day=="All Days") | (input.groupBy=="Day" &input.treatment=="All Treatments")',
                h3('Line Plots of Individual Subjects:'),
                uiOutput('plots')
              )
      ),
      
      tabItem(tabName='scatterPlot',
              h3('Scatter Plots:'),
              withSpinner(plotlyOutput('scatterPlot',height=plotHeight),type=1)
      ),
      
      tabItem(tabName='PCA',
              h3('Principal Component Analysis:'),
              withSpinner(plotlyOutput('PCA'),type=1)
      )
    )
  )
  
)

# Run Shiny App
shinyApp(ui = ui, server = server)