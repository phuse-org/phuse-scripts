#' Test init file
#' @description Test the merge list
#' @name app_test_merge

library(shiny)

# Define UI for dataset viewer app ----
ui <- fluidPage(

  # App title ----
  titlePanel("Script Metadata"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      # Input: Text for providing a caption ----
      # Note: Changes made to the caption in the textInput control
      # are updated in the output area immediately as you type
      textInput(inputId = "caption",
                label = "Caption:",
                value = "Script Metadata"),

      # Input: Selector for choosing dataset ----
      selectInput(inputId = "dataset",
                  label = "Choose a dataset:",
                  choices = c("Online", "Local", "Merged")),

      # Input: Numeric entry for number of obs to view ----
      numericInput(inputId = "obs",
                   label = "Number of observations to view:",
                   value = 10)

    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Formatted text for caption ----
      h3(textOutput("caption", container = span)),

      # Output: HTML table with requested number of observations ----
      tableOutput("view"),

      # Output: Verbatim text for data summary ----
      verbatimTextOutput("summary")
    )
  )
)

# Define server logic to summarize and view selected dataset ----
library('yaml')
server <- function(input, output) {

  c1 <- yaml.load_file('https://github.com/phuse-org/phuse-scripts/raw/master/development/R/scripts/test_load_df2ora_rep.yml')
  d1 <- list2df(c1)
  c2 <- yaml.load_file('/Users/htu/Repos/github/phuse-scripts/trunk/development/R/scripts/test_load_df2ora_loc.yml')
  d2 <- list2df(c2)
  c3 <- merge_lists(c1,c2)
  d3 <- list2df(c3)

  # Return the requested dataset ----
  # By declaring datasetInput as a reactive expression we ensure
  # that:
  #
  # 1. It is only called when the inputs it depends on changes
  # 2. The computation and result are shared by all the callers,
  #    i.e. it only executes a single time
  datasetInput <- reactive({
    switch(input$dataset,
           "Online" = d1,
           "Local" = d2,
           "Merged" = d3)
  })

  # Create caption ----
  # The output$caption is computed based on a reactive expression
  # that returns input$caption. When the user changes the
  # "caption" field:
  #
  # 1. This function is automatically called to recompute the output
  # 2. New caption is pushed back to the browser for re-display
  #
  # Note that because the data-oriented reactive expressions
  # below don't depend on input$caption, those expressions are
  # NOT called when input$caption changes
  output$caption <- renderText({
    input$caption
  })

  # Generate a summary of the dataset ----
  # The output$summary depends on the datasetInput reactive
  # expression, so will be re-executed whenever datasetInput is
  # invalidated, i.e. whenever the input$dataset changes
  output$summary <- renderPrint({
    dataset <- datasetInput()
    summary(dataset)
  })

  # Show the first "n" observations ----
  # The output$view depends on both the databaseInput reactive
  # expression and input$obs, so it will be re-executed whenever
  # input$dataset or input$obs is changed
  output$view <- renderTable({
    head(datasetInput(), n = input$obs)
  })

}

# Create Shiny app ----
shinyApp(ui, server)
