################ Setup Application ########################################################

# Check for Required Packages, Install if Necessary, and Load
list.of.packages <- c("shiny","SASxport","rChoiceDialogs","ggplot2")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
library(SASxport)
library(rChoiceDialogs)
library(ggplot2)

# Source Required Functions
source('directoryInput.R')
source('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')

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
      if (input$directory >= 1) {
        path <- rchoose.dir(default = defaultStudyFolder)
        updateDirectoryInput(session, 'directory', value = path)
      }
    }
  )
  
  output$BWplot <- renderPlot({
    
    path <- readDirectoryInput(session,'directory')
    
    setwd(path)
    
    Data <- load.xpt.files()
    
    bw <- Data$bw
    dm <- Data$dm
    
    print(head(bw))
    print(head(dm))
    
    # Tasks
    # 1) Add grouping variable -- Bob
    # 2) Add percent difference from day 0 -- Tony/Bill
    # 3) Add body weight gain with selected interval -- Kevin
    
    p <- ggplot(bw,aes(x=BWDY,y=BWSTRESN)) + geom_point()
    print(p)
    
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
      
      sliderInput('n','Interval Length',min=1,max=20,value=10)
    ),
    
    mainPanel(
      plotOutput("BWplot")
    ) 
  )
)

############################################################################################

# Run Shiny App
shinyApp(ui = ui, server = server)