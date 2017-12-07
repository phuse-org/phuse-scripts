# Function to merge in demographic and treatment data for each of the SEND experimental results domains

groupSEND <- function(dataset,targetDomain,dmFields=c('SEX','ARMCD','SETCD','USUBJID'),
                      exFields=c('EXTRT','EXDOSE','EXDOSU'),
                      txParams=c('TRTDOS','TRTDOSU','TKDESC','GRPLBL','SPGRPCD')) {
  
  # Get dataframe of domain of interest and identify subjects
  groupedData <- dataset[[targetDomain]]
  if (! is.factor(groupedData$USUBJID)) {
    groupedData$USUBJID <- factor(groupedData$USUBJID)
  }
  subjects <- levels(groupedData$USUBJID)
  
  # Merge relevant fields from dm domain by subject (defaults: sex, trial arm, and trial set)
  groupedData <- merge(groupedData,dataset$dm[,dmFields],by='USUBJID')
  
  # Merge relevant fields from the ex domain by subject (defaults: treatment, dose, and dose unit)
  for (field in exFields) {
    assign(field,NA)
  }
  count <- 0
  for (subject in subjects) {
    count <- count + 1
    subjectIndex <- which(dataset$ex$USUBJID==subject)
    for (field in exFields) {
      tmp <- get(field)
      uniqueFieldValues <- unique(dataset$ex[subjectIndex,field])
      if (is.factor(dataset$ex[[field]])) {
        uniqueFieldValues <- levels(dataset$ex[[field]])[uniqueFieldValues]
      }
      if (length(uniqueFieldValues)>1) {
        tmp[count] <- paste(uniqueFieldValues,collapse="; ")
      } else {
        tmp[count] <- uniqueFieldValues
      }
      assign(field,tmp)
    }
  }
  exData <- subjects
  for (field in exFields) {
    exData <- cbind(exData,get(field))
  }
  exData <- as.data.frame(exData)
  colnames(exData) <- c('USUBJID',exFields)
  groupedData <- merge(groupedData,exData,by='USUBJID')
  
  # Merge relevant information from tx domain by set code (default: dose, dose unit, toxicokinetics description, group label, and sponsor-defined group label)
  #                                                       (control treatment currently hard coded)
  if (! is.factor(dataset$tx$SETCD)) {
    dataset$tx$SETCD <- factor(dataset$tx$SETCD)
  }
  SETCD <- levels(dataset$tx$SETCD)
  for (param in c('SET',txParams,'TCNTRL')) {
    assign(param,NA)
  }
  txParamsFlag <- rep(FALSE,length(txParams))
  names(txParamsFlag) <- txParams
  count <- 0
  for (set in SETCD) {
    count <- count + 1
    setIndex <- which(dataset$tx$SETCD==set)
    SET[count] <- levels(dataset$tx$SET)[unique(dataset$tx$SET[setIndex])][1]
    if (length(levels(dataset$tx$SET)[unique(dataset$tx$SET[setIndex])])>1) {
      warning('SET names do not match SETCD in TX Domain!')
    }
    for (param in txParams) {
      if (param %in% dataset$tx$TXPARMCD) {
        if (count==1) {
          txParamsFlag[param] <- TRUE
        }
        tmp <- get(param)
        tmp[count] <- getFieldValue(dataset$tx,'TXVAL',c('SETCD','TXPARMCD'),c(set,param))
        assign(param,tmp)
      }
    }
    if ('TCNTRL' %in% dataset$tx$TXPARMCD) {
      if (as.numeric(TRTDOS[count])==0) {
        TCNTRL[count] <- getFieldValue(dataset$tx,'TXVAL',c('SETCD','TXPARMCD'),c(set,'TCNTRL'))
      } else {
        TCNTRL[count] <- NA
      }
    } else {
      TCNTRL[count] <- NA
    }
  }
  txData <- cbind(SETCD,SET)
  for (param in txParams[txParamsFlag==T]) {
    txData <- cbind(txData,get(param))
  }
  txData <- cbind(txData,TCNTRL)
  txData <- as.data.frame(txData)
  colnames(txData) <- c('SETCD','SET',txParams[txParamsFlag==T],'TCNTRL')
  groupedData <- merge(groupedData,txData,by='SETCD')
  
  # Check ifUSUBJID in PP --> TKSTATUS
  TKcheck <- rep(NA,length(subjects)*2)
  dim(TKcheck) <- c(length(subjects),2)
  colnames(TKcheck) <- c('USUBJID','TKstatus')
  TKcheck <- as.data.frame(TKcheck)
  count <- 0
  for (subject in subjects) {
    count <- count + 1
    TKcheck$USUBJID[count] <- subject
    if (subject %in% dataset$pp$USUBJID) {
      TKcheck$TKstatus[count] <- TRUE
    } else {
      TKcheck$TKstatus[count] <- FALSE
    }
  }
  groupedData <- merge(groupedData,TKcheck,by='USUBJID')
  
  # Merge recovery status from ta domain (EPOCH) by arm code or se domain (ELEMENT) by subject
  if (!is.null(dataset$ta)) {
    ARMCD <- levels(dataset$ta$ARMCD)
    taData <- rep(NA,length(ARMCD)*2)
    dim(taData) <- c(length(ARMCD),2)
    colnames(taData) <- c('ARMCD','RecoveryStatus')
    taData <- as.data.frame(taData)
    taData$ARMCD <- ARMCD
    count <- 0
    for (arm in ARMCD) {
      count <- count + 1
      armIndex <- which(dataset$ta$ARMCD==arm)
      if (length(grep('recovery',dataset$ta$EPOCH[armIndex],ignore.case=TRUE))>0) {
        taData$RecoveryStatus[count] <- TRUE
      } else {
        taData$RecoveryStatus[count] <- FALSE
      }
    }
    groupedData <- merge(groupedData,taData,by='ARMCD')
  } else if (!is.null(dataset$se)) {
    seData <- rep(NA,length(subjects)*2)
    dim(seData) <- c(length(subjects),2)
    colnames(seData) <- c('USUBJID','RecoveryStatus')
    seData <- as.data.frame(seData)
    seData$USUBJID <- subjects
    count <- 0
    for (subject in subjects) {
      count <- count + 1
      subjectIndex <- which(dataset$se$USUBJID==subject)
      if (length(grep('recovery',dataset$se$ELEMENT[subjectIndex],ignore.case=TRUE))>0) {
        seData$RecoveryStatus[count] <- TRUE
      } else {
        seData$RecoveryStatus[count] <- FALSE
      }
    }
    groupedData <- merge(groupedData,seData,by='USUBJID')
  }
  
  # Clean up the dataframe
  
  # Rename SEX
  groupedData$Sex <- groupedData$SEX
  
  # Define Treatment
  if ('TCNTRL' %in% colnames(groupedData)) {
    levels(groupedData$EXTRT) <- c(levels(groupedData$EXTRT),levels(groupedData$TCNTRL))
    tcntrlIndex <- which(!is.na(groupedData$TCNTRL))
    groupedData$EXTRT[tcntrlIndex] <- groupedData$TCNTRL[tcntrlIndex]
  }
  groupedData$Treatment <- groupedData$EXTRT
  dropColumns <- 'TCNTRL'
  
  # Check for dose discrepancy
  if (is.factor(groupedData$EXDOSE)) {
    if (! FALSE %in% is.finite(as.numeric(levels(groupedData$EXDOSE)[groupedData$EXDOSE]))) {
      groupedData$EXDOSE <- as.numeric(levels(groupedData$EXDOSE)[groupedData$EXDOSE])
    } else {
      groupedData$EXDOSE <- as.character(levels(groupedData$EXDOSE)[groupedData$EXDOSE])
    }
  }
  if (is.factor(groupedData$TRTDOS)) {
    if (! FALSE %in% is.finite(as.numeric(levels(groupedData$TRTDOS)[groupedData$TRTDOS]))) {
      groupedData$TRTDOS <- as.numeric(levels(groupedData$TRTDOS)[groupedData$TRTDOS])
    } else {
      groupedData$TRTDOS <- as.character(levels(groupedData$TRTDOS)[groupedData$TRTDOS])
    }
  }
  if (! FALSE %in% (groupedData$EXDOSE==groupedData$TRTDOS)) {
    dropColumns <- c(dropColumns,'TRTDOS')
  }
  groupedData$DoseN <- groupedData$EXDOSE
  
#   print(sort(levels(groupedData$EXDOSU))==sort(levels(groupedData$TRTDOSU)))
#   if (! FALSE %in% c(sort(levels(groupedData$EXDOSU))==sort(levels(groupedData$TRTDOSU)))) {print('YAY')}
  # Check for dose unit discrepancy
  if (length(levels(groupedData$EXDOSU)==length(levels(groupedData$TRTDOSU)))) {
    if (length(levels(groupedData$EXDOSU))==1) {
      if (levels(groupedData$EXDOSU)==levels(groupedData$TRTDOSU)) {
        dropColumns <- c(dropColumns,'TRTDOSU')
      }
    } else {
      if (! FALSE %in% sort(levels(groupedData$EXDOSU))==sort(levels(groupedData$TRTDOSU))) {
        if (! FALSE %in% (groupedData$EXDOSU==groupedData$TRTDOSU)) {
          dropColumns <- c(dropColumns,'TRTDOSU')
        }
      }
    }
  }
  groupedData$DoseUnit <- groupedData$EXDOSU
  
  # Create concatenated dose with units
  groupedData$Dose <- paste(groupedData$DoseN,groupedData$DoseUnit)
  groupedData$TreatmentDose <- paste(groupedData$Treatment,groupedData$Dose)
  dropColumns <- c(dropColumns,'DoseN','DoseUnit')
  
  # Define TK
  if ('TKDESC' %in% colnames(groupedData)) {
    noTKindex <- grep('no',groupedData$TKDESC,ignore.case=T)
    groupedData$TKstatus[noTKindex] <- FALSE
    groupedData$TKstatus[-noTKindex] <- TRUE
    dropColumns <- c(dropColumns,'TKDESC')
  }
  
  # drop useless columns
  dropIndex <- which(! colnames(groupedData) %in% dropColumns)
  groupedData <- groupedData[,dropIndex]
  
  # reorder columns
  columns2move <- c('SET','Treatment','TreatmentDose','Dose','Sex','RecoveryStatus','TKstatus')
  columnsNOmove <- which(! colnames(groupedData) %in% columns2move)
  groupedData <- cbind(groupedData[,columns2move],groupedData[,columnsNOmove])
  
  return(groupedData)
}