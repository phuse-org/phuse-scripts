# Purpose: Parse components from TRTV string
# Development History:
#   MM/DD/2019 (developer) - description
#   09/12/2021 (W. Wang) - Initial version of parsing TRTV R Shiny App
#install.packages("devtools")
#library(devtools)

library(shiny)
library(shinydashboard)
library(shinyjs)
library(shinyBS)
library(SASxport)
library(Hmisc)
library(rhandsontable)
library(phuse)
library(DT)
library(V8)
library(stringr)
source("parseTRTV.R")
is_empty <- phuse::is_empty;

header <- dashboardHeader(
  title = "Parsing TRTV"
)

sidebar <- dashboardSidebar(
  sidebarMenu(
    # Setting id makes input$tabs give the tabName of currently-selected tab
    id = "tab1",
    menuItem("Parse TRTV", icon = icon("cog"),
             menuSubItem("Parse TRTV User Guide", href = 'https://github.com/phuse-org/phuse-scripts/tree/master/contributed/Nonclinical/R/parseTRTV/parseTRTV instruction.pdf', newtab = FALSE) #png to be created
             , menuSubItem('Source Code',href='https://github.com/phuse-org/phuse-scripts/blob/master/contributed/Nonclinical/R/parseTRTV/parseTRTV.R', newtab = TRUE)
             
    )
  )
)
jsCodehide <- 'shinyjs.hideSidebar = function(params) {
      $("body").addClass("sidebar-collapse");
      $(window).trigger("resize"); }'
jscodeshow <- 'shinyjs.showSidebar = function(params) {
      $("body").removeClass("sidebar-collapse");
      $(window).trigger("resize"); }'

ui <- dashboardPage(
  header,
  sidebar,
  dashboardBody(
    useShinyjs()
    , extendShinyjs(text = jsCodehide , functions = c("hideSidebar"))
    , extendShinyjs(text = jscodeshow , functions = c("showSidebar"))
    , bsButton("showpanel", "Show/Hide sidebar",icon = icon("toggle-off"),
               type = "toggle",style = "info", value = TRUE)
    , tags$head(
      tags$style(type="text/css",
                 "label{ display: table-cell; text-align: right; vertical-align: middle; }
         .form-group { display: table-col;}")
    )
    , fluidRow(tabsetPanel(id='tabs'
                           , tabPanel("TRTV", uiOutput("tabP1"))
                           , tabPanel("Vehicle Components View", uiOutput("tabP2"))
    ))
    , fluidRow(
      tabItem("tab1", hr()
              , menuItem('Parse TRTV User Guide',icon=icon('code'),href = 'https://github.com/phuse-org/phuse-scripts/tree/master/contributed/Nonclinical/R/parseTRTV/parseTRTV_instruction.pdf')
              #, menuItem('Parse TRTV User Guide',icon=icon('code'),href = 'parseTRTV_instruction.pdf')
              , menuItem('Source Code',icon=icon('code'),href='https://github.com/phuse-org/phuse-scripts/blob/master/contributed/Nonclinical/R/parseTRTV/parseTRTV.R') # to be updated
              , hr()
      )
    )
    , tags$footer("PhUSE Code Sharing (Repository) Project"
                  , align = "center"
                  , style = "position:dynamic;
              bottom:0;
              width:100%;
              height:30px;   /* Height of the footer */
              color: white;
              padding: 10px;
              background-color: blue;
              z-index: 1000;"
    )
  )
)

server <- function(input, output, session) {
  (WD <- getwd())
  if (!is.null(WD)) setwd(WD)
  
  #read the table of component names that are already sorted from longest text string to shortest text string.
  tokens <- read.table(paste0(WD,"/tokens.csv"),sep=",", header = TRUE,stringsAsFactors=FALSE);
  
  ts_content <- reactive({
    
    validate(
      need(input$TRTV != "", "Please provide TRTV.")
    )
    req(input$TRTV)
    #parse the vehicle string from input$TRTV to vehicle components
    ts = ParseTRTV(input$TRTV, tokens)
    
    validate(
      need(nrow(ts) > 0, "TRTV parsing returns zero components, please check the TRTV value.")
    )
    ts
  })
  
  # -------------------- 1 tabPanel: TRTV  --------------------------------
 
  output$tabP1 <- renderUI({
    tabPanel("TRTV"
             , div(id = "form"
                   , textInput("TRTV", "Vehicle Text (TRTV) *" , width = '95%')
                   , bsAlert("alert")
              )
             , hr()
             , hidden(downloadButton('downloadData', 'Download'))
    )
  })
  # The parsed vehicle components can be downloaded as csv file.
  output$downloadData <- downloadHandler(
    filename = function() { paste("xv", ".csv",sep="") },
    content  = function(file = filename) {
      str(file)
      # get dataframe with the data
      studyData <- ts_content()
      write.csv(studyData,file=file,na="",row.names=FALSE)
     }
  )
  
  # -------------------- 2 tabPanel: View  ----------------------------------
  output$DT2 <- renderDataTable({
    df <- ts_content()
    str(df)
    datatable(df, options = list(dom = 't', scrollX=TRUE ));  # from DT package
  })
  
  output$tabP2 <- renderUI({
    df <- ts_content()
    tabPanel("CompsView"
             , DT::dataTableOutput("DT2")
             , hr()
             , hidden(downloadButton('downloadData', 'Download'))
    )
  })
  
  observe({
    if(input$showpanel == TRUE) {
      js$showSidebar()
    }
    else {
      js$hideSidebar()
    }
  })
  
  observeEvent(input$TRTV, {
    if (input$TRTV == "")
      hide("downloadData")
    else
      show("downloadData")
  })
  
  # TRTV should not be longer than 200 characters
  observeEvent(input$TRTV, {
    if(input$TRTV != "") {
      if (str_length(input$TRTV)>200) {
        updateTextInput(session, "TRTV", value = str_sub(input$TRTV, end=200) )
        createAlert(session, "alert", "TRTVAlert", title = "TRTV Alert"
                    , content = "Vehicle text must not exceed 200 characters and will be truncated."
                    , dismiss = TRUE, style = "warning", append = FALSE)
        Sys.sleep(3)
      } else {
        closeAlert(session, "TRTVAlert")
      }
    }
  })
}

shinyApp(ui, server)