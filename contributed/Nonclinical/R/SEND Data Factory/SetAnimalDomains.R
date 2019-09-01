# These functions work together with the SendDataFactory


getArmFromSet <- function(inSetCD) {
  # get arm given set
  as.character(txOut[txOut$TXPARMCD=="ARMCD" & txOut$SETCD==inSetCD,]$TXVAL[1])
}

getStartDate <- function() {
  # get start date for all animals
  as.character(TSFromFile[TSFromFile$TSPARMCD=="STSTDTC",]$TSVAL)
}
getEndDate <- function() {
  # get end date for all animals
  aDuration <-(TSFromFile[TSFromFile$TSPARMCD=="TRMSAC",]$TSVAL)
  pattern <- gregexpr('[0-9]+',aDuration)
  studyLength <- as.integer(regmatches(aDuration,pattern))
  as.character(as.Date(getStartDate())+studyLength)
}

getElementDuration <- function(anElement) {
  aDuration <-(teOut[teOut$ETCD==anElement,]$TEDUR[1])
  pattern <- gregexpr('[0-9]+',aDuration)
  as.integer(regmatches(aDuration,pattern))
}

getEndDateTK <- function() {
  # get end date for all animals
  # assume TK just 5 days
  TKLength <- 5
  as.character(as.Date(getStartDate())+TKLength)
}
getAgeNumber <- function() {
  anAge <-as.character((TSFromFile[TSFromFile$TSPARMCD=="AGETXT",]$TSVAL))
  #remove Days or Weeks
  anAge <- sub("DAYS","",toupper(anAge))
  sub(" ","",toupper(anAge))
}

getAgeUnits  <- function() {
  anAge <-as.character((TSFromFile[TSFromFile$TSPARMCD=="AGETXT",]$TSVAL))
  #return Days or Weeks
  returnUnits <- ""
  theUnits <- "DAYS"
  if (grepl(theUnits,toupper(anAge))) { returnUnits <- theUnits }
  theUnits <- "WEEKS"
  if (grepl(theUnits,toupper(anAge))) { returnUnits <- theUnits }
  returnUnits
}

#
setDMFile <- function(input) {
  # create data frame based on structure
  aDomain <- "DM"

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
  theArm <- 1
  hasTK <- FALSE
  if (as.integer(input$TKanimalsPerGroup)>0 ) {hasTK<-TRUE}
  # loop for each group
  for (theGroup in input$treatment) {
    theSet <- theArm
    # if has TK, doubles the number of sets
    if (hasTK) {
      theSet <- theArm*2-1
    }
    # loop for each animal per group, males and females (assume same number)
    for (aSex in input$sex) {
      for (nAnimal in 1:as.integer(input$animalsPerGroup)) {
        tOut[aRow,]$STUDYID <<- input$studyName
        tOut[aRow,]$DOMAIN <<- aDomain
        tOut[aRow,]$USUBJID <<- paste(input$studyName,aRow,sep="-")
        tOut[aRow,]$SUBJID <<- aRow
        tOut[aRow,]$RFSTDTC <<- getStartDate()
        tOut[aRow,]$RFENDTC <<- getEndDate()
        tOut[aRow,]$AGETXT <<- getAgeNumber()
        tOut[aRow,]$AGEU <<- getAgeUnits()
        tOut[aRow,]$SEX <<- substring(aSex,1,1)
        tOut[aRow,]$ARMCD <<- theArm
        tOut[aRow,]$ARM <<- taOut[taOut$ARMCD==theArm,]$ARM[1]
        tOut[aRow,]$SETCD <<- theSet
        aRow <- aRow + 1
    } # end animal loop
    } # end of sex loop
    if (hasTK) {
      # TK is the next set number
      theTKSet <- theSet+1
      for (aSex in input$sex) {
        for (nAnimal in 1:as.integer(input$TKanimalsPerGroup)) {
          tOut[aRow,]$STUDYID <<- input$studyName
          tOut[aRow,]$DOMAIN <<- aDomain
          tOut[aRow,]$USUBJID <<- paste(input$studyName,aRow,sep="-")
          tOut[aRow,]$SUBJID <<- aRow
          tOut[aRow,]$RFSTDTC <<- getStartDate()
          tOut[aRow,]$RFENDTC <<- getEndDate()
          tOut[aRow,]$AGETXT <<- getAgeNumber()
          tOut[aRow,]$AGEU <<- getAgeUnits()
          tOut[aRow,]$SEX <<- substring(aSex,1,1)
          tOut[aRow,]$ARMCD <<- theArm
          tOut[aRow,]$ARM <<- taOut[taOut$ARMCD==theArm,]$ARM[1]
          tOut[aRow,]$SETCD <<- theTKSet
          aRow <- aRow + 1
    } # end TK animal loop
    } # end of sex loop
    } # end of TK check
    theArm <- theArm + 1
  } # end group loop
  dmOut <<- tOut
  # add to set of data
  addToSet("DM","Demographics","dmOut")
}

#
setSEFile <- function(input) {
  # create data frame based on structure
  aDomain <- "SE"
  
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
  theAnimal <- 1
  theArm <- 1
  hasTK <- FALSE
  if (as.integer(input$TKanimalsPerGroup)>0 ) {hasTK<-TRUE}
  # loop for each group
  for (theGroup in input$treatment) {
    theSet <- theArm
    # if has TK, doubles the number of sets
    if (hasTK) {
      theSet <- theArm*2-1
    }
    TKLoop <- 1
    if (hasTK) { TKLoop <- 2 }
    print(paste("Looping for this many subsets",TKLoop))
    for (addTK in 1:TKLoop) {  
      print(paste("Subset:",addTK))
      print(paste("Looping for this many sexes",input$sex))
      for (aSex in input$sex) {
        print(paste("Sex:",aSex))
        # loop for each animal per group, males and females (assume same number)
         animalsPerGroup <- input$animalsPerGroup
         if (addTK==2) {animalsPerGroup <- input$TKanimalsPerGroup}
         print(paste("Looping for this many animals per group",animalsPerGroup))
         for (nAnimal in 1:as.integer(animalsPerGroup)) {
          # set animal start0
          elementStart <- as.Date(getStartDate())
          # get animal set
          aSet <- dmOut$SETCD[theAnimal]
          # get set arm
          anArm <- getArmFromSet(aSet)
          # get elements this animal goes through based on its set
          print(paste("Looping for this many elements per animsl",taOut[taOut$ARMCD==anArm,]$ETCD))
          for (anElement in taOut[taOut$ARMCD==anArm,]$ETCD) {
            print(paste("Element:",anElement))
            elementName <- teOut[teOut$ETCD==anElement,]$ELEMENT
              elementEnd <- elementStart + getElementDuration(anElement)
              tOut[aRow,] <<- list(input$studyName,
                                    aDomain,
                                    paste(input$studyName,theAnimal,sep="-"),
                                    aRow,
                                    anElement,
                                    elementName,
                                    as.character(elementStart),
                                    as.character(elementEnd)
              )        
            aRow <- aRow + 1
            # next element start is the date the previous eneded
            elementStart <- elementEnd
          } # end of element loop
          theAnimal <- theAnimal + 1
      } # end animal loop
    } # end of sex loop
    } # end of add TK loop
    theArm <- theArm + 1
    print(paste("Complete SE domain for group:",theGroup))
  } # end group loop
  seOut <<- tOut  
  # add to set of data
  addToSet("SE","Subject Elements","seOut")
}
