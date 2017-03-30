library(shiny)

shinyUI(fluidPage(
  
  # Application title
  titlePanel("Create HistoGraphic"),
  
  # Create GUI Parameter Options
  fluidRow(
    column(6,
           # Set number of studies
           numericInput('numStudies',label = h3("How many studies would you like to plot? (up to 5)"),value=1),
           
           # Display Error Message if Less than 1 Study Chosen
           conditionalPanel(
             condition = "input.numStudies < 1",
             h3("")
           ),
           
           # Define Study 1 Directory
           conditionalPanel(
             condition = "input.numStudies >= 1 && input.numStudies <= 5",
             h3('Study 1'),
             directoryInput('directory1',label = 'Directory:',value=defaultStudyFolder),
             textInput('study1Name',label='Study 1 Label:',value='Study 1')
           ),
           
           # Define Study 2 Directory
           conditionalPanel(
             condition = "input.numStudies >= 2 && input.numStudies <= 5",
             h3('Study 2'),
             directoryInput('directory2',label = 'Directory:',value=defaultStudyFolder),
             textInput('study2Name',label='Label:',value='Study 2')
           ),
           conditionalPanel(
             condition = "input.numStudies == 2",
             checkboxInput("addStudyCategory","Add Study as a Category?",value=FALSE)
           ),
           
           # Define Study 3 Directory
           conditionalPanel(
             condition = "input.numStudies >= 3 && input.numStudies <= 5",
             h3('Study 3'),
             directoryInput('directory3',label = 'Directory:',value=defaultStudyFolder),
             textInput('study3Name',label='Label:',value='Study 3')
           ),
           
           # Define Study 4 Directory
           conditionalPanel(
             condition = "input.numStudies >= 4 && input.numStudies <= 5",
             h3('Study 4'),
             directoryInput('directory4',label = 'Directory:',value=defaultStudyFolder),
             textInput('study4Name',label='Label:',value='Study 4')
           ),
           
           # Define Study 5 Directory
           conditionalPanel(
             condition = "input.numStudies ==5",
             h3('Study 5'),
             directoryInput('directory5',label = 'Directory:',value=defaultStudyFolder),
             textInput('study5Name',label='Label:',value='Study 5')
           ),
           
           # Display Error Message if Greater than 5 Studies Chose
           conditionalPanel(
             condition = "input.numStudies > 5",
             h3("Cannot choose more than 5 studies!")
           ),
           
           br(),
           
           # Define Filters
           h3('Filters:'),
           checkboxInput("includeNormal",label="Filter Out Organs without Abnormal Findings",value=TRUE),
           checkboxInput("removeNormal",label="Remove Normal Findings",value=FALSE),
           selectInput('severityFilter',label='Filter Out Organs with Findings of Severity Less than:',
                       choices = list(" "=0,"Minimal"=-1,"Mild"=-2,"Moderate"=-3,"Marked"=-4,"Severe"=-5)),
           checkboxInput("filterControls",label='Filter Out Findings with Equal or Greater Incidence and/or Severity in Controls',value=FALSE),br(),
           
           # Define Web Browser Selection
           selectInput('webBrowser',label='Choose Your Web Browser:',
                       choices = list("Firefox" = 'Firefox',"Google Chrome" = 'Chrome',"Internet Explorer" = 'IE')),
           
           # Define Submit Button
           actionButton("submit","Submit"),br(),br(),
           
           # Define Output Text Box
           verbatimTextOutput("text")
    ),
    column(6,
           # Define Drop Downs for Preset Category Organization
           selectInput("track",label="Report Counts or Incidence Rate?",
                       choices = list("Counts"='counts',"Incidence Rate"='incidence')),
           h3('Preset Category Organization'),
           selectInput("organizeBy",label="Organize By:",
                       choices = list("Organ"='Organ',"Subject"='Subject',"Custom"='Custom')),
           
           # Define Drop Downs for Custom Category Organization
           h3('Custom Category Organization'),
           conditionalPanel(
             condition = "input.numStudies == 1 || (input.numStudies == 2 && input.addStudyCategory == false)",
             selectInput("layer1",label="Category 1",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer2",label="Category 2",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer3",label="Category 3",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer4",label="Category 4",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer5",label="Category 5",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID')),
             selectInput("layer6",label="Category 6",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Animal ID"='SubjectID'))
           ),
           conditionalPanel(
             condition = "input.addStudyCategory == true || input.numStudies > 2",
             selectInput("layer1s",label="Category 1",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer2s",label="Category 2",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer3s",label="Category 3",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer4s",label="Category 4",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer5s",label="Category 5",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer6s",label="Category 6",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID')),
             selectInput("layer7s",label="Category 7",
                         choices = list(" "='blank',"Organ"='Organ',"Finding"='Finding',"Treatment"='Treatment',"Sex"='Sex',"Recovery"='Recovery',"Study ID"='StudyID',"Animal ID"='SubjectID'))
           )
    )
  )
)

############################################################################################


# Run Shiny App
)