rm(list=ls())

library(Hmisc)
library(tools)
library(stringr)
library(lattice)

`%ni%` <- Negate('%in%')

# Necessary Changes to the Conformance RUles File:

# Problem #1: In excel file or conformance rules in cell [559,F] a non-ASCI character is used for " that needs to be fixed.
# Solution #1: I fixed this by replacing its contents with cell [555,F]

# Problem #2: In Rule 58, Class was specified as "ALL" but SPC and INT domains are not applicable and break rule
# Solution #2: Class changed from "ALL" to "TDM, FND, EVT"

source('~/PhUSE/Git/phuse-scripts/contributed/Nonclinical/R/Functions/Functions.R')

# frame_files <- lapply(sys.frames(), function(x) x$ofile)
# frame_files <- Filter(Negate(is.null), frame_files)
# PATH <- dirname(frame_files[[length(frame_files)]])

PATH <- dirname(sys.calls()[[1]][[2]])

setwd(PATH)

Data_paths <- '~/PhUSE/Git/phuse-scripts/data/send/FFU-Contribution-to-FDA/'
# Datasets_path <- list.files(Data_path,'*.xpt',full.names = T)

# Add SUPP-- to this later
Classes <- list(TDM = c('TE', 'TA', 'TX', 'TS'), SPC = c('DM', 'CO', 'SE'),
                FND = c('BW', 'BG', 'CL', 'DD', 'FW', 'LB', 'MA', 'MI', 'OM', 'PM', 'PC', 'PP', 'SC', 'TF', 'VS', 'EG', 'CV', 'RE'),
                EVT = c('DS'), INT = c('EX'))
SUPP <- paste0('SUPP',unlist(Classes))
Classes$REL <- c('RELREC',SUPP,'POOLDEF')

Rules <- read.csv('SEND_Conformance_Rules_v2.0.csv')

Conjunctions <- data.frame('AND' = c(' and ', '(?i) and ', '&'),
                           'OR' = c(' or ', '(?i) or ', '|'))
row.names(Conjunctions) <- c('grep','strsplit','collapse')

Signs <- data.frame('not.equals' = c(' ^= ', ' \\^= ', ' != '),
                    'equals' = c(' = ', ' = ', ' == '))
row.names(Signs) <- c('grep', 'strsplit', 'paste')

mySplitterTables <- list('Conjunctions' = Conjunctions,'Signs' = Signs)

# conjunctions <- c(' ?o?r ', ' ?a?n?d ')
# names(conjunctions) <- c('|', '&')
# splitters <- c(' ^= ',' = ')
# names(splitters) <- c(' != ', ' == ')

# ruleExclusionTerms <- c('Define-XML', 'Domain Name')

source('convertRule.R')

