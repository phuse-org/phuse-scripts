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

# get maximum value for a column as a date
getAnimalMaxDateColumn <- function(aDf,aUsub,aCol) {
  aFilter <- aDf[aDf$USUBJID==aUsub,]
  theMax <- max(as.Date(aFilter[,aCol]))
  values <- as.character(theMax)
  values[1]
}

# get value from a second column based upon maximum value for a column as a date
getAnimalMaxDateColumnOther <- function(aDf,aUsub,aCol1,aCol2) {
  aFilter <- aDf[aDf$USUBJID==aUsub,]
  theMax <- max(as.Date(aFilter[,aCol1]))
  values <-  aFilter[aFilter[aCol1]==as.character(theMax),][aCol2]
  values[1]
}

# get value from a column filtered to the animal
getAnimalColumn <- function(aDf,aUsub,aCol) {
  aFilter <- aDf[aDf$USUBJID==aUsub,]
  values <- as.character(aFilter[,aCol])
  values[1]
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
          tOut[aRow,]$SPECIES <<- input$species
          tOut[aRow,]$STRAIN <<- input$strain
          tOut[aRow,]$ARMCD <<- theArm
          tOut[aRow,]$ARM <<- taOut[taOut$ARMCD==theArm,]$ARM[1]
          tOut[aRow,]$SETCD <<- theTKSet
          aRow <- aRow + 1
    } # end TK animal loop
    } # end of sex loop
    } # end of TK check
    theArm <- theArm + 1
  } # end group loop
  dmOut <<- tOut[, checkCore(tOut)]
  # add to set of data
  addToSet("DM","Demographics","dmOut")
}

