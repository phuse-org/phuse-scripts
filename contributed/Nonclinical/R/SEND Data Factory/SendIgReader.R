### Functions to create and read SENDIG data.frame

# read all domain structures
readDomainStructures <-function() {
  # read if it is not there yet
  if (!exists("bSENDIGRead")) {
    bSENDIGRead <<- FALSE
  } 
  # read from saved file
  # available since this was done and saved by developer: save(dfSENDIG,file=paste0(sourceDir,"/dfSENDIG.Rda"))
  # if (!bSENDIGRead) {
  #   print(" SENDIG being read from saved Rda file")
  #   load(file=paste0(sourceDir,"/dfSENDIG.Rda"))
  #    if (exists("dfSENDIG")) {
  #      print(" SENDIG successfully read")
  #      # ensure as global
  #      dfSENDIG <<- dfSENDIG
  #      bSENDIGRead <<- TRUE
  #    }
  # }
  if (!bSENDIGRead) {
    withProgress({
      setProgress(value=1,message='Reading domain structures from the SEND IG')
      readSENDIG()
    })
  }
}

# This function checks columns to verify if the column needs to be included
# based upon the columns core requirement. Returns a logical vector. TRUE
# if it should be included, FALSE otherwise
# TODO: This isn't very effiecent
checkCore <- function(dataset) {
  
  # Create TF vector for permisable columns
  domain_i <- unique(dataset$DOMAIN)
  cores <- dfSENDIG[dfSENDIG$Domain == domain_i, "Expectancy"]
  isPerm <- cores == "Perm"
  
  # Create TF vector for blank cols
  blankCol <- apply(dataset, 2, function(x) all(is.na(x)))
  
  # Return vector where both conditions are true.
  !(isPerm & blankCol)
}


isDomainStart <- function(aLine) {
  # Fine the description start
  theDomain <- ""
  pattern <- ".xpt, "
  aLocation <- gregexpr(pattern =pattern,aLine)[[1]][1]
  # special for the BW domain due to error in SENDIG3.1
  pattern2 <- "+, Body Weight - Findings"
  aLocation2 <- gregexpr(pattern =pattern2,aLine)[[1]][1]
  # if found, and within 8 of begining of line is a table of
  # defining a domain
  if (aLocation>0 & aLocation<9) {
    # found a table start
    # set the domain name
    theDomain <- toupper(substring(aLine,1,aLocation-1))
    # print(paste("Reading SENDIG for theDomain",theDomain,aLine))
  } else if (aLocation2>0 & aLocation2<9) {
    theDomain <- "BW"
    # print(paste("Reading SENDIG for theDomain",theDomain,aLine))
  }
  theDomain
}

