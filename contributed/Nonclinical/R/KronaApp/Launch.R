list.of.packages <- c("shiny","XLConnect","rChoiceDialogs","SASxport")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
folder_address <- dirname(sys.frame(1)$ofile)
setwd(folder_address)
options(browser = "C:/Program Files/Internet Explorer/iexplore.exe")
shiny::runApp(folder_address, launch.browser=TRUE)