setDSFile <- function(input) {
  # create data frame based on structure
  print(paste("FIXME DS","working on ds"))
  aDomain <- "DS"

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
        aUSUBJID <-  paste(input$studyName,aRow,sep="-")
        tOut[aRow,]$USUBJID <<- aUSUBJID
		    tOut[aRow,]$DSSEQ <<- aRow
		    # get last element for animal
		    lastElement <- getAnimalMaxDateColumnOther(seOut,aUSUBJID,"SEENDTC","ELEMENT")
		    if (as.character(lastElement$ELEMENT)=="Recovery period") {
		      tOut[aRow,]$DSDECOD <<- "RECOVERY SACRIFICE"
		      tOut[aRow,]$DSNOMLBL <<- "Recovery Sacrifice" 
		    } else {
		      tOut[aRow,]$DSDECOD <<- "TERMINAL SACRIFICE"
		      tOut[aRow,]$DSNOMLBL <<- "Terminal Sacrifice" 
		    }
    		tOut[aRow,]$DSTERM <<- "Exsanguinated"
    		# get last date on study
    		aDSSTDTC <- getAnimalMaxDateColumn(seOut,aUSUBJID,"SEENDTC")
    		tOut[aRow,]$DSSTDTC <<- aDSSTDTC
    		# get number of days on study
    		aDiffDate <- as.character(as.Date(aDSSTDTC) - as.Date(getAnimalColumn(dmOut,aUSUBJID,"RFSTDTC")))
    		tOut[aRow,]$DSSTDY <<- aDiffDate
		    tOut[aRow,]$DSNOMDY <<- aDiffDate
        aRow <- aRow + 1
    } # end animal loop
    } # end of sex loop
    print(paste("FIXME DS","Ds so far"))
    print(head(tOut))
    if (hasTK) {
      # TK is the next set number
      theTKSet <- theSet+1
      for (aSex in input$sex) {
        for (nAnimal in 1:as.integer(input$TKanimalsPerGroup)) {
          tOut[aRow,]$STUDYID <<- input$studyName
          tOut[aRow,]$DOMAIN <<- aDomain
          aUSUBJID <-  paste(input$studyName,aRow,sep="-")
          tOut[aRow,]$USUBJID <<- aUSUBJID
          tOut[aRow,]$DSSEQ <<- aRow
          tOut[aRow,]$DSTERM <<- "Exsanguinated"
          # get last element for animal
          lastElement <- getAnimalMaxDateColumnOther(seOut,aUSUBJID,"SEENDTC","ELEMENT")
          if (as.character(lastElement$ELEMENT)=="Recovery period") {
            tOut[aRow,]$DSDECOD <<- "RECOVERY SACRIFICE"
            tOut[aRow,]$DSNOMLBL <<- "Recovery Sacrifice" 
          } else {
            tOut[aRow,]$DSDECOD <<- "TERMINAL SACRIFICE"
            tOut[aRow,]$DSNOMLBL <<- "Terminal Sacrifice" 
          }
          # get last date on study
          aDSSTDTC <- getAnimalMaxDateColumn(seOut,aUSUBJID,"SEENDTC")
          tOut[aRow,]$DSSTDTC <<- aDSSTDTC
          # get number of days on study
          aDiffDate <- as.character(as.Date(aDSSTDTC) - as.Date(getAnimalColumn(dmOut,aUSUBJID,"RFSTDTC")))
          tOut[aRow,]$DSSTDY <<- aDiffDate
          tOut[aRow,]$DSNOMDY <<- aDiffDate
          tOut[aRow,]$DSNOMLBL <<- "Terminal Sacrifice" 
          aRow <- aRow + 1
        } # end TK animal loop
    } # end of sex loop
    } # end of TK check
    theArm <- theArm + 1
  } # end group loop
  dsOut <<- tOut[, checkCore(tOut)]
  # add to set of data
  addToSet("DS","Disposition","dsOut")
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
    # print(paste("Looping for this many subsets",TKLoop))
    for (addTK in 1:TKLoop) {  
      # print(paste("Subset:",addTK))
      # print(paste("Looping for this many sexes",input$sex))
      for (aSex in input$sex) {
        # print(paste("Sex:",aSex))
        # loop for each animal per group, males and females (assume same number)
         animalsPerGroup <- input$animalsPerGroup
         if (addTK==2) {animalsPerGroup <- input$TKanimalsPerGroup}
         # print(paste("Looping for this many animals per group",animalsPerGroup))
         for (nAnimal in 1:as.integer(animalsPerGroup)) {
          # set animal start0
          elementStart <- as.Date(getStartDate())
          # get animal set
          aSet <- dmOut$SETCD[theAnimal]
          # get set arm
          anArm <- getArmFromSet(aSet)
          # get elements this animal goes through based on its set
          # print(paste("Looping for this many elements per animal",taOut[taOut$ARMCD==anArm,]$ETCD))
          for (anElement in taOut[taOut$ARMCD==anArm,]$ETCD) {
            # print(paste("Element:",anElement))
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
    # print(paste("Complete SE domain for group:",theGroup))
  } # end group loop
  seOut <<- tOut[, checkCore(tOut)]
  # add to set of data
  addToSet("SE","Subject Elements","seOut")
}

setEXFile <- function(input) {
  
  aDomain <- "EX"
  theColumns <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Column
  theLabels <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Label
  tOut <<- setNames(data.frame(matrix(ncol = length(theColumns), nrow = 1)),
                    theColumns
  )
  
  dosingTable <- input$DoseTable
  
  print("Check TS table read from file with changes by user")
  print(TSFromFile)
  startDate <- TSFromFile[TSFromFile$TSPARMCD == "STSTDTC","TSVAL"]
  # TODO: make this more robust
  # Only implemented for single dose right now
  animalList <-as.character(dmOut$USUBJID)
  aRow <- 1  
  for(animal_i in animalList) {
    print(animal_i)
    sex_i <- dmOut[dmOut$USUBJID == animal_i, "SEX"]
    armcd_i <- dmOut[dmOut$USUBJID == animal_i, "ARMCD"]
    dose_level_i <- ifelse(sex_i == "M",
                           DoseFromFile[DoseFromFile$Dose.group == armcd_i, "Male.dose.level"], # Male dose level
                           DoseFromFile[DoseFromFile$Dose.group == armcd_i, "Female.dose.level"]) # Female dose level
    dose_unit_i <- ifelse(sex_i == "M",
                          as.character(DoseFromFile[DoseFromFile$Dose.group == armcd_i, "Male.dose.units"]), # Male dose unit
                          as.character(DoseFromFile[DoseFromFile$Dose.group == armcd_i, "Female.dose.units"])) # Female dose unit
   
      tOut[aRow,]$STUDYID <<- input$studyName
      tOut[aRow,]$DOMAIN <<- aDomain
      tOut[aRow,]$USUBJID <<- animal_i
      tOut[aRow,]$EXSEQ <<- aRow
      tOut[aRow,]$EXTRT <<- input$testArticle
      tOut[aRow,]$EXDOSE <<- dose_level_i
      tOut[aRow,]$EXDOSU <<- dose_unit_i
      tOut[aRow,]$EXDOSFRM <<- "UNKNOWN"
      tOut[aRow,]$EXDOSFRQ <<- "ONCE"
      tOut[aRow,]$EXROUTE <<- TSFromFile[TSFromFile$TSPARMCD == "ROUTE", "TSVAL"]
      tOut[aRow,]$EXLOT <<- "theLotNumber"
      tOut[aRow,]$EXTRTV <<- TSFromFile[TSFromFile$TSPARMCD == "TRTV", "TSVAL"]
      tOut[aRow,]$EXSTDTC <<- as.character(TSFromFile[TSFromFile$TSPARMCD == "STSTDTC", "TSVAL"])
      print(tOut[aRow,])
      aRow <- aRow + 1
  }
  
  exOut <<- tOut[, checkCore(tOut)]
  # add to set of data
  addToSet("EX","Exposure","exOut")
}
