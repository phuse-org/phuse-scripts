# This is intended to become a GUI for the xpt2txt.r and txt2xpt.r scripts as well as optionally perform
# other transformations on the datasets.
#
# 2018-26-12 When using xpt input and xpt output, the Pinnacle21 report on the result has a few false errors, but no valid errors or warnings that appear to be introduced by this script.
#  next I need to test the xpt output when using txt as input.
#  will SENDView open the xpt files created from either txt or xpt?
#  Then I should add code to read the configuration files and perform the transformations.


library(shiny)
library(SASxport)
library(stringr)
#require(utils)
library(plyr)

#initialize global variables
FolderOut <- FolderIn <- FolderConfig <- "select a folder"
sepchar <- "\t";

FolderIn = "C:\\001\\DN18010 (20138184)\\20138184 FR"
FolderOut = "C:\\001\\empty"

# Define UI 
TransformLog <- "transformation log"
ui <- fluidPage(
  titlePanel("xpt_txt: SEND transformation tool"),
  sidebarLayout(
      sidebarPanel(
        actionButton("bi","Input Folder"),
        textOutput("t1"),
        br(),
        actionButton("bc","Configuration Folder"),
        textOutput("t2"),
        br(),
        actionButton("bo","Output Folder"),
        textOutput("t3"),
        br(),
        actionButton("go","Transform", style="background-color: #D0F0FF")
      ), 
      mainPanel(htmlOutput("tlog"))
  )
)

