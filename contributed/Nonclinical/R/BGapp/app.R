################ Setup Application ########################################################

# Check for Required Packages, Install if Necessary, and Load
list.of.packages <- c("shiny","SASxport","rChoiceDialogs")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
library(SASxport)
library(rChoiceDialogs)

# Source Required Functions
source('directoryInput.R')

# Default Study Folder
defaultStudyFolder <- path.expand('~')

############################################################################################

################# Define Functional Response to GUI Input ##################################

server <- function(input, output,session) {
  
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$directory
    },
    handlerExpr = {
      if (input$directory == 1) {
        path = rchoose.dir(default = defaultStudyFolder)
        updateDirectoryInput(session, 'directory', value = path)
      }
    }
  )
  
  output$BWplot <- renderPlot({
    
    n <- input$n
    x <- 1:n
    
    for (i in seq(length(x))) {
      if (i == 1) {
        y <- x[i] + rnorm(1,0,1)
      } else {
        y[i] <- x[i] + rnorm(1,0,1)
      }
    }
    
    plot(x,y,xlab='Days',ylab='BW',main='Body Weight')
    
  })
  
}

############################################################################################

############################### Define GUI for Application #################################

ui <- fluidPage(
  
  titlePanel("Body Weight Gains Plot"),
  
  sidebarLayout(
    
    sidebarPanel(
      h3('Select Study'),
      directoryInput('directory',label = 'Directory:',value=defaultStudyFolder),
      
      sliderInput('n','Number of Days',min=1,max=100,value=50)
    ),
    
    mainPanel(
      plotOutput("BWplot")
    ) 
  )
)

############################################################################################

# Run Shiny App
shinyApp(ui = ui, server = server)