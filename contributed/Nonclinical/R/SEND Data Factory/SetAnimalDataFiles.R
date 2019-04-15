# These functions work together with the SendDataFactory

#
getTestCDs <- function(aDomain) {
  # FIXME read these from a configuration file combined with on screen choices
  switch(aDomain,
         "BW" = {aList <- c("BW","TERMBW")},
         "CL" = {aList <- c("GO","CS")},
         "LB" = {aList <- c("ALB","ALP","WBC","RBC","PH","CREAT","NEUT")},
         "MI" = {aList <- c("MIEXAM")},
         "PM" = {aList <- c("LENGTH","WIDTH","ULCER")},
         "MA" = {aList <- c("GROSPATH")},
         "OM" = {aList <- c("WEIGHT","OWBW","OWBR")},
         "PC" = {aList <- c(paste(theTestArticle,"_MET",sep=""),paste(theTestArticle,"_PAR",sep=""))} 
  )
  aList
}

#check if data frame has a DY component
hasDays <- function(aDF,aDomain) {
  aDY <- paste(aDomain,"DY",sep="")
  aResult <- (aDY %in% labels(aDF)[2][[1]] )
  aResult
}

createAnimalDataDomain <- function(input,aDomain,aDescription,aDFName) {
  theColumns <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Column
  theLabels <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Label
  # Creating the data fames
  print(paste("Creating the data frames with columns: ",theColumns))
  aDF <<- setNames(data.frame(matrix(ncol = length(theColumns), nrow = 1)),
                     theColumns
  )
  # set other global variables for use
  theTestArticle <<- input$testArticle
  # set labels for each field 
  index <- 1
  for (aColumn in theColumns) {
    Hmisc::label(aDF[[index]]) <<- theLabels[index]
    index <- index + 1
  }
  aRow <- 1
  # set some defaults
  if (is.null(input$sex)) {
    sexList <- c("Male","Female")
  } else {
    sexList <- input$sex
  }
    
  if (is.null(input$treatment)) {
    treatmentList <- c("Control Group")
  }  else {
    treatmentList <- input$treatment
  }
  if (is.null(input$animalsPerGroup)) {
    animalsList <- 10
  }  else {
    animalsList <- input$animalsPerGroup
  }
  
  print(paste("Looping by SEX:",sexList))
  for (aSex in sexList) {
    # now loop on all groups
    print(paste("Looping by treatment:",treatmentList))
    for (aTreatment in treatmentList) {
      # now loop on all animals for which we want to create rows
      print(paste("Looping by animals per group:",animalsList))
      for (anAnimal in 1:animalsList) {
        # if this domain has days, loop over days
        if (hasDays(aDF,aDomain)) {
          # FIXME - use study length from configuration or user selection
          endDay <- 10
        } else {
          endDay <- 1  
        }
        for (iDay in 1:endDay) {
          # loop over the tests for this domain
          for (aTestCD in getTestCDs(aDomain)) {
            # print(paste(" About to create row animal for",aTestCD,input$studyName))
            aRowList <<- createRowAnimal(aSex,aTreatment,anAnimal,aDF,aRow,aDomain,
            input$studyName,aTestCD,iDay)
            # replace empties with NA
            # print(paste(" inserting",aRowList))
            aRowList <<- sub("$^", NA, aRowList)
            aDF[aRow,] <<- aRowList        
            aRow <- aRow + 1
          } # end of test loop
        } # end of day loop
      } # end of animal loop
    } # end of treament loop
  } # end of sex loop
  aDF
}

createRowAnimal <- function(aSex,aTreatment,anAnimal,aDF,aRow,aDomain,aStudyID,
                            aTestCD,iDay) {
 aList <- list() 
 # print(paste("Creating row for:",aSex,aTreatment,anAnimal,aRow,aDomain,aStudyID,aTestCD))
 # print(paste("Getting values for:",labels(aDF)[2][[1]]))
 # loop on fields in data frame
 for (aCol in labels(aDF)[2][[1]]) {
   # add value to the list of column values, based upon the column name
   columnData <- getColumnData(aCol,aSex,aTreatment,anAnimal,aRow,aDomain,
                                aStudyID,aTestCD,iDay)
   aList <- c(aList, columnData)
 }
 # print(paste("  values are:",aList))
 # return the list of fields
 aList
}

setAnimalDataFiles <- function(input) {
    # Make a list of domains to handle
    DomainsList <- c("BW","CL","LB","MA","MI","OM","PC","PM")
    # create data frame based on structure
    # Loop on num domains
    index <- 0
    for (aDomain in DomainsList) {
      index <- index + 1
      percentOfList <- index/length(DomainsList)
      setProgress(value=percentOfList,message=paste('Producting dataset: ',aDomain))
      aDFName <- paste(aDomain,"Out",sep="")
      aDescription <- "FIXME - read description from SENDIG"
      aDFReturned <<- createAnimalDataDomain(input,aDomain,aDescription,aDFName)
      # now reset the name of this dataframe to keep it
      assign(aDFName, aDFReturned, envir=.GlobalEnv)
      addToSet(aDomain,aDescription,aDFName)
    }
}