addDomainRow <- function(inLine,inDomain) {
  bResult <- FALSE
  # see if you can split the line into "Column","Type","Label","Codelist","Expectancy"
  Headerpattern1 <- "^Variable {1,}Controlled Terms"
  Headerpattern2 <- "^Variable Label"
  Headerpattern3 <- "^Variable Name"
  Headerpattern4 <- "^Name *Codelist"
  Headerpattern5 <- "^Controlled Terms"
  aLocation1 <- gregexpr(pattern =Headerpattern1,trimws(inLine))[[1]][1]
  aLocation2 <- gregexpr(pattern =Headerpattern2,trimws(inLine))[[1]][1]
  aLocation3 <- gregexpr(pattern =Headerpattern3,trimws(inLine))[[1]][1]
  aLocation4 <- gregexpr(pattern =Headerpattern4,trimws(inLine))[[1]][1]
  aLocation5 <- gregexpr(pattern =Headerpattern5,trimws(inLine))[[1]][1]
  if (aLocation1>0 | aLocation2>0 | aLocation3>0| aLocation4>0| aLocation5>0) {
    # Header line found, return true since still within the table
    bResult <- TRUE
    # print (paste("Debug Header found:",inLine))
    # tables end with a number for the next section
  } else if (!is.numeric(substring(inLine,1,1)) ) {
    aSplit <<- strsplit(inLine,'\\s{2,}')
    # if (inDomain=="CV") print (paste("debug A split created",aSplit," for line: ",inLine))
    dataFound <- FALSE
    newRow <- FALSE
    
    # if the first phrase has field description and merged together
    firstPhrase <-  aSplit[[1]][[1]]
    aLoc <- gregexpr(pattern =" ",trimws(firstPhrase))[[1]][1]
    if (substring(firstPhrase,1,1)==" " & aLoc>1) {
      # split it further
      aSplit[[1]] <<- c(substring(firstPhrase,2,aLoc),
                        substring(firstPhrase,aLoc+2),aSplit[[1]][-1] )
    }
    
    # if expectancy is merged to the end of the split, separate it out
    aLength <- length(aSplit[[1]])
    lastString <- aSplit[[1]][[aLength]]
    lastWord <- tail(strsplit(lastString,split=" ")[[1]],1)
    if ( nchar(lastString)>(nchar(lastWord)+1) & 
         (lastWord == "Req" | lastWord == "Exp" | lastWord == "Perm" )) {
      aSplit[[1]][[aLength+1]] <<- lastWord
      # end remove last word from the previous
      aSplit[[1]][[aLength]] <<- gsub("\\s*\\w*$", "",aSplit[[1]][[aLength]])
    }
    
    # special case of type and codelist making it combine down to 5
    #if 1st ends with Char ISO 8601 and length is 5, make it a 6 by spliting out type and codelist
    if (length(aSplit[[1]])==5) {
      aPart <- aSplit[[1]][[2]]
      aLoc <- gregexpr(pattern =" Char ISO 8601",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],substring(aPart,1,aLoc-1),
                     "Char",
                     "ISO 8601",aSplit[[1]][[3]],
                     aSplit[[1]][[4]],aSplit[[1]][[5]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of type and codelist making it combine down to 5
    #if 2nd has Char ( and length is 5, make it a 6 by spliting out type and codelist
    if (length(aSplit[[1]])==5) {
      aPart <- aSplit[[1]][[2]]
      aLoc <- gregexpr(pattern =" Char [(]",aPart)[[1]][1]
      if (aLoc>1) { 
        rest <- substring(aPart,aLoc+1)
        aPart2 <- strsplit(rest,split=" ")
        theList <- c(aSplit[[1]][[1]],substring(aPart,1,aLoc-1),
                     "Char",
                     aPart2[[1]][[2]],aSplit[[1]][[3]],
                     aSplit[[1]][[4]],aSplit[[1]][[5]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    #if 1st starts with blank and ends with Char ISO 8601
    if (length(aSplit[[1]])==4) {
      aPart <- aSplit[[1]][[1]]
      aLocF <- gregexpr(pattern ="^ ",aPart)[[1]][1]
      aLoc <- gregexpr(pattern =" Char ISO 8601",aPart)[[1]][1]
      if (aLoc>1 & aLocF==1) {
        aLocS <- gregexpr(pattern =" ",substring(aPart,2))[[1]][1]
        theList <- c(substring(aPart,2,aLocS-1),substring(aPart,aLocS+1,aLoc-1),
                     "Char",
                     "ISO 8601",aSplit[[1]][[2]],
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    #if 1st starts with blank and ends with Char ISO 8601
    if (length(aSplit[[1]])==4) {
      aPart <- aSplit[[1]][[1]]
      aLocF <- gregexpr(pattern ="^ ",aPart)[[1]][1]
      aLoc <- gregexpr(pattern =" Char ISO 8601",aPart)[[1]][1]
      if (aLoc>1 & aLocF==1) {
        aLocS <- gregexpr(pattern =" ",substring(aPart,2))[[1]][1]
        theList <- c(substring(aPart,2,aLocS),substring(aPart,aLocS+2,aLoc-1),
                     "Char",
                     "ISO 8601",aSplit[[1]][[2]],
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    #if 1st starts with blank and ends with Char
    if (length(aSplit[[1]])==4) {
      aPart <- aSplit[[1]][[1]]
      aLocF <- gregexpr(pattern ="^ ",aPart)[[1]][1]
      aLoc <- gregexpr(pattern =" Char$",aPart)[[1]][1]
      if (aLoc>1 & aLocF==1) {
        aLocS <- gregexpr(pattern =" ",substring(aPart,2))[[1]][1]
        theList <- c(substring(aPart,2,aLocS),substring(aPart,aLocS+2,aLoc-1),
                     "Char",
                     aSplit[[1]][[2]],
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    # where column name is merged with description
    if (length(aSplit[[1]])==4) {
      aPart <- trimws(aSplit[[1]][[1]])
      aLoc <- gregexpr(pattern =" ",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(substring(aPart,1,aLoc-1),substring(aPart,aLoc+1),
                     aSplit[[1]][[2]],
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    # where column type is merged with the description
    if (length(aSplit[[1]])==4) {
      aPart <- trimws(aSplit[[1]][[2]])
      aLoc <- gregexpr(pattern ="Num$",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],
                     substring(aPart,1,aLoc-1),substring(aPart,aLoc+1),
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    # where lookup and column type is merged with the description
    if (length(aSplit[[1]])==4) {
      aPart <- trimws(aSplit[[1]][[2]])
      aLoc <- gregexpr(pattern ="Char [(]",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],
                     substring(aPart,1,aLoc-1),
                     substring(aPart,aLoc,aLoc+4),
                     substring(aPart,aLoc+5),
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    # where lookup and column type and fixed value is merged with the description
    if (length(aSplit[[1]])==4) {
      aPart <- trimws(aSplit[[1]][[2]])
      aLoc <- gregexpr(pattern ="Char T",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],
                     substring(aPart,1,aLoc-1),
                     substring(aPart,aLoc,aLoc+4),
                     substring(aPart,aLoc+5),
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    # where lookup and column type and fixed value is merged with the description
    if (length(aSplit[[1]])==4) {
      aPart <- trimws(aSplit[[1]][[2]])
      aLoc <- gregexpr(pattern ="Char D",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],
                     substring(aPart,1,aLoc-1),
                     substring(aPart,aLoc,aLoc+4),
                     substring(aPart,aLoc+5),
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    # special case of fields merged to first making it combine down to 4
    # where column type is merged with the description
    if (length(aSplit[[1]])==4) {
      aPart <- trimws(aSplit[[1]][[2]])
      aLoc <- gregexpr(pattern ="Char$",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],
                     substring(aPart,1,aLoc-1),substring(aPart,aLoc+1),
                     aSplit[[1]][[3]],aSplit[[1]][[4]])
        aSplit[[1]] <<- theList
      }
    }
    
    if (length(aSplit[[1]])==5) {
      aPart <- aSplit[[1]][[2]]
      # special case if type at end of 2nd field
      aLoc <- gregexpr(pattern =" Char$",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],substring(aPart,1,aLoc-1),
                     "Char",
                     aSplit[[1]][[3]],
                     aSplit[[1]][[4]],aSplit[[1]][[5]])
        aSplit[[1]] <<- theList
      }
    }
    
    if (length(aSplit[[1]])==5) {
      aPart <- aSplit[[1]][[2]]
      # special case if type at end of 2nd field
      aLoc <- gregexpr(pattern =" Num$",aPart)[[1]][1]
      if (aLoc>1) {
        theList <- c(aSplit[[1]][[1]],substring(aPart,1,aLoc-1),
                     "Num",
                     aSplit[[1]][[3]],
                     aSplit[[1]][[4]],aSplit[[1]][[5]])
        aSplit[[1]] <<- theList
      }
    }
    
    # some have no code list , making a new row
    if (length(aSplit[[1]])==5) {
      dataFound <- TRUE
      newRow <- TRUE
      aColumn <- trimws(aSplit[[1]][[1]])
      aLabel <- aSplit[[1]][[2]]
      aType <- aSplit[[1]][[3]]
      # sometimes the codelist comes merged with the type
      aTypeLoc <- gregexpr(pattern =" ",aType)[[1]][1]
      if (aTypeLoc>1) {
        aCodeList <- substring(aType,aTypeLoc+1)
        aType <- substring(aType,1,aTypeLoc-1)       
      } else {
        aCodeList <- ""
      }
      anExpectancy <- aSplit[[1]][[5]]
    }
    # if codelist, making a new row
    if (length(aSplit[[1]])==6) {
      dataFound <- TRUE
      newRow <- TRUE
      aColumn <- trimws(aSplit[[1]][[1]])
      aLabel <- aSplit[[1]][[2]]
      aType <- aSplit[[1]][[3]]
      # check if space within type
      aLocType <- gregexpr(pattern =" ",aType)[[1]][1]
      # if Topic or Identifier or Timing, Record or Synonym or Rule, these are Role field
      aWord <- aSplit[[1]][[4]]
      if (aWord != "Topic" & aWord != "Identifier" & aWord != "Result" & aWord != "Timing" &aWord != "Record" &aWord != "Grouping" &aWord != "Synonym" & aWord != "Rule"& aWord != "Variable"){
        aCodeList <- aSplit[[1]][[4]]
        # If there is a space in the type, then second part is the codelist
      } else if (aLocType>1) {
        aCodeList <- substring(aType,aLocType+1)
        aType <- substring(aType,1,aLocType-1)
      } else {
        aCodeList <- ""
      }
      anExpectancy <- aSplit[[1]][[6]]
    } # end of length check 6
    # if codelist, making a new row
    if (length(aSplit[[1]])==7) {
      dataFound <- TRUE
      newRow <- TRUE
      aColumn <- trimws(aSplit[[1]][[1]])
      aLabel <- aSplit[[1]][[2]]
      aType <- aSplit[[1]][[3]]
      aCodeList <- aSplit[[1]][[4]]
      anExpectancy <- aSplit[[1]][[7]]
    } # end of length check 7
    # if 2 or 3 or 4 in length and first is empty, is a continuation of the label from previous row
    if ((length(aSplit[[1]])==2 | length(aSplit[[1]])==3
         | length(aSplit[[1]])==4) & (aSplit[[1]][[1]]=="")) {
      # was part of table, discarding because is only about cdisc notes
      dataFound <- TRUE
      # check if should still be adding to row or already finished with description
      if (exists("addMoreToRow") & addMoreToRow<3) {
        
        # add at most 2 more to row, no variables have more than 3 rows for the label
        addMoreToRow <<- addMoreToRow + 1
        
        # special case, not true that we want to append if starts with certain lines
        aLabel <- aSplit[[1]][[2]]
        aLabel <- trimws(aLabel)
        checkList <- c(
          "have,",
          "in BG",
          "individual,",
          "or AGE",
          "unrelated,",
          "CVSTRESN.",
          "CVTPTNUM ",
          "date/time",
          "[(]DM[)] domain",
          "[(]without location",
          "1 FIRST",
          "ABNORMAL",
          "accomodate",
          "Acid,",
          "administered",
          "after dosing",
          "algorithm",
          "also be",
          "An example",
          "and CVENINT ",
          "and NEGATIVE",
          "any valid",
          "as an ISO",
          "be any valid",
          "be either",
          "be left",
          "be null",
          "be relative",
          "BEAGLE",
          "because",
          "being submitted",
          "beyond",
          "branch",
          "branch",
          "can be",
          "calculations",
          "character format",
          "codelist",
          "Codelist, or",
          "collected",
          "COVAL1",
          "define",
          "Demographics ",
          "description",
          "designations",
          "disposition,",
          "domain",
          "DOSE",
          "dose",
          "during",
          "--DY",
          "each subject",
          "example",
          "Element;",
          "Example",
          "excluded",
          "external",
          "EXTPTNUM and",
          "findings",
          "flag",
          "for the",
          "for calc",
          "For example",
          "format",
          "genetic",
          "group",
          "have",
          "hours [(]",
          "identification",
          "in BWSTRESN",
          "in LBSTRESN",
          "in FWSTRESN",
          "in OMSTRESN",
          "in the data",
          "in the LBSPEC",
          "in the OMSPEC",
          "in ISO format",
          "include",
          "indicated",
          "individual",
          "interval",
          "is not the",
          "INVESTIGATOR", 
          "LBTPTNUM and ",
          "letters",
          "list",
          "MALIGNANT",
          "mass identification",
          "metadata",
          "might",
          "multiple",
          "must",
          "NONE",
          "not the treatment",
          "number",
          "of test",
          "only",
          "or ,",
          "origin",
          "OTHER",
          "PCSTRESC is ",
          "PCSTRESN. For",
          "PCTPTNUM and ",
          "period of",
          "PMSTAT.",
          "POOLID",
          "point",
          "populate",
          "Previous dose",
          "PREVIOUS",
          "Pparg",
          "primates",
          "PT1",
          "Qualifier",
          "QNAM may", 
          "record",
          "reference",
          "represent",
          "results",
          "REVIEW, ",
          "rule",
          "See EGTPTNUM",
          "SEGMENT,",
          "semantic",
          "sequential",
          "sets",
          "should",
          "site",
          "specified in",
          "sponsor",
          "Sponsors should",
          "submi",
          "subject",
          "such as",
          "terminology",
          "Terminology codelist",
          "Terminology list.",
          "terms, utilizing",
          "The algorithm",
          "the in-life",
          "the reference",
          "The sponsor",
          "the sponsor",
          "the Demographics",
          "the experiment", 
          "the test",
          "the treatment",
          "The value",
          "the value",
          "this domain",
          "This is ",
          "those",
          "time",
          "to represent",
          "to the sponsor",
          "to Treatment",
          "Treatment, ",
          "unique ",
          "Unknown.",
          "unless",
          "underscores",
          "unrelated",
          "used",
          "USUBJID",
          "UNCONSTRAINED",
          "value",
          "variable",
          "Variable",
          "VETERINARIAN",
          "VSTESTCD cannot",
          "when identifying",
          "whichever",
          "with a number",
          "within",
          "Wt",
          ".",
          "4.3.6.2",
          "[(]e.g.",
          "[^0-9]-PT1",
          "[^0-9]1TEST",
          "[^0-9]Treated")
        # check if any match
        aMatch <- FALSE
        for (aPhrase in checkList) {
          if (gregexpr(pattern =aPhrase,aLabel)[[1]][1]==1) aMatch <- TRUE
        }
        if (!aMatch){
          newRow <- FALSE
          dataFound <- TRUE
          dfSENDIG[nrow(dfSENDIG),]$Label <<- paste(dfSENDIG[nrow(dfSENDIG),]$Label,aLabel)
          # DEBUG - use this next line to clean up the description labels
          # dfSENDIG[nrow(dfSENDIG),]$Label <<- paste(dfSENDIG[nrow(dfSENDIG),]$Label,"END?",aLabel)
        }
      } # end of check if addMoreToRow
    } # end of 2,3,4 length
    # if 2 and starts with copyright character
    if (length(aSplit[[1]])==2 & (substring(aSplit[[1]][[1]],1,1)=='\u00A9')) {
      # continues within table still
      dataFound <- TRUE
    } # end of page break check
    # if 2 and starts with "Final"
    if (length(aSplit[[1]])==2 & (aSplit[[1]][[1]]=="Final")) {
      # continues within table still
      dataFound <- TRUE
    } # end of page break check
    # if 1 and starts with "CDISC Standard"
    if (length(aSplit[[1]])==1 & (substring(aSplit[[1]][[1]],1,14)=="CDISC Standard")) {
      # continues within table still
      dataFound <- TRUE
    } # end of new page check
    if (length(aSplit[[1]])==1 & (substring(aSplit[[1]][[1]],1,11)=="Tabulation.")) {
      # continues within table still
      dataFound <- TRUE
    } # end of new page check
    
    # add this row
    if (newRow) {
      bResult <- TRUE
      dfSENDIG[nrow(dfSENDIG) + 1,] <<- list(inDomain,aColumn,aType,aLabel,aCodeList,anExpectancy)
      addMoreToRow <<- 0
    }
    if (dataFound) bResult <- TRUE
  } # end of if not numeric
  # debug -
  if (inDomain=="PP") {  # Debug on parsing 
    print(paste("-----------For domain: ",inDomain))
    print(paste(" the length is:",length(aSplit[[1]])))
    print(inLine)
    print(aSplit)
    lastSplit <<- aSplit
  }
  bResult
}



convertIGRaw <- function (SENDIGRaw) {
  # using raw text, search and create structure dataframe
  dfSENDIG <<- setNames(data.frame(matrix(ncol = 6, nrow = 1)),
                        c("Domain","Column","Type","Label",
                          "Codelist","Expectancy"))
  # loop through raw looking for the start of a description
  # states are "Searching","FoundDomain"
  aState <- "Searching"
  aCount <- 0
  withProgress({
    for (aPage in SENDIGRaw) {
      for (aLine in aPage) {
        if (aState == "Searching") {
          theDomain <- isDomainStart(aLine)
          if (theDomain != "") { 
            aState <- "FoundDomain"
            aCount <- aCount + 1
            # assume about 30 domains
            setProgress(value=aCount/30,message=paste('Reading domain structure for ',theDomain))
            # give time for user to read
            sleepSeconds(1)
          }
        } else if (aState == "FoundDomain") {
          if (!addDomainRow(aLine,theDomain)) aState <- "Searching"
        }
        
      } # end of line loop
    } # end of Page loop
  })  # end of progress
  # remove first empty row
  dfSENDIG <<- dfSENDIG[-1,]
  bSENDIGRead <<- TRUE
}

readSENDIG <- function() {
  # FIXME - due to CDISC login needed
  base <- "https://www.cdisc.org/system/files/members/standard/foundational/send/"
  aZip <- "SENDIG_v_3_1.zip"
  aFile <- "SENDIG_3_1.pdf"
  SENDIGRaw <- readPDFFromURLZip(base,aZip,aFile)
  # Continue if not there yet, because otherwise might have been built with error row
  if (bSENDIGFound && !bSENDIGRead) {
    convertIGRaw(SENDIGRaw)
  }
}


## read pdf by first downloading a file
readPDFFromURLZip <- function(aLocation,aZip,aName,output) {
  subdir <- "downloads"
  anExDir <- paste(sourceDir,subdir,sep="/")
  createOutputDirectory(sourceDir,subdir)
  aTargetZip <- paste(sourceDir,subdir,aZip,sep="/")
  aTarget <- paste(sourceDir,subdir,aName,sep="/")
  aURL <- paste(aLocation,aZip,sep="/")
  # get file if not aleady downloaded - cannot be done without a login, so assume it is there
  # if (!file.exists(aTargetZip)) {
  #  download.file(aURL,aTargetZip,mode = "wb")
  # }
  if (!file.exists(aTargetZip)) {
    dfSENDIG <<- setNames(data.frame(matrix(ncol = 1, nrow = 1)),
                          c("Error"))
    dfSENDIG$Error <<- paste("You must obtain a copy of the SEND IG zip file from ",aURL," and place here: ",aTargetZip," before running the application.")
    bSENDIGFound <<- FALSE
  } else {
    # now read from within the zip file, the actual file needed
    bSENDIGFound <<- TRUE
    unzip(aTargetZip, files = aName, list = FALSE, overwrite = TRUE,
          junkpaths = FALSE, exdir = anExDir, unzip = "internal",
          setTimes = FALSE)
    txt <- pdf_text(aTarget) %>% strsplit(split = "\r\n")
    txt
  }
  
}


createOutputDirectory <- function (aDir,aStudy) {	
  setwd(aDir)
  if (file.exists(aStudy)){
    setwd(file.path(aDir, aStudy))
  } else {
    dir.create(file.path(aDir, aStudy))
    setwd(file.path(aDir, aStudy))
  }
}

sleepSeconds <- function(x)
{
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1 # The cpu usage should be negligible
}
