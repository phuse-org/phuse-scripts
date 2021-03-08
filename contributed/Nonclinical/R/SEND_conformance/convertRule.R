# Inputs:
# origRule: verbatim text of rule or condition to convert to logical statement for R evaluation
# mySplitterTables: list of characters to convert to interpretable logical operators
# myClasses: list of domains in each class
# myDomain: current domain

# Output: text string that can be evaluated by R as a logical operation

`%ni%` <- Negate('%in%')

convertRule <- function(origRule,
                        mySplitterTables = splitterTables,
                        myClasses = Classes,
                        myDomain = Domain) {
  newRule <- origRule
  
  # Add trailing spaces to ^= operator
  newRule <- str_replace_all(newRule, fixed(' ^='), fixed(' ^= '))
  newRule <- str_replace_all(newRule, fixed('^= '), fixed(' ^= '))
  
  # Make all spaces single spaces
  newRule <- gsub('\\s+', ' ', newRule)
  
  # Remove parenthesis from rule
  newRule <- str_replace_all(newRule, fixed('('), '')
  newRule <- str_replace_all(newRule, fixed(')'), '')
  
  # Split rule into words
  ruleWords <- unlist(strsplit(newRule, ' '))
  
  # Loop through words of rule
  for (word in ruleWords) {
    # Check if word is still in rule
    if (word %ni% unlist(strsplit(newRule, ' '))) {
      next
    }
    
    # Check if word is a [Domain].[Variable]
    if (length(grep('[A-Z][A-Z]\\.[A-Z][A-Z][A-Z]', word))) {
      
      # Split domain from variable
      wordSplit <- unlist(strsplit(word, '\\.'))
      newDomain <- wordSplit[1]
      newWord <- wordSplit[2]
      
      # Re-write word as "Data[[Domain]][[Variable]][i]"
      newRule <- str_replace_all(newRule, word, paste0("Data[['", newDomain, "']][['", newWord, "']][i]"))
    
    # Check if word is a variable with the domain as first two characters, e.g. MISTAT, and re-write as "Data[[Domain]][[Variable]][i]"
    } else if ((substr(word, 1, 2) %in% unlist(myClasses))&(length(grep('[A-Z][A-Z][A-Z][A-Z]', substr(word, 3, nchar(word)))) > 0)) {
      if (substr(word, 1, 2) %in% c(myClasses$TDM, myClasses$SPC)) {
        newRule <- str_replace_all(newRule, word, paste0("Data[['", substr(word,1,2), "']][['", substr(word, 3, nchar(word)), "']][i]"))
      } else {
        newRule <- str_replace_all(newRule, word, paste0("Data[['", substr(word,1,2), "']][['", word, "']][i]"))
      }
      
    # ELSE check if word is [Domain + extra characters].[Variable] and re-write as "Data[[Domain]][[Variable]][i]
    } else if ((substr(word,1,2) %in% unlist(myClasses))&(length(grep('[A-Z][A-Z][A-Z][A-Z]',substr(word,3,nchar(word)))) > 0)) {
      newRule <- str_replace_all(newRule, word, paste0("Data[['", substr(word,1,2), "']][['", substr(word,3,nchar(word)), "']][i]"))
    
    # ELSE check for -- and place variable name in format: "domainData[[Variable]][i]
    } else if (length(grep('--', word, fixed = T)) > 0) {
      newRule <- str_replace_all(newRule, word, paste0("domainData[['", word, "']][i]"))
    
    # ELSE skip if word is "DONE"
    } else if (length(grep('DONE', word)) > 0) {
      next
    
    # ELSE skip if word is "PROTOCOL"
    } else if (length(grep('PROTOCOL', word)) > 0) {
      next
    
    # ELSE convert any four letter ALL CAPS words into domainData[[XXXX]][i] format
    } else if (length(grep('[A-Z][A-Z][A-Z][A-Z]', word)) > 0) {
      newRule <- str_replace(newRule, word, paste0("domainData[['", word, "']][i]"))
    }
  }
  
  # Convert any cases of XX.domainData to Data[[XX]]
  if (length(grep('[A-Z][A-Z]\\.domainData', newRule))) {
    newRuleWords <- unlist(strsplit(newRule, ' '))
    for (word in newRuleWords) {
      if (length(grep('[A-Z][A-Z]\\.domainData', word))) {
        wordSplit <- unlist(strsplit(word, '\\.domainData'))
        newDomain <- wordSplit[1]
        newWord <- wordSplit[2]
        newRule <- str_replace_all(newRule, fixed(word), paste0("Data[['", newDomain, "']]", newWord))
      }
    }
  }
  
  # Get Conjunction and Sign Terms
  Conjunctions <- mySplitterTables$Conjunctions
  Signs <- mySplitterTables$Signs
  
  
  # Convert conjunctions and signs from Conformance Rule syntax to R syntax
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
  
  # Convert Conformance Rule NULL syntax to R NULL syntax
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
  
  # Replace any remaining -- with current domain and ^ with ! and = with ==
  newRule <- str_replace_all(newRule, fixed('--'), myDomain)
  newRule <- str_replace_all(newRule, fixed('^'), fixed('!'))
  newRule <- str_replace_all(newRule, fixed(' = '), fixed(' == '))
  
  return(newRule)
}