# Define server logic 
server <- function(input, output) {
  
  # display the inital values on the screen
  output$t1 <- renderText({FolderIn})
  output$t2 <- renderText({FolderConfig})
  output$t3 <- renderText({FolderOut})
  output$tlog <- renderUI({TransformLog})
  
  # respond to user interactions for selecting folders and options
  observeEvent(input$bi, {
    FolderIn <<- choose.dir(getwd(), "Choose an input folder")
    output$t1 <- renderText({FolderIn})
  })
  observeEvent(input$bc, {
  FolderConfig <<- choose.dir(getwd(),"Choose a folder with configuration files")
    output$t2 <- renderText({FolderConfig})
  })
  observeEvent(input$bo, {
    FolderOut <<- choose.dir(getwd(),"Choose an empty output folder")
    output$t3 <- renderText({FolderOut})
  })
  
  # Transformation button was pressed
  observeEvent(input$go, {
    TransformLog <<- sprintf("%s<br/>Started Transformations.", TransformLog)
    output$tlog <- renderText({HTML(TransformLog)})

    #Look in output folder, If any files are present, ask the user to clear the directory and try again.
    if (!dir.exists(FolderOut))
    {
      TransformLog <<- sprintf("%s<br/>The output foler, %s, does not exist. Please select another folder.", TransformLog, FolderOut)
      output$tlog <- renderText({HTML(TransformLog)})
    }
    else if (length(dir(FolderOut))!= 0)
    {
      TransformLog <<- sprintf("%s<br/>The output foler, %s, is not empty. Please clear it or select another folder.", TransformLog, FolderOut)
      output$tlog <- renderText({HTML(TransformLog)})
    }
    else
    {
      # Read the input foler
      if (!dir.exists(FolderIn))
      {
        TransformLog <<- sprintf("%s<br/>The input folder, %s, does not exist. Please specify a valid input folder.",TransformLog, FolderIn)
        output$tlog <- renderText({HTML(TransformLog)})
      }
      else
      {
        # Look in the input folder for a ts.txt file.
        if (file.exists(paste(FolderIn,"\\ts.txt",sep="")))
        {
          TransformLog <<- sprintf("%s<br/>Found ts.txt, reading the %s\\*.txt files.", TransformLog, FolderIn)
          output$tlog <- renderText({HTML(TransformLog)})
          
          # Read all the *.txt files as datasets
          i_file <- 1
          FilesIn <- dir(FolderIn, pattern=".*.txt", ignore.case=TRUE)
          assign("DS",vector("list",length(FilesIn)), envir = .GlobalEnv)
          for (f in (FilesIn))
          {
            # browser() #uncomment this line to pasue R Shiny an enable inspection of variables for
            d <- tolower(str_extract(f,"[^\\.]*")) #extract the portion of the file name from the beginning until but not including the first period
            pf <- paste(FolderIn,"\\",f,sep="")
            h <- paste("DSHeader",d,sep=".")
            
            DS[[i_file]] <<- d # create a list of the portion of the data files' names used for the variables.
            
            TransformLog <<- sprintf("%s<br/>Reading %s", TransformLog, pf)
            output$tlog <- renderText({HTML(TransformLog)})

            myInLine <- readLines(pf)
            domain_name  <- str_trim(myInLine[1])  #read the domain name trimming off the tabs at the end introduced by Excel
            domain_label <- str_trim(myInLine[2])  #read the domain label trimming off the tabs at the end introduced by Excel
            # identify the columns that have a non-blank value in the variable names row.
            keep <- c()
            row <- strsplit(myInLine[5],sepchar)
            for (i in 1:length(row[[1]]))
            {
              if (row[[1]][i]!="")
              {
                keep <- c(keep,i)
              }
            }
            
            #read the variable labels
            row <- strsplit(myInLine[3],sepchar)
            variable_labels <- row[[1]][keep]
            #give error if any lable is more than 40 characters
            for (i in 1:length(variable_labels))
            {
              if (nchar(variable_labels[i])>40)
              {
                print(paste( c("Warning: varialbe label '",variable_labels[i], "' is longer than 40 characters."), collapse=""))
              }
            }
            
            #read the variable types
            row <- strsplit(myInLine[4],sepchar)
            column_types_all <- row[[1]];
            variable_types <- row[[1]][keep]
            #give error if any lable is anythng other than "character" or "numeric"
            for (i in 1:length(variable_types))
            {
              if ((variable_types[i] == "character") || (variable_types[i] == "numeric"))
              {
              }
              else
              {
                print(paste( c("Warning: varialbe label '",variable_labels[i], "' has a type that is neither 'character' nor 'numeric'."), collapse=""))
              }
            }
            
            #read the variable names
            row <- strsplit(myInLine[5],sepchar)
            variable_names <- row[[1]][keep]
            #give error if any name is more than 8 characters
            for (i in 1:length(variable_labels))
            {
              if (nchar(variable_names[i])>8)
              {
                print(paste( c("Warning: varialbe name '",variable_labels[i], "' is longer than 8 characters."), collapse=""))
                # I should improve this to prevent errors later.
              }
            }
 
            df1 <- read.table(pf, sep = sepchar, colClasses=column_types_all, skip = 4, header=TRUE, comment.char = "", flush=TRUE, stringsAsFactors = FALSE)
            # check the variable types:
            # for (i in colnames(df1)){print(class(df1[[i]]))}
            
            #Prepare the data to be written to the *.xpt file
            # Remove the columns that aren't to be kept.
            studyData <- df1[,keep]
            # give the dataset a label
            label(studyData) <- domain_label
            # give each variable a label
            for (i in 1:length(variable_labels))
            {
              label(studyData[[i]]) <- variable_labels[i]
            }
            # give each numeric variable the correct variable class
            for (i in which(variable_types=="numeric"))
            {
              df1[,i] <- as.numeric(df1[,i])
            }
            
            #store the dataset in global variables
            assign(paste("DSTable"     ,d,sep="."),       df1,                        envir = .GlobalEnv) #reads the Table data
            assign(paste("DSName" ,d,sep="."),            domain_name,                envir = .GlobalEnv) #This is the dataset name like DM
            assign(paste("DSLabel",d,sep="."),            domain_label,               envir = .GlobalEnv) #This is the dataset label like DEMOGRAPHICS
            assign(paste("DSVariableLabels",d,sep="."),   variable_labels,            envir = .GlobalEnv) #This is a list of the variable labels (up to 40 characters each)
            assign(paste("DSVariableTypes",d,sep="."),    variable_types,             envir = .GlobalEnv) #This is a list of the variable types like "character" "character" "numeric" "character" ...
            assign(paste("DSVariableNames",d,sep="."),    variable_names,             envir = .GlobalEnv) #This is a list of the variable names (up to 8 characters each)
            
            i_file <- i_file+1
          }  
          foundData <- TRUE 
        }
        else if (file.exists(paste(FolderIn,"\\ts.xpt",sep="")))
        {
          TransformLog <<- sprintf("%s<br/>Found ts.xpt, reading the %s\\*.xpt files.", TransformLog, FolderIn)
          output$tlog <- renderText({HTML(TransformLog)})

          # Read all the *.xpt files as datasets
          i <- 1
          FilesIn <- dir(FolderIn, pattern=".*.xpt", ignore.case=TRUE)
          assign("DS",vector("list",length(FilesIn)), envir = .GlobalEnv)
          for (f in (FilesIn))
          {
            # lookup.xport("c:/sas-play/dm.xpt") #prints a subset of the domain attributes in an easy to read format
            # browser() #uncomment this line to pasue R Shiny an enable inspection of variables for
            d <- tolower(str_extract(f,"[^\\.]*")) #extract the portion of the file name from the beginning until but not including the first period
            pf <- paste(FolderIn,"\\",f,sep="")
            h <- paste("DSHeader",d,sep=".")
            
            DS[[i]] <<- d #assign("DS"[[i]],d,envir = .GlobalEnv) # create a list of the portion of the data files' names used for the variables.

            TransformLog <<- sprintf("%s<br/>Reading %s", TransformLog, pf)
            output$tlog <- renderText({HTML(TransformLog)})
            df1 <-read.xport(pf)
            
            assign(h,                                      lookup.xport(pf),           envir = .GlobalEnv) #read the dataset metadata
            dn <- assign(paste("DSName" ,d,sep="."),       attr(get(h),"names"),       envir = .GlobalEnv) #This is the dataset name like DM
            assign(paste("DSLabel",d,sep="."),             attr(get(h)[[dn]],"label"), envir = .GlobalEnv) #This is the dataset label like DEMOGRAPHICS
            variable_labels <- 
              assign(paste("DSVariableLabels",d,sep="."), get(h)[[dn]]$label,         envir = .GlobalEnv) #This is a list of the variable labels (up to 40 characters each)
            assign(paste("DSVariableTypes",d,sep="."),    get(h)[[dn]]$type,          envir = .GlobalEnv) #This is a list of the variable types like "character" "character" "numeric" "character" ...
            assign(paste("DSVariableNames",d,sep="."),    get(h)[[dn]]$name,          envir = .GlobalEnv) #This is a list of the variable names (up to 8 characters each)
            
            #convert all integers to numeric.  This will ensure that they are written to xpt output as numeric
            t <- which(sapply(df1,class)[2,]=="integer")
            for (j in t)
            {
              df1[,j] <- as.numeric(df1[,j]) #this line unintentionally removes "labeled" from the results of class(df1[,j])
            }
            for (j in 1:length(variable_labels))  # re-assign the variable lables
            {
              label(df1[[j]]) <- variable_labels[j]
            }
            assign(paste("DSTable"     ,d,sep="."),        df1,                        envir = .GlobalEnv) #reads the Table data
            
            i <- i+1
          }      
          foundData <- TRUE
        }
        else
        {
          TransformLog <<- sprintf("%s<br/>Neither a ts.txt file nor a ts.xpt file could be found in the input folder, %s. Please provide a ts file; so, I know if I should read the xpt or the txt files.", TransformLog, FolderIn)
          output$tlog <- renderText({HTML(TransformLog)})
          foundData <- FALSE
        }
        if (foundData)
        {
        # Read the configuration foler
        
        # Perform the transformations
          
        #Output a revised set of SEND datasets in the output folder in both xpt format and txt (tab delimited).
          # write the txt output
          i <- 1
          for (f in DS)
          {
            f2 <- paste(f,".txt",sep="")
            pf <- paste(FolderOut,f2,sep="\\")
            myOutFile <- file(pf,"w")

            TransformLog <<- sprintf("%s<br/>Writing %s", TransformLog, pf)
            output$tlog <- renderText({HTML(TransformLog)})
            
            writeLines(get(paste("DSName",             DS[i],sep=".")),myOutFile)
            writeLines(get(paste("DSLabel",            DS[i],sep=".")),myOutFile)
            #writeLines(paste(variable_labels,sep="",collapse=sepchar),myOutFile)
            writeLines(paste(get(paste("DSVariableLabels",   DS[i],sep=".")),sep="",collapse=sepchar),myOutFile)
            writeLines(paste(get(paste("DSVariableTypes",    DS[i],sep=".")),sep="",collapse=sepchar),myOutFile)
            writeLines(paste(get(paste("DSVariableNames",    DS[i],sep=".")),sep="",collapse=sepchar),myOutFile)
            write.table(get(paste("DSTable",           DS[i],sep=".")),myOutFile,append = TRUE, sep =sepchar, row.names=FALSE, col.names=FALSE)
            close(myOutFile)  
            i <- i+1
          }
          # write the xpt output
          i <- 1
          for (f in DS)
          {
            f2 <- paste(f,".xpt",sep="")
            pf <- paste(FolderOut,f2,sep="\\")
            myOutFile <- file(pf,"w")
            
            TransformLog <<- sprintf("%s<br/>Writing %s", TransformLog, pf)
            output$tlog <- renderText({HTML(TransformLog)})
            cat(file=stdout(), paste("\nWriting",pf))
            
            # place this dataset into a list with a name
            aList = list(get(paste("DSTable",           DS[i],sep=".")))
            # assign the dataset name to it
            names(aList)[1]<- get(paste("DSName",             DS[i],sep="."))
            # write out dataframe
            write.xport(
              list=aList,
              file = pf,
              verbose=FALSE,
              sasVer="7.00",
              osType = str_match(R.version.string,"[0-9]+.[0-9]+.[0-9]+"),
              cDate = Sys.time(),
              formats=NULL,
              autogen.formats=FALSE
            )
            close(myOutFile)
            i <- i+1
          }
        }
      }
    }
    TransformLog <<- sprintf("%s<br/>Ended Transformations.", TransformLog)
    output$tlog <- renderText({HTML(TransformLog)})
  })
}

# Run the app
shinyApp(ui = ui, server = server)
