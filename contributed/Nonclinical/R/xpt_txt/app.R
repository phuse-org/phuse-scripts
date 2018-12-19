# This is intended to become a GUI for the xpt2txt.r and txt2xpt.r scripts as well as optionally perform
# other transformations on the datasets.
#

library(shiny)

#initialize global variables
TransformSEND <- function(f_in,f_config,f_out) {
}

# Define UI 
FolderOut <- FolderIn <- FolderConfig <- "select a folder"
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
      # Look in the input folder for a ts.txt file. 
      
      # Read the configuration foler
      
      # Perform the transformations
    }
    TransformLog <<- sprintf("%s<br/>Ended Transformations.", TransformLog)
    output$tlog <- renderText({HTML(TransformLog)})
  })
}

# Run the app
shinyApp(ui = ui, server = server)
