# These functions work together with the SendDataFactory

#
setTSFile <- function(input) {
  # create data frame based on structure
  aDomain <- "TS"
  print(input$studyName)
  print(input$CTSelection)
  print(paste("SEND Implementation Guide Version ",input$SENDVersions))
  
  theColumns <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Column
  theLabels <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Label
  tsOut <<- setNames(data.frame(matrix(ncol = length(theColumns), nrow = 1)),
                     theColumns
  )
  # set labels for each field 
  index <- 1
  for (aColumn in theColumns) {
    Hmisc::label(tsOut[[index]]) <<- theLabels[index]
    index <- index + 1
  }
  aRow <- 1
  if (!is.null(input$testArticle)) {
    tsOut[aRow,] <<- list(input$studyName,
                          aDomain,
                          aRow,
                          "",
                          "TRT",
                          "Investigational Therapy or Treatment",
                          input$testArticle,
                          "")        
    aRow <- aRow + 1
  }
  if (!is.null(input$species)) {
    tsOut[aRow,] <<- list(input$studyName,
                          aDomain,
                          aRow,
                          "",
                          "SPECIES",
                          "Species",
                          input$species,
                          "")        
    aRow <- aRow + 1
  }
  if (!is.null(input$studyType)) {
    tsOut[aRow,] <<- list(input$studyName,
                          aDomain,
                          aRow,
                          "",
                          "SSTYP",
                          "Study Type",
                          input$studyType,
                          "")        
    aRow <- aRow + 1
  }
  if (!is.null(input$CTSelection)) {
    tsOut[aRow,] <<- list(input$studyName,
                          aDomain,
                          aRow,
                          "",
                          "SNDCTVER",
                          "SEND Controlled Terminology Version",
                          paste("SEND Terminology",input$CTSelection),
                          "")        
    aRow <- aRow + 1
  }
  if (!is.null(input$SENDVersions)) {
    tsOut[aRow,] <<- list(input$studyName,
                          aDomain,
                          aRow,
                          "",
                          "SNDIGVER",
                          "SEND Implementation Guide Version",
                          paste("SEND Implementation Guide Version",input$SENDVersions),
                          "")        
    aRow <- aRow + 1
  }
  if (!is.null(input$strain)) {
    tsOut[aRow,] <<- list(input$studyName,
                          aDomain,
                          aRow,
                          "",
                          "STRAIN",
                          "Strain/Substrain",
                          input$strain,
                          "")        
    aRow <- aRow + 1
  }
  # Add in the other TS values
  for(index in 1:nrow(TSFromFile)) {
    tsOut[aRow,] <<- list(input$studyName,
                          aDomain,
                          aRow,
                          "",
                          as.character(TSFromFile$TSPARMCD[index]),
                          as.character(TSFromFile$TSPARM[index]),
                          as.character(TSFromFile$TSVAL[index]),
                          "")        
    aRow <- aRow + 1
  }
  
  # add to set of data
  addToSet("TS","TRIAL SUMMARY","tsOut")
}

setTEFile <- function(input) {
  # create data frame based on structure
  aDomain <- "TE"
  theColumns <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Column
  theLabels <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Label
  tOut <<- setNames(data.frame(matrix(ncol = length(theColumns), nrow = 1)),
                     theColumns
  )
  # set labels for each field 
  index <- 1
  for (aColumn in theColumns) {
    Hmisc::label(tOut[[index]]) <<- theLabels[index]
    index <- index + 1
  }
  aRow <- 1
  # create element for pretreatment
  if ("Pre-treatment" %in% input$elementOptions ) {
    tOut[aRow,] <<- list(input$studyName,
                         aDomain,
                         "SCRN",
                         "Screen",
                         "Start of Pretreatment",
                         # FIXME - make lenth of pretreatment variable
                         paste(1,"week after start of Element"),
                         paste("P",7,"D",sep=""))        
    aRow <- aRow + 1
  }
  # create element for dosing phases
  for (iDose in input$treatment) {
    iCount <- 1
    # read duration from DOSDUR in tsOUT
    duration <- tsOut[tsOut$TSPARMCD=="DOSDUR","TSVAL"]
    iDays <- DUR_to_days(duration)
    tOut[aRow,] <<- list(input$studyName,
                         aDomain,
                         paste("TRT0",iCount,sep=""),
                         iDose,
                         paste("Start of",iDose),
                         paste(iDays,"days after start of Element"),
                         duration
                         )        
    iCount <- iCount + 1
    aRow <- aRow + 1
  }
  if ("Recovery animals" %in% input$elementOptions ) {
    tOut[aRow,] <<- list(input$studyName,
                         aDomain,
                         "RECOVERY",
                         "Recovery period",
                         "Start of Recovery period",
                         # FIXME - make lenth of recovery variable
                         paste(7,"days after start of Element"),
                         paste("P",7,"D",sep=""))        
    aRow <- aRow + 1
  }
  # save final
  teOut <<- tOut
  # add to set of data
  addToSet("TE","TRIAL ELEMENTS","teOut")
}
