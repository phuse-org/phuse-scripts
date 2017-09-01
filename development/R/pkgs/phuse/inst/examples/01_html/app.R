library(shiny)

# Define server logic for random distribution app ----
server <- function(input, output) {

  # Reactive expression to generate the requested distribution ----
  # This is called whenever the inputs change. The output functions
  # defined below then use the value computed from this expression
  d <- reactive({
    dist <- switch(input$dist,
    sapr1 = 'https://github.com/phuse-org/phuse-scripts/raw/master/contributed/SAS%20Analysis%20Panels_zip.yml',
    sapr2 = 'https://github.com/phuse-org/phuse-scripts/raw/master/contributed/Scripts_Top_Dir_zip.yml',
    aesr1 = 'https://github.com/phuse-org/phuse-scripts/raw/master/contributed/AE/AE%20Scripts_zip.yml',
    f0701r = 'https://github.com/phuse-org/phuse-scripts/raw/master/whitepapers/WPCT/WPCT-F.07.01_R.yml',
    f0701s = 'https://github.com/phuse-org/phuse-scripts/raw/master/whitepapers/WPCT/WPCT-F.07.01_sas.yml'
    # index = 'https://github.com/phuse-org/phuse-scripts/wiki/Simple-Index'
    )
  })
  formulaText <- reactive({
    if (input$act == 'dld') {
      paste("Downloading ", d())
    } else if (input$act == 'exe') {
      paste("Executing ", d())
    } else {
      paste("Displaying", d())
    }
  })

  output$mdlink <- renderText({
    paste("A=", input$act, " Go to ", a(href=d(), title=d(), toupper(input$dist)))
  })

  output$caption <- renderText({
    formulaText()
  })

  output$smetadata <- renderText({
    # formulaText()
    # getURI(d())
    # getURLContent(d())
    if (input$act == 'dld') {
      paste("Downloading", d())
    } else if (input$act == 'exe') {
      paste("Executing", d())
    } else {
     # paste("See it in ", a(href=d(), title=d(), 'GitHub'))
     readChar(d(),nchars=1e6)
    }
    })
}

# Create Shiny app ----
shinyApp(ui = htmlTemplate("www/index.html"), server)
