convertRule <- function(origRule,splitterTables = mySplitterTables) {
  newRule <- origRule
  newRule <- str_replace_all(newRule, fixed(' ^='), fixed(' ^= '))
  newRule <- str_replace_all(newRule, fixed('^= '), fixed(' ^= '))
  newRule <- gsub('\\s+', ' ', newRule)
  ruleWords <- unlist(strsplit(origRule, ' '))
  for (word in ruleWords) {
    if (length(grep('[A-Z][A-Z]\\.[A-Z][A-Z][A-Z]', word))) {
      wordSplit <- unlist(strsplit(word, '\\.'))
      newDomain <- wordSplit[1]
      newWord <- wordSplit[2]
      newRule <- str_replace(newRule, word, paste0("Data[['", newDomain, "']][['", newWord, "']][i]"))
    # } else if (length(grep('"', word, fixed = T)) > 0) {
    #   newRule <- str_replace_all(newRule, fixed('“'), "'")
    # } else if (length(grep('"', word, fixed = T)) > 0) {
    #   newRule <- str_replace_all(newRule, fixed('”'), "'")
    } else if (length(grep('(', word, fixed = T)) > 0) {
      newRule <- str_replace_all(newRule, fixed('('), '')
    } else if (length(grep(')', word, fixed = T)) > 0) {
      newRule <- str_replace_all(newRule, fixed(')'), '')
      newWord <- str_replace_all(word, fixed(')'), '')
      if ((substr(newWord,1,2) %in% unlist(Classes))&(length(grep('[A-Z][A-Z][A-Z][A-Z]',substr(newWord,3,nchar(newWord)))) > 0)) {
        newRule <- str_replace(newRule, newWord, paste0("Data[['", substr(newWord,1,2), "']][['", substr(newWord,3,nchar(newWord)), "']][i]"))
      }
    } else if ((substr(word,1,2) %in% unlist(Classes))&(length(grep('[A-Z][A-Z][A-Z][A-Z]',substr(word,3,nchar(word)))) > 0)) {
      newRule <- str_replace(newRule, word, paste0("Data[['", substr(word,1,2), "']][['", substr(word,3,nchar(word)), "']][i]"))
    } else if (length(grep('--', word, fixed = T)) > 0) {
      newRule <- str_replace_all(newRule, word, paste0("domainData[['", word, "']][i]"))
    } else if (length(grep('DONE', word)) > 0) {
      next
    } else if (length(grep('PROTOCOL', word)) > 0) {
      next
    } else if (length(grep('[A-Z][A-Z][A-Z][A-Z]', word)) > 0) {
      newRule <- str_replace_all(newRule, word, paste0("domainData[['", word, "']][i]"))
      # } else if (length(grep('ARM', word)) > 0) {
      #   newRule <- str_replace(newRule, word, paste0("domainData[['", word, "']][i]"))
    }
  }
  
  if (length(grep('[A-Z][A-Z]\\.domainData', newRule))) {
    newRuleWords <- unlist(strsplit(newRule, ' '))
    for (word in newRuleWords) {
      if (length(grep('[A-Z][A-Z]\\.domainData', word))) {
        wordSplit <- unlist(strsplit(word, '\\.domainData'))
        newDomain <- wordSplit[1]
        newWord <- wordSplit[2]
        newRule <- str_replace(newRule, fixed(word), paste0("Data[['", newDomain, "']]", newWord))
      }
    }
  }
    
  Conjunctions <- splitterTables$Conjunctions
  Signs <- splitterTables$Signs
  
  for (conjunction in colnames(Conjunctions)) {
    if (length(grep(Conjunctions['grep',conjunction], newRule, ignore.case = T)) > 0) {
      for (sign in colnames(Signs)) {
        if (length(unlist(strsplit(newRule, Signs['strsplit',sign]))) == 2) {
          splitSides <- unlist(strsplit(newRule, Signs['strsplit',sign]))
          leftSides <- splitSides[1]
          rightSides <- splitSides[2]
          splitLeftSides <- unlist(strsplit(leftSides, Conjunctions['strsplit',conjunction]))
          splitRightSides <- unlist(strsplit(rightSides, Conjunctions['strsplit',conjunction]))
          splitRules <- NULL
          if (length(splitRightSides) > 1) {
            for (splitRightSide in splitRightSides) {
              splitRules <- c(splitRules,paste0('(', leftSides, Signs['paste',sign], splitRightSide, ')'))
            }
          } else if (length(splitLeftSides) > 1) {
            for (splitLeftSide in splitLeftSides) {
              splitRules <- c(splitRules,paste0('(', splitLeftSide, Signs['paste',sign], rightSides, ')'))
            }
          }
          
          if (length(grep(' ^= null', splitRules, fixed = T))>0) {
            splitRules <- str_replace_all(splitRules, fixed(' ^= null'), '')
            splitRules <- paste0('(!is.null(', splitRules, '))&(!is.na(', splitRules, '))')
          } else if (length(grep(' != null', splitRules, fixed = T))>0) {
            splitRules <- str_replace_all(splitRules, fixed(' != null'), '')
            splitRules <- paste0('(!is.null(', splitRules, '))&(!is.na(', splitRules, '))')
          } else if (length(grep(' = null', splitRules, fixed = T))>0) {
            splitRules <- str_replace_all(splitRules, fixed(' = null'), '')
            splitRules <- paste0('(is.null(', splitRules, '))|(is.na(', splitRules, '))')
          }
          
          newRule <- paste0(splitRules, collapse = Conjunctions['collapse',conjunction])
        } else if (length(unlist(strsplit(newRule, Signs['strsplit',sign]))) > 2) {
          splitRules <- paste0('(', unlist(strsplit(newRule, Conjunctions['strsplit',conjunction])), ')')
          
          if (length(grep(' ^= null', splitRules, fixed = T))>0) {
            splitRules <- str_replace_all(splitRules, fixed(' ^= null'), '')
            splitRules <- paste0('(!is.null(', splitRules, '))&(!is.na(', splitRules, '))')
          } else if (length(grep(' != null', splitRules, fixed = T))>0) {
            splitRules <- str_replace_all(splitRules, fixed(' != null'), '')
            splitRules <- paste0('(!is.null(', splitRules, '))&(!is.na(', splitRules, '))')
          } else if (length(grep(' = null', splitRules, fixed = T))>0) {
            splitRules <- str_replace_all(splitRules, fixed(' = null'), '')
            splitRules <- paste0('(is.null(', splitRules, '))|(is.na(', splitRules, '))')
          }
          
          newRule <- paste0(splitRules, collapse = Conjunctions['collapse',conjunction])
        }
      }
    }
  }
  
  if (length(grep(' ^= null', newRule, fixed = T))>0) {
    newRule <- str_replace_all(newRule, fixed(' ^= null'), '')
    newRule <- paste0('(!is.null(', newRule, '))&(!is.na(', newRule, '))')
  } else if (length(grep(' != null', newRule, fixed = T))>0) {
    newRule <- str_replace_all(newRule, fixed(' != null'), '')
    newRule <- paste0('(!is.null(', newRule, '))&(!is.na(', newRule, '))')
  } else if (length(grep(' = null', newRule, fixed = T))>0) {
    newRule <- str_replace_all(newRule, fixed(' = null'), '')
    newRule <- paste0('(is.null(', newRule, '))|(is.na(', newRule, '))')
  }
  
  newRule <- str_replace_all(newRule, fixed('--'), Domain)
  newRule <- str_replace_all(newRule, fixed('^'), fixed('!'))
  newRule <- str_replace_all(newRule, fixed(' = '), fixed(' == '))
  
  return(newRule)
}