RuleNum <- NULL
Condition <- NULL
ConformanceRule <- NULL
Result <- NULL
DOMAIN <- NULL
DataSet <- NULL
DOMAINrow <- NULL
IGversion <- NULL
for (Data_path in Data_paths) {
  Dataset_name <- basename(Data_path)
  Data <- load.xpt.files(Data_path)
  # for (row in seq(500)) {
  for (row in seq(nrow(Rules))) {
    # Select Rule
    Rule <- Rules[row,]
    
    # Exclusion Cases:
    
    # Rules
    if (length(grep('Define-XML', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Domain Name', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('for a given [A-Z][A-Z] record', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('valid domain abbreviation', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Study day variable', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('value length', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('either a record with', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('AND/OR', Rule$Rule, fixed = T)) > 0) {
      next
    }
    if (length(grep('Each Trial Set must have a single', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('treatment name only', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Each trial set must have', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('ISO 8601 format in SEND', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Only one record with', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Unit for', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('When', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('for derived data', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('precision of data collection', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Variable label length', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Variable name length', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('absolute latest value of test', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('value for that subject', Rule$Rule, ignore.case = T)) > 0) {
      next
    }
    
    # Conditions
    if (length(grep('record refers to', Rule$Condition, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('for one of the two', Rule$Condition, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('numeric value', Rule$Condition, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('Variable Core Status', Rule$Condition, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('permissible and codelist', Rule$Condition, ignore.case = T)) > 0) {
      next
    }
    if (length(grep('measurement is made over', Rule$Condition, ignore.case = T)) > 0) {
      next
    }
    
    # Fixed Exclusions
    
    
    # Get Applicable Domains from Class and Domain
    Domains <- NULL
    if (!is.na(Rule$Class)) {
      if (Rule$Class != 'ALL') {
        if (length(grep(',', Rule$Class)) == 0) {
          Domains <- Classes[[Rule$Class]]
        } else {
          rowClasses <- unlist(strsplit(Rule$Class, ', ', fixed = T))
          for (rowClass in rowClasses) {
            Domains <- c(Domains,Classes[[rowClass]])
          }
        }
      } else {
        Domains <- unlist(Classes)
      }
    }
    if (!is.na(Rule$Domain)) {
      if (Rule$Domain != 'ALL') {
        rowDomains <- unlist(strsplit(Rule$Domain, ', ', fixed = T))
        Domains <- Domains[which(Domains %in% rowDomains)]
      }
    }
    if (('SUPP' %in% Domains)|('SUPP--' %in% Domains)) {
      if ('SUPP' %in% Domains) {
        removeIndex <- which(Domains == 'SUPP')
      } else if ('SUPP--' %in% Domains) {
        removeIndex <- which(Domains == 'SUPP--')
      }
      Domains <- Domains[-removeIndex]
      Domains <- c(Domains,SUPP)
    }
    
    # # Get Applicable Variables from Variable
    # Variables <- NULL
    # if (Rule$Variable %ni% c('ALL','GEN')) {
    #   if (length(grep(',', Rule$Variable)) == 0) {
    #     Variables <- Rule$Variable
    #   } else {
    #     Variables <- unlist(strsplit(Rule$Variable, ', '))
    #   }
    # }
    
    # Identify if interpretable condition exists
    if (Rule$Condition != '') {
      conditionExists <- T
      if (length(grep('=',Rule$Condition,fixed=T))>0) {
        conditionInterpretable <- T
      } else if (length(grep('<',Rule$Condition,fixed=T))>0) {
        conditionInterpretable <- T
      } else if (length(grep('>',Rule$Condition,fixed=T))>0) {
        conditionInterpretable <- T
      } else {
        conditionInterpretable <- F
      }
    } else {
      conditionExists <- F
    }
    
    for (Domain in Domains) {
      if (tolower(Domain) %in% names(Data)) {
        domainData <- Data[[tolower(Domain)]]
      } else {
        
        next
      }  
      
      if (length(grep('=',Rule$Rule)) > 0) {
        origCondition <- Rule$Condition
        newCondition <- convertRule(origCondition)
        
        origRule <- Rule$Rule
        newRule <- convertRule(origRule)
        
        ruleNum <- Rule$CDISC.SEND.Rule.ID
        
        for (i in seq(length(domainData))) {
          Condition <- c(Condition, Rule$Condition)
          RuleNum <- c(RuleNum, ruleNum)
          ConformanceRule <- c(ConformanceRule,Rule$Rule)
          DOMAIN <- c(DOMAIN,Domain)
          DataSet <- c(DataSet,Dataset_name)
          DOMAINrow <- c(DOMAINrow,i)
          IGversion <- c(IGversion,Rule$Cited.Document)
          if (conditionExists == T) {
            if (conditionInterpretable == T) {
              if (eval(parse(text = paste0('length(',newCondition,')>0')))) {
                if (eval(parse(text = paste0('!is.na(',newCondition,')')))) {
                  if (eval(parse(text = newCondition))) {
                    # print(newCondition)
                    # print(ruleNum)
                    if (eval(parse(text = paste0('length(',newRule,')>0')))) {
                      if (eval(parse(text= newRule))==F) {
                        Result <- c(Result,'FAIL')
                        # print(ruleNum)
                        # print('Stop!') # come up with a way to log these rather than break
                        # stop()
                      } else {
                        Result <- c(Result,'PASS')
                      }
                    } else {
                      # print('Skipped Rule')
                      Result <- c(Result,'NA')
                    }
                  } else {
                    Result <- c(Result,'Condition Not Met')
                  }
                } else {
                  # print('Skipped Condition')
                  Result <- c(Result,'Skipped Condition')
                } 
              } else {
                # print('Skipped Condition')
                Result <- c(Result,'Skipped Condition')
              }
            } else {
              Result <- c(Result,'Condition Not Interpretable')
            }
          } else {
            if (eval(parse(text = paste0('length(',newRule,')>0')))) {
              if (eval(parse(text= newRule))==F) {
                Result <- c(Result,'FAIL')
                # print(ruleNum)
                # print('Stop!') # come up with a way to log these rather than break
                # stop()
              } else {
                Result <- c(Result,'PASS')
              }
            } else {
              # print('Skipped Rule')
              Result <- c(Result, 'NA')
            }
          }
        }
      }
    }
  }
}

Results <- as.data.frame(cbind(DataSet,DOMAIN,DOMAINrow,RuleNum,Condition,ConformanceRule,Result,IGversion))
print(Results[which(Results$Result=="FAIL"),])
print("Passed the following Rules:")
passedRules <- NULL
for (rule in unique(Rules$CDISC.SEND.Rule.ID)) {
  passRule <- T
  if (rule %in% Results$RuleNum) {
    index <- which(Results$RuleNum == rule)
    for (result in Results$Result[index]) {
      if (result %ni% c('PASS','Condition Not Met','NA')) {
        passRule <- F
      }
    }
    if (passRule == T) {
      passedRules <- c(passedRules,rule)
    }
  }
}
print(passedRules)
