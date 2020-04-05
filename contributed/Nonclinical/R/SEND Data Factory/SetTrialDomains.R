# These functions work together with the SendDataFactory

# convert ISO duration to days
DUR_to_days <- function(duration) {
  DUR_to_seconds(duration)/(24*3600)
}


isControl <- function(theGroup) {
  # return if this group has control in its name
  grepl(toupper("control"),toupper(theGroup))
}

getTrialSetInfoCount <- function(theGroup) {
  # return number of trial set information rows per set
  iCount <- 10
  if (!isControl(theGroup)) {iCount <- iCount -1}
  iCount
}

trialSetInfo <- function(iParam,whichColumn,theArm,theSetName,theGroup,isTK,numMales,numFemales,DoseFromFile) {
  txcodes <- c(
"ARMCD",
"SPGRPCD",
"GRPLBL",
"SETLBL",
"TRTDOS",
"TRTDOSU",
"TCNTRL",
"TKDESC",
"PLANMSUB",
"PLANFSUB")
txnames <- c(
"Arm Code",
"Sponsor-Defined Group Code",
"Group Label",
"Set Label",
"Dose Level",
"Dose Units",
"Control Type",
"Toxicokinetic Description",
"Planned Number of Male Subjects",
"Planned Number of Female Subjects")
  # skip control parameter if not a control group
  if (!isControl(theGroup)&&iParam>=7) { iParam <- iParam+1}
  # return values for parameters
  if (whichColumn==1) {  # code 
    txcodes[iParam]
  } else if (whichColumn==2) { # name
    txnames[iParam]
  } else { # value
    if (iParam==1) {theArm}     
    else if (iParam==2) {theArm}
    else if (iParam==3) {unique(taOut$ARM)[theArm]}
    else if (iParam==4) {theSetName}
    # assumes males and females same dose level
    else if (iParam==5) {DoseFromFile$Male.dose.level[theArm]}
    else if (iParam==6) {as.character(DoseFromFile$Male.dose.units[theArm])}
    else if (iParam==7) { # control type
      theGroup }
    else if (iParam==8) {
        if (isTK) { "TK"
        } else {"NONTK"}
      }
    else if (iParam==9) {
      numMales}
    else {numFemales }
      
    } # end of value else 
}

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
  iCount <- 1
  for (iDose in input$treatment) {
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
  if ("Recovery" %in% input$elementOptions ) {
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

setTAFile <- function(input) {
  # create data frame based on structure
  aDomain <- "TA"
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
  # assume 1 arm per dose group, first one is control
  nArm <- 1
  aRow <- 1
  for (iDose in input$treatment) {
  # within the arm, add treatment row if existing  
  anElement <- 1
  armName <- iDose
  screenElement <- 0
  isRecovery <- FALSE
  if ("Recovery" %in% input$elementOptions ) {isRecovery<-TRUE}
  if (nArm == 1) { armName <- "Control"}
  if ("Pre-treatment" %in% input$elementOptions ) {
    tOut[aRow,] <<- list(input$studyName,
                         aDomain,
                         nArm,
                         armName,
                         anElement,
                         teOut$ETCD[1],
                         teOut$ELEMENT[1],
                         paste("Randomized to Group",nArm),
                         "","Screen"
                         )        
    aRow <- aRow + 1
    screenElement <- 1
    anElement <- anElement + 1
  }
  TaBranch <- ""
  if (isRecovery) TaBranch <- "Start of Recovery"
  # within the arm, add the matching treatment row
  tOut[aRow,] <<- list(input$studyName,
                       aDomain,
                       nArm,
                       armName,
                       anElement,
                       teOut$ETCD[nArm+screenElement],
                       teOut$ELEMENT[nArm+screenElement],
                       TaBranch,
                       "","Treatment"
  )        
  aRow <- aRow + 1
  anElement <- anElement + 1
  
  if ("Recovery" %in% input$elementOptions ) {
    tOut[aRow,] <<- list(input$studyName,
                         aDomain,
                         nArm,
                         armName,
                         anElement,
                         teOut$ETCD[nrow(teOut)],
                         teOut$ELEMENT[nrow(teOut)],
                         "",
                         "","Recovery"
    )        
    aRow <- aRow + 1
    anElement <- anElement + 1
  } # recovery need check
    nArm <- nArm+1
  } # treatment count loop
  # save final
  taOut <<- tOut
  # add to set of data
  addToSet("TA","TRIAL ARMS","taOut")
}

setTXFile <- function(input) {
  # create data frame based on structure
  aDomain <- "TX"
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
  # assume 1 set per dosage group, double if TK
  nSet <- 1
  nArm <- 1
  aRow <- 1
  # assume for now no spare animals, and have males and females
  numGroups <- length(unique(taOut$ARM))
  numMales <- as.integer(input$animalsPerGroup)
  numFemales <- as.integer(input$animalsPerGroup)
  numMalesTK <- as.integer(input$TKanimalsPerGroup)
  numFemalesTK <- as.integer(input$TKanimalsPerGroup)
  for (theGroup in input$treatment) {
    # within the arm, add treatment row if existing  
    hasTK <- FALSE
    if (as.integer(input$TKanimalsPerGroup)>0 ) {hasTK<-TRUE}
    # within the set, add the matching treatment rows
    theArm <- unique(taOut$ARM)[nArm]
    name <- theArm 
    if (hasTK) { name <- paste(theArm,", Non-TK",sep="") }
    # non TK first
    for (iLoop in 1:getTrialSetInfoCount(theGroup)) {
      tOut[aRow,] <<- list(input$studyName,
                         aDomain,
                         nSet,
                         name,
                         aRow,
                         trialSetInfo(iLoop,1,nArm,name,theGroup,FALSE,numMales,numFemales,DoseFromFile),
                         trialSetInfo(iLoop,2,nArm,name,theGroup,FALSE,numMales,numFemales,DoseFromFile),
                         trialSetInfo(iLoop,3,nArm,name,theGroup,FALSE,numMales,numFemales,DoseFromFile)
    )        
    aRow <- aRow + 1
    } # iLoop
    
    nSet <- nSet+1
    if (hasTK) {
        name <- paste(theArm,", TK",sep="")
        for (iLoop in 1:getTrialSetInfoCount(theGroup)) {
          tOut[aRow,] <<- list(input$studyName,
                               aDomain,
                               nSet,
                               name,
                               aRow,
                               trialSetInfo(iLoop,1,nArm,name,theGroup,TRUE,numMalesTK,numFemalesTK,DoseFromFile),
                               trialSetInfo(iLoop,2,nArm,name,theGroup,TRUE,numMalesTK,numFemalesTK,DoseFromFile),
                               trialSetInfo(iLoop,3,nArm,name,theGroup,TRUE,numMalesTK,numFemalesTK,DoseFromFile)
          )        
      aRow <- aRow + 1
      } # iLoop
      nSet <- nSet+1
    } # hasTK
    nArm <- nArm+1
  } # treatment count loop
  # save final
  txOut <<- tOut
  # add to set of data
  addToSet("TX","TRIAL SETS","txOut")
}
