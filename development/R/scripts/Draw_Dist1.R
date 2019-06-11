#' Plot Distribution
#' @description extract folders and file names from a list containing script metadata.
#' @param lst a list containing script metadata
#' @return a data frame (subdir, filename) containing parsed file names
#' @name draw_dist2
#' @export
#' @author Hanming Tu
# Function Name: draw_dist2
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  09/17/2017 (htu) - initial creation
#

library(shiny)

ui <- fluidPage(
  titlePanel("Test Draw App"),
  sidebarLayout(
    # Sidebar panel for inputs ----
    sidebarPanel(
      radioButtons("p1","Distribution type:"
	    ,c("Normal"="rnorm","Uniform"="runif","Log-normal"="rlnorm","Exponential"="rexp")),
      sliderInput("p2","Number of observations:",value = 500,min = 1,max = 1000)
	 ),
    mainPanel(
      # Output: Tabset w/ plot, summary, and table ----
      tabsetPanel(type = "tabs",
	    tabPanel("Execute", plotOutput("execute"))
	  )
    )
  )	
)

# Define server logic for random distribution app ----
server <- function(input, output, session) {
  output$execute <- renderPlot({
    dn <-  reactive({input$p1});
    nn <-  reactive({input$p2});
    d <- eval(call(dn(), nn()));
    t <- paste(dn(), "(", nn(), ")", sep = "");
    hist(d, main = t,col="#75AADB", border = "white")
  })
}

# Create Shiny app ----
shinyApp(ui, server)

