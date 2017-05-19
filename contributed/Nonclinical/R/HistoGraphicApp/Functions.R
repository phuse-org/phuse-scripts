# Function to extract relevant fields and rename them
subTable <- function(fields,names,rawData) {
  count <- 0
  colIndex <- NA
  for (field in fields) {
    count <- count + 1
    if (length(which(colnames(rawData)==field))==1) { # test to make sure we get each column correctly
      index <- which(colnames(rawData)==field)
    } else {
      stop(paste(field,' Not Present in Dataset!',sep='')) # break and throw error message
    }
    colIndex[count] <- index
  }
  Data <- rawData[,colIndex]
  colnames(Data) <- names
  return(Data)
}

# Function to get the value of a row within a field defined by values in other fields
# For example: to check a TXVAL given a TXPARMCD and SETCD
getFieldValue <- function(dataset,queryField,indexFields,indexValues) {
  for (i in 1:length(indexFields)) {
    indexTmp <- which(dataset[,indexFields[i]]==indexValues[i])
    if (i == 1) {
      index <- indexTmp
    } else {
      index <- intersect(index,indexTmp)
    }
  }
  fieldValue <- dataset[index,queryField]
  if (length(levels(dataset[,queryField])) > 0) {
    return(levels(dataset[,queryField])[fieldValue])
  } else {
    return(fieldValue)
  }
}