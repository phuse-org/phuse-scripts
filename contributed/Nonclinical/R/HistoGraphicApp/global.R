
####### Issues to Resolve/Feature to Add ##################################################
#
# 1) Modified versions of Krona are not allowed to use the trademark Krona.  Need to come
#    up with another name and change the name icons and references in the script.
#       - Completed! (renamed the tool HistoGraphic)
# 2) Handle unscheduled deaths as intended recovery or non-recovery group
#       - Not sure this can be done in a reliable way (eliminated option from GUI)
# 3) Add feature to filter out findings of equal or lesser incidence/severity than controls
#       - Completed (but still requires more testing)
# 4) Allow studies to be displayed in the same chart (study as a ring)
#       - Completed (but maybe I should also add rings for species/duration/drug if applicable)
# 5) Make color contrast more drastic (and more friendly for the red/green color blind)
#       - Completed (but not sure if I picked the best possible color scheme)
# 6) Display parameter setting on side of plot
###########################################################################################

################ Setup Application ########################################################

# Check for Required Packages, Install if Necessary, and Load
list.of.packages <- c("shiny","XLConnect","rChoiceDialogs","SASxport")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos='http://cran.us.r-project.org')
library(shiny)
library(XLConnect)
library(rChoiceDialogs)
library(SASxport)

# Source Required Functions
source('directoryInput.R')
source('Functions.R')

# Default Study Folder
defaultStudyFolder <- path.expand('~')

############################################################################################


################# Define Functional Response to GUI Input ##################################

