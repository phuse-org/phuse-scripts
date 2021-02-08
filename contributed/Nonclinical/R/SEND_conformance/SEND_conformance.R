rm(list=ls())

library(Hmisc)
library(tools)
library(stringr)
library(lattice)
library(devtools)
library(httr)

`%ni%` <- Negate('%in%')

# Necessary Changes to the Conformance RUles File:

# Problem #1: In excel file or conformance rules in cell [559,F] a non-ASCI character is used for " that needs to be fixed.
# Solution #1: I fixed this by replacing its contents with cell [555,F]

# Problem #2: In Rule 58, Class was specified as "ALL" but SPC and INT domains are not applicable and break rule
# Solution #2: Class changed from "ALL" to "TDM, FND, EVT"

# Source Functions.R from PHUSE GitHub
source_url('https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/contributed/Nonclinical/R/Functions/Functions.R')

# Set working directory to location of script
PATH <- dirname(sys.calls()[[1]][[2]])
setwd(PATH)

# Select dataset from PHUSE GitHub to evaluate
Data_paths <- 'data/send/FFU-Contribution-to-FDA/'

# List which domains are in which classes
Classes <- list(TDM = c('TE', 'TA', 'TX', 'TS'), SPC = c('DM', 'CO', 'SE'),
                FND = c('BW', 'BG', 'CL', 'DD', 'FW', 'LB', 'MA', 'MI', 'OM', 'PM', 'PC', 'PP', 'SC', 'TF', 'VS', 'EG', 'CV', 'RE'),
                EVT = c('DS'), INT = c('EX'))
SUPP <- paste0('SUPP',unlist(Classes))
Classes$REL <- c('RELREC',SUPP,'POOLDEF')

# Set path of conformance rules .csv file
Rules <- read.csv('SEND_Conformance_Rules_v2.0.csv')

# Provide regular expression for conjunctions, i.e. AND, OR
Conjunctions <- data.frame('AND' = c(' and ', '(?i) and ', '&'),
                           'OR' = c(' or ', '(?i) or ', '|'))
row.names(Conjunctions) <- c('grep','strsplit','collapse')

# Provide regular expression for equation signs, i.e. ==, !=
Signs <- data.frame('not.equals' = c(' ^= ', ' \\^= ', ' != '),
                    'equals' = c(' = ', ' = ', ' == '))
row.names(Signs) <- c('grep', 'strsplit', 'paste')

# Store conjunctions and signs
mySplitterTables <- list('Conjunctions' = Conjunctions,'Signs' = Signs)

# Source function for converting rules into logical statements
source('convertRule.R')

# Initialize variables
RuleNum <- NULL
Condition <- NULL
ConformanceRule <- NULL
Result <- NULL
DOMAIN <- NULL
DataSet <- NULL
DOMAINrow <- NULL
IGversion <- NULL

# Loop through files to evaluate
for (Data_path in Data_paths) {
  
  # Get name of dataset
  Dataset_name <- basename(Data_path)
  
  # Load dataset
  Data <- load.GitHub.xpt.files(studyDir = Data_path)
  
  # Loop through rules to evaluate dataset against
  for (row in seq(nrow(Rules))) {
    
    # Select Rule
    Rule <- Rules[row,]
    
    # Exclude rules/conditions with uninterpreaible content
    
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
    
    # Evaluate whether an interpretable condition exists
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
    
    # Loop through domains applicable to rule
    for (Domain in Domains) {
      
      # Skip domain if not present in dataset
      if (tolower(Domain) %in% names(Data)) {
        domainData <- Data[[tolower(Domain)]]
      } else {
        next
      }  
      
      # Check if rule is interpretable and only move forward if it is
      if (length(grep('=', Rule$Rule, fixed = T)) > 0) {
        
        # Store verbatim condition text
        origCondition <- Rule$Condition
        
        # Convert condition into logical operation
        newCondition <- convertRule(origCondition)
        
        # Store verbatim rule text
        origRule <- Rule$Rule
        
        # Convert rule into logical operation
        newRule <- convertRule(origRule)
        
        # Store CDISC Rule ID
        ruleNum <- Rule$CDISC.SEND.Rule.ID
        
        # Loop through each record in domain
        for (i in seq(length(domainData))) {
          
          # Store information about row
          Condition <- c(Condition, Rule$Condition)
          RuleNum <- c(RuleNum, ruleNum)
          ConformanceRule <- c(ConformanceRule,Rule$Rule)
          DOMAIN <- c(DOMAIN,Domain)
          DataSet <- c(DataSet,Dataset_name)
          DOMAINrow <- c(DOMAINrow,i)
          IGversion <- c(IGversion,Rule$Cited.Document)
          
          # Check if there is a condition to evaluate
          if (conditionExists == T) {
            # Check if the condition is interpretable
            if (conditionInterpretable == T) {
              # Check that evaluation of condition produces an answer
              if (eval(parse(text = paste0('length(',newCondition,')>0')))) {
                # Check that evaluation of condition is not NA
                if (eval(parse(text = paste0('!is.na(',newCondition,')')))) {
                  # Check if evaluation of condition == TRUE
                  if (eval(parse(text = newCondition))) {
                    # Check if evaluation of rule produces an answer
                    if (eval(parse(text = paste0('length(',newRule,')>0')))) {
                      # Check if evaluation of rule is TRUE or FALSE
                      if (eval(parse(text= newRule))==F) {
                        # Record rule FAILED
                        Result <- c(Result,'FAIL')
                      } else {
                        # Record rule PASSED
                        Result <- c(Result,'PASS')
                      }
                    } else {
                      # Record that evaulation of rule did not produce an answer
                      Result <- c(Result,'NA')
                    }
                  } else {
                    # Record that Condition was not met so rule should not be evaluated
                    Result <- c(Result,'Condition Not Met')
                  }
                } else {
                  # Record that condition was skipped to due to being NA
                  Result <- c(Result,'Skipped Condition')
                } 
              } else {
                # Record that condition was skipped to due to not producing an answer
                Result <- c(Result,'Skipped Condition')
              }
            } else {
              # Record that condition was skipped to due not being interpretable
              Result <- c(Result,'Condition Not Interpretable')
            }
          # No condition, proceed with rule evaluation  
          } else {
            # Check if evaluation of rule produces an answer
            if (eval(parse(text = paste0('length(',newRule,')>0')))) {
              # Check if evaluation of rule is TRUE or FALSE
              if (eval(parse(text= newRule))==F) {
                # Record rule FAILED
                Result <- c(Result,'FAIL')
              } else {
                # Record rule PASSED
                Result <- c(Result,'PASS')
              }
            } else {
              # Record that evaulation of rule did not produce an answer
              Result <- c(Result, 'NA')
            }
          }
        }
      }
    }
  }
}

# Convert results to data frame
Results <- as.data.frame(cbind(DataSet,DOMAIN,DOMAINrow,RuleNum,Condition,ConformanceRule,Result,IGversion))

# print records that failed a rule
print(Results[which(Results$Result=="FAIL"),])
print("Passed the following Rules:")

# Get list of rules that passed
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
