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
      # textOutput("yml_name"),
      div(id="yml_name",class="shiny-text-output",style="display: none;"),
      # textInput("yn", "YML File Name: ", verbatimTextOutput("yml_name")),
      br(),
      # div(id="script_inputs",class="shiny-html-output")
      # includeHTML("www/s01.R"),
      uiOutput("script_inputs")
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
                  tabPanel("Merge", tableOutput("merge")),
                  # tabPanel("Execute", verbatimTextOutput("execute"))
                  tabPanel("Execute", plotOutput("execute"))
      )
    )
  )
)

fns <- build_script_df();
# txt <- readChar("www/links.txt",nchars=1e6)
sel <- fns[,1]; names(sel) <- fns[,2]
# h_a <- "<a href='%s' title='%s'>%s</a>"

# Define server logic for random distribution app ----
server <- function(input, output, session) {

  output$selectUI <- renderUI({
    selectInput("file", "Select Script:", sel)
  })

  output$result <- renderText({
    paste("Script File ID: ", input$file)
  })

  # output$fns <- build_script_df();
  # sel <- fns[,3]; names(sel) <- fns[,1];

  # output$links <- renderText({ txt })

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

  output$yml_name <- renderText({ as.character(fn()) })

  output$script <- renderText({
    # formulaText()
    # getURI(d())
    # getURLContent(d())
    # convert /x/y/a_b_sas.yml to /x/y/a_b.sas
    f1 <- gsub('_([[:alnum:]]+).([[:alnum:]]+)$','.\\1',fn())
    if (!exists("f1")) { return('') }
    if (is.na(f1) || length(f1) < 1 ) { return('') }
    ft <- gsub('.+\\.(\\w+)$','\\1', f1)
    if (length(ft) > 0 && grepl('^(zip|exe|bin)', ft, ignore.case = TRUE) ) {
      paste(paste0("File: ", f1),"     Could not be displayed.", sep = "\n")
    } else {
      paste(paste0("File: ", f1),readChar(f1,nchars=1e6), sep = "\n")
    }
  })

  output$yml <- renderText({
    f1 <- fn()
    paste(paste0("File: ", f1),readChar(f1,nchars=1e6), sep = "\n")
  })

  output$finfo <- renderTable({
    t1 <- t(fns[input$file,])
    # t1["file_url",] <- sprintf(h_a, t1["file_url",], t1["file_url",], t1["file",])
    t1
  }, rownames = TRUE )

  output$mtable <- renderTable({
    # yaml.load_file(URLencode(f1()[input$file,4]))
    m2()
  })

  output$verify <- renderTable({ extract_fns(read_yml(fn())) }, rownames = TRUE )

  output$dnload <- renderTable({
    y1 <- extract_fns(read_yml(fn()))
    y2 <- download_fns(y1)
    f1 <- y2[y2$tag=="script_name","file_path"]
    if (exists("session$clientdata")) { session$clientdata$ofn <- f1 }
    y2
  }, rownames = TRUE )

  output$merge <- renderTable({
    f1 <- fn()
    file_name <- basename(f1)
    work_dir  <- crt_workdir(to_crt_dir = FALSE)
    f2 <- paste(work_dir, "scripts", file_name, sep = '/')
    if (file.exists(f2)) {
      a  <- read_yml(f1)
      b  <- read_yml(f2)
      c  <- merge_lists(a,b)
      cvt_list2df(c)
    } else {
      msg <- c(paste0("Repo: ", f1), paste0("Loc : ", f2, " does not exists."));
      data.frame(msg)
    }
    }, rownames = TRUE )

  output$script_inputs <- renderUI({
    # y1 <- build_inputs(fn())
    tagList(
    sliderInput("nn","Number of observations:",value = 500,min = 1,max = 1000),
    radioButtons("dn","Distribution type:",
                 c("Normal"="rnorm","Uniform"="runif","Log-normal"="rlnorm","Exponential"="rexp"))
    )
    # eval(call(y1))
    # includeScript("www/s01.R")
  })

  output$execute <- renderPlot({
    # if (!is.null(input$yml_name)) {
    #  y2 <- input$yml_name
    # } else if (is.null(session$clientdata$ofn)) {
    #  f1 <- ifelse(input$src=="loc","file_path", "file_url")
    #  y1 <- download_fns(extract_fns(read_yml(fn())))
    #  y2 <- as.character(y1[y1$tag=="script_name",f1])
    # } else {
    #   y2 <- session$clientdata$ofn
    # }
    y2 <- gsub('_([[:alnum:]]+).([[:alnum:]]+)$','.\\1',fn())
    commandArgs <- function() c("phuse", y2, input$dn, input$nn)
    source(y2, local = TRUE)
  })
}

# Create Shiny app ----
shinyApp(ui, server)
