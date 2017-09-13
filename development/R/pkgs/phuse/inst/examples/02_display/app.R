library(shiny)

# Define UI for random distribution app ----
ui <- fluidPage(

  # App title ----
  titlePanel("Phuse Script Web Application Framework"),
  includeHTML("www/links.txt"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      htmlOutput("selectUI"),
      radioButtons("src", "File Source:",
                 c("Local" = "loc", "Repository" = "rep")),
      textOutput("result"),
      br(),
      div(id="script_inputs",class="shiny-html-output")
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Tabset w/ plot, summary, and table ----
      tabsetPanel(type = "tabs",
                  tabPanel("Script", pre(id="script",class="shiny-html-output")),
                  tabPanel("YML", pre(id="yml",class="shiny-html-output")),
                  tabPanel("Info", tableOutput("finfo")),
                  tabPanel("Metadata", tableOutput("mtable")),
                  tabPanel("Verify", tableOutput("verify")),
                  tabPanel("Download", tableOutput("dnload")),
                  tabPanel("Merge", verbatimTextOutput("summary")),
                  tabPanel("Execute", plotOutput("plot"))

      )
    )
  )
)

fns <- build_script_df();
# txt <- readChar("www/links.txt",nchars=1e6)
sel <- fns[,1]; names(sel) <- fns[,2]
h_a <- "<a href='%s' title='%s'>%s</a>"

# Define server logic for random distribution app ----
server <- function(input, output) {
  output$selectUI <- renderUI({
    selectInput("file", "Select Script:", sel)
  })

  output$result <- renderText({
    paste("Script File ID: ", input$file)
  })

  # output$fns <- build_script_df();
  # sel <- fns[,3]; names(sel) <- fns[,1];

  output$links <- renderText({ txt })

  m1 <- reactive({ fns })
  # u1 <- reactive({ URLencode(as.character(f1()[input$file,"file_url"])) })
  m2 <- reactive({ # URLencode(m1()[input$file,4])
    u1 <- URLencode(as.character(fns[input$file,"file_url"]))
    u2 <- NULL
    # gsub("[^[:alnum:]///' ]", "",
    # gsub("[\n]","\r\n",
    try(u2 <- cvt_list2df(read_yml(u1)), silent = TRUE)
    if (is.null(u2)) { paste0("Error parsing ", u1) } else { u2 }
    # )
    })

  fn <- reactive({
    f1 <- ifelse(input$src=="loc","file_path", "file_url")
    f2 <- gsub('\r','', fns[input$file,f1], perl = TRUE)
    f3 <- ifelse(input$src=="loc",f2, URLencode(as.character(f2)))
    f3
  })
  output$script <- renderText({
    # formulaText()
    # getURI(d())
    # getURLContent(d())
    # convert /x/y/a_b_sas.yml to /x/y/a_b.sas
    f1 <- gsub('_([[:alnum:]]+).([[:alnum:]]+)$','.\\1',fn())
    paste(paste0("File: ", f1),readChar(f1,nchars=1e6), sep = "\n")
  })

  output$yml <- renderText({
    f1 <- fn()
    paste(paste0("File: ", f1),readChar(f1,nchars=1e6), sep = "\n")
  })

  output$mtable <- renderTable({
    # yaml.load_file(URLencode(f1()[input$file,4]))
    m2()
  })

  output$finfo <- renderTable({
    t1 <- t(fns[input$file,])
    # t1["file_url",] <- sprintf(h_a, t1["file_url",], t1["file_url",], t1["file",])
    t1
  }, rownames = TRUE )

  output$verify <- renderTable({ extract(read_yml(fn())) }, rownames = TRUE )

  output$dnload <- renderTable({
    y1 <- extract(read_yml(fn()))
    y2 <- download_fns(y1)
    y2
  }, rownames = TRUE )

  output$script_inputs <- renderText({  build_inputs(fn())  })

  # Reactive expression to generate the requested distribution ----
  # This is called whenever the inputs change. The output functions
  # defined below then use the value computed from this expression
  d <- reactive({
    dist <- switch(input$dist,
                   norm = rnorm,
                   unif = runif,
                   lnorm = rlnorm,
                   exp = rexp,
                   rnorm)
    dist(input$n)
  })

  # Generate a plot of the data ----
  # Also uses the inputs to build the plot label. Note that the
  # dependencies on the inputs and the data reactive expression are
  # both tracked, and all expressions are called in the sequence
  # implied by the dependency graph.
  output$plot <- renderPlot({
    dist <- input$dist
    n <- input$n
    hist(d(),
         main = paste("r", dist, "(", n, ")", sep = ""),
         col = "#75AADB", border = "white")
  })

  # Generate a summary of the data ----
  output$summary <- renderPrint({
    summary(d())
  })

  # Generate an HTML table view of the data ----
  output$table <- renderTable({
    d()
  })

}

# Create Shiny app ----
shinyApp(ui, server)
