library(shiny)

# Define UI for random distribution app ----
ui <- fluidPage(

  # App title ----
  titlePanel("R Shiny Environments"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(
      radioButtons("env", "R Environment:",
                 c("Parent" = "par", "Current" = "cur")),
      div(id="yml_name",class="shiny-text-output",style="display: yes;"),
      br(),
      conditionalPanel( condition = "output.show_ui", uiOutput("script_inputs") )
    ),

    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Tabset w/ plot, summary, and table ----
      tabsetPanel(type = "tabs",
                  # tabPanel("SysEnv", pre(id="sysenv",class="shiny-html-output")),
                  tabPanel("SysEnv", tableOutput("sysenv")),
                  tabPanel("SysInfo", tableOutput("sysinfo")),
                  tabPanel("Inputs", tableOutput("iparam")),
                  tabPanel("Outputs", tableOutput("oparam")),
                  tabPanel("ClientData", tableOutput("cldata")),
                  # tabPanel("Execute", verbatimTextOutput("execute"))
                  tabPanel("Execute", plotOutput("exeplot"))
      )
    )
  )
)

# Define server logic for random distribution app ----
server <- function(input, output, session) {

  output$show_ui <- reactive({ TRUE  })
  env_name <- reactive({ ifelse(input$env=="par","parent", "current") })
  output$yml_name  <- renderText({ paste0("Env Name: ", input$env) })

  output$sysenv  <- renderTable({
    r1 <- Sys.getenv();
    b <- ifelse(input$env=="cur", TRUE, FALSE)
    cvt_class2df(r1, condition = b)
    }, rownames = TRUE)
  output$sysinfo <- renderTable({ Sys.info()   }, rownames = TRUE)
  output$iparam  <- renderTable({ cvt_class2df(input)   }, rownames = TRUE)
  output$oparam  <- renderTable({ cvt_class2df(output)  }, rownames = TRUE)
  output$cldata  <- renderTable({ cvt_class2df(session$clientData) }, rownames = TRUE)
  output$exeplot <- renderPlot({
    d1 <- system.file("examples",package = "phuse")
    f1 <- paste(d1, "03_showenv", "draw_hist_R.yml", sep = '/')
    commandArgs <- function() list("phuse", input$p1, input$p2, script_name=f1)
    source(f1, local = TRUE)
  })

  output$script_inputs <- renderUI({
    tagList(
      sliderInput("p2","Number of observations:",value = 500,min = 1,max = 1000),
      radioButtons("p1","Distribution type:",
                   c("Normal"="rnorm","Uniform"="runif","Log-normal"="rlnorm","Exponential"="rexp"))
    )
  })
}

# Create Shiny app ----
shinyApp(ui, server)
