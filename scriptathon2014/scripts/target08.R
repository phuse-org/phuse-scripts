#**************************************************************************#
#         PROGRAM NAME: Demographics Analysis Table                        #
#                                                                          #
#          DESCRIPTION: Find subject counts and % per treatment            #
#                       Find subject counts and % per disposition          #
#                        for age group, sex, race, ethnicity, country      #
#                       Find summary statistics for age                    #
#                       Output to RTF                                      #
#                                                                          #
#      EVALUATION TYPE:                                                    #
#                                                                          #
#               AUTHOR: Bob Friedman (bfriedman@xybion.com)		   #
#                                                                          #
#                 DATE: 21 March 2013                                      #
#                                                                          #
#            MADE WITH: R                                                  #
#                                                                          #
# 	LIMITATIONS:							   # 
# 		this report is for only 2 treatments, therefore Placebo    #
#   	        is filtered out, leaving two treatments in example dataset.#
#                                                                          # 
# 	YET TO DO:                                                         #
#             Allow study selection, allow selection of which treatments   #
#               to include                                                 #
#	      Ensure n properly reduced in case of missing values          #  
#	      Add country demographics (seemingly not in data set)         #
#	      Remove grid lines?                                           #
#	      Reorder treatments low to high?                              #
#	      Are age >=65 and >=75 meant to be offset from the other      #
#             columns?                                                     #  
#             Example showed p-values on >=65 and >=75 but need 2x2 matrix #
#                                                                          #
#**************************************************************************#

# REVISIONS 
#
# 21-Mar-2014 BJF Completion of first pass
#
#
#
install.packages("rtf")
library(rtf)
library(SASxport)
#
#define variables needed
	dataSource ="http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/adsl.xpt"
	outputFileName = "DemographicSummary.rtf"
	tableName = "Table 7.1 Demographic Summary"
	 # determine the treatment names	
	header <<- array(c("<Enrolled / Randomized> Population","Study Name"))
	nHeader <<- 2
	footer <<- array()
	footer[1] = "Abbrevations: N= number of subjects in population;"
	footer[2] = "		 n= number of subjects"
	footer[3] = ""
	footer[4] = "*a = number of subjects with non-missing data, used as denominator"
	footer[5] = "*b = For categorical measure; p-value is calculated from Fisher's exact test. For continuous measure: t-test when comparing means."
	nFooter <<- 5

# create global variables for routine
	Col1 <<- array()
	Col2 <<- array()
	TotCol <<- array()
	Treat <<- matrix(nrow=200,ncol=3)
	pvalue <<- array()
	
	rowC <<- 1

# function for output rows
outputRows <- function(){
#	combine individual vectors into data frame
	aFrame <-data.frame(cbind(Col1,Col2,Treat[1:rowC-1,1],Treat[1:rowC-1,2],TotCol,pvalue))
	print(head(aFrame))
#	Remove column names
	sTreata <- array()
	sTreata = paste(rownames(treatments)," (N=",treatments,")",sep = "")
	sTotal = paste("Total "," (N=",nrow(data),")",sep = "")
	colnames(aFrame)<-c("Demographic Parameter"," ",sTreata[1],sTreata[2],"Total","p-value*b")
#	put out as RTF table
		
	addTable(rtf,aFrame,font.size=8,row.names=FALSE,NA.string="-",header.col.justify=c("L","C","C","C","C","C"),
		col.justify=c("L","C","C","C","C","C"),col.widths=c(2.5,1,1,1,1,1.5))	
}
#

# function to make an empty row in table
emptyRow <- function() {
	Col1[rowC] <<- ""
	Col2[rowC] <<- ""
	# total
	# for all treatments
	for (t in 1:nTreat) {
		Treat[rowC,t] <<- ""
	}
	TotalDenominator <<- ""
	TotCol[rowC] <<- ""
	pvalue[rowC] <<- ""
	rowC <<- rowC + 1 
}

# function to get study name from data
getStudyName <- function() {
	studies <<- xtabs(~STUDYID, data=data,drop.unused.levels=TRUE)
	# for now - first one
	return (rownames(studies)[1])
}


# function for p-value for categorical
pvalue_categorical <- function(aggregated) {
	# Fischers exact test
	aresult = fisher.test(aggregated)
	return (aresult$p.value)
}


# function for p-value for numerical
pvalue_numerical <- function(dep,indep) {
	# Fischers exact test
	aresult = t.test(dep~indep,data=data)
	return (aresult$p.value)
}


#

# function for general categorical calculations
outputCategorical <- function(Type){
#
# 
	if (Type==1) {
		aggreg <<- xtabs(~SEX+TRT01P, data=data,drop.unused.levels=TRUE)
		totals <<- xtabs(~SEX, data=data,drop.unused.levels=TRUE)
		denominators <<- xtabs(~TRT01P,data=data,drop.unused.levels=TRUE)
		Col1[rowC] <<- "Sex n(%)"
		dataType = "Sex"
	}
	else if (Type==2) {
		aggreg <<- xtabs(~RACE+TRT01P, data=data,drop.unused.levels=TRUE)
		totals <<- xtabs(~RACE, data=data,drop.unused.levels=TRUE)
		denominators <<- xtabs(~TRT01P,data=data,drop.unused.levels=TRUE)
		Col1[rowC] <<- "Race n(%)"
		dataType = "Race"
	}
	else if (Type==3) {
		aggreg <<- xtabs(~ETHNIC+TRT01P, data=data,drop.unused.levels=TRUE)
		totals <<- xtabs(~ETHNIC, data=data,drop.unused.levels=TRUE)
		denominators <<- xtabs(~TRT01P,data=data,drop.unused.levels=TRUE)
		Col1[rowC] <<- "Ethnicity n(%)"
		dataType = "Ethnicity"
	}
	else if (Type==4) {
		aggreg <<- xtabs(~AGEGR1+TRT01P, data=data,drop.unused.levels=TRUE)
		totals <<- xtabs(~AGEGR1, data=data,drop.unused.levels=TRUE)
		denominators <<- xtabs(~TRT01P,data=data,drop.unused.levels=TRUE)
		Col1[rowC] <<- "Age categories n(%)"
		dataType = "Age"
	}
	sumtotals = summary(totals)
	Col2[rowC] <<- "n*a"
	# total
	# for all treatments
	for (t in 1:nTreat) {
		Treat[rowC,t] <<- denominators[t]
	}
	TotalDenominator <- sumtotals$n.cases
	TotCol[rowC] <<- TotalDenominator
	pvalue[rowC] <<- ""
	print(paste("Created row",rowC,"with",dataType,"data"))
	rowC <<- rowC + 1 
  # aggreg data
  # loop for all in category
  	clist <<- rownames(totals)
	first = TRUE
	for (i in clist) {
		Col1[rowC] <<- ""
		Col2[rowC] <<- i
		# for all treatments, get incidence for this parameter
		for (t in 1:nTreat) {
			value = aggreg[i,rownames(treatments)[t]]
			percent = 100.*value/denominators[t]
			Treat[rowC,t]<<-paste(value," (",round(percent,1),")",sep = "")
		}
		# total
		value = totals[i]
		percent = 100.*value/TotalDenominator
		TotCol[rowC] <<-paste(value," (",round(percent,1),")",sep = "")
		# obtain p-value on first look only
		if (first) {
			pvalue[rowC] <<- round(pvalue_categorical(aggreg),3)
		} else { pvalue[rowC] <<- "" }
		print(paste("Created row",rowC,"with",dataType,"data"))

		first = FALSE
		rowC <<- rowC + 1			
	}
}

# function for outputing special age categories
outputAgeGreater <- function(age){
#
# 
	dataAge <<- data[data$AGE>=age,]
	aggreg <<- xtabs(~TRT01P,data=dataAge,drop.unused.levels=TRUE)
	denominators <<- xtabs(~TRT01P,data=data,drop.unused.levels=TRUE)	
	totals <<- xtabs(~AGE, data=data,drop.unused.levels=TRUE)
	Col1[rowC] <<- ""
	Col2[rowC] <<- paste(">=",age,sep = "")
 	# aggreg data
	sumtotals = summary(totals)
	TotalDenominator <- sumtotals$n.cases
	TotCol[rowC] <<- TotalDenominator

	# for all treatments, get incidence for this parameter
	for (t in 1:nTreat) {
		value = aggreg[rownames(treatments)[t]]
		percent = 100.*value/denominators[t]
		Treat[rowC,t]<<-paste(value," (",round(percent,1),")",sep = "")
	}
	# total
	value = nrow(dataAge)
	percent = 100.*value/TotalDenominator
	TotCol[rowC] <<-paste(value," (",round(percent,1),")",sep = "")
	# FIXME - obtain p-value? not possible without more dimensions
	# pvalue[rowC] <<- round(pvalue_categorical(aggreg),3)
	pvalue[rowC] <<- ""
	print(paste("Created row",rowC,"with age category data"))
	rowC <<- rowC + 1			
}



# function for general numerical calculations
outputNumerical <- function(Type){
#
# 
	indep = data$TRT01P
	if (Type==1) {
		dep = data$AGE
		totals <<- xtabs(~AGE, data=data,drop.unused.levels=TRUE)
		denominators <<- xtabs(~TRT01P,data=data,drop.unused.levels=TRUE)
		Col1[rowC] <<- "Age (yrs)"
		dataType = "Age"
	}
	else if (Type==2) {
		dep = data$WEIGHTBL
		totals <<- xtabs(~WEIGHTBL, data=data,drop.unused.levels=TRUE)
		denominators <<- xtabs(~TRT01P,data=data[data$WEIGHTBL,],drop.unused.levels=TRUE)
		dataType = "Weight"
		Col1[rowC] <<- "Weight (kg)"
	}
	sumtotals = summary(totals)
	Col2[rowC] <<- "n*a"
	# total
	# for all treatments
	for (t in 1:nTreat) {
		Treat[rowC,t] <<- denominators[t]
	}
	TotalDenominator <- sumtotals$n.cases
	TotCol[rowC] <<- TotalDenominator
	pvalue[rowC] <<- ""
	print(paste("Created row",rowC,"with",dataType,"data"))
	rowC <<- rowC + 1 
  # mean data
  # Mean, Std. Dev., Median, Q1 Q3, Min, Max
  # loop for all in category
  	clist <<- c("mean","sd","median","quantile","min")
  	clists <<- c("Mean","Std. Dev.","Median","Q1, Q3","Min, Max")
	first = TRUE
	ii = 1
	for (i in clist) {
		Col1[rowC] <<- ""
		Col2[rowC] <<- clists[ii]
		values = tapply(dep,data$TRT01P,i,na.rm=TRUE)
		valuesMax = tapply(dep,data$TRT01P,max,na.rm=TRUE)
		# for all treatments, get descriptive statistic
		for (t in 1:nTreat) {
			value = values[rownames(treatments)[t]]
			if (i=="min") {
				value2 = valuesMax[rownames(treatments)[t]]
				Treat[rowC,t]<<- paste(round(value,0),", ",round(value2,0),sep = "")
			}
			else if (i=="quantile") {
				# get 1st and 3rd quantile
				names(value)="name"
				value1  = value$name[2]	
				value2 = value$name[4]
				Treat[rowC,t]<<- paste(round(value1,0),", ",round(value2,0),sep = "")
			} else {
				Treat[rowC,t]<<-round(value,1)

			}
		}
		# total column
		if (i=="mean") {
			value = mean(dep,na.rm=TRUE)
			sValue = round(value,1)
		} else 	if (i=="sd") {
			value = sd(dep,na.rm=TRUE)
			sValue = round(value,1)
		} else 	if (i=="median") {
			value = median(dep,na.rm=TRUE)
			sValue = round(value,1)
		} else 	if (i=="quantile") {
			value = quantile(dep,na.rm=TRUE)
			value1  = value[2]	
			value2 = value[4]
			sValue = paste(round(value1,0),", ",round(value2,0),sep = "")
		} else 	if (i=="min") {
			value1 = min(dep,na.rm=TRUE)
			value2 = max(dep,na.rm=TRUE)
			sValue = paste(round(value1,0),", ",round(value2,0),sep = "")
		}
		TotCol[rowC] <<- sValue
		# obtain p-value on first row only
		if (first) {
			pvalue[rowC] <<- round(pvalue_numerical(dep,indep),3)
		} else {
			pvalue[rowC] <<- ""	
		}
		first= FALSE
		print(paste("Created row",rowC,"with",dataType,"data"))
		ii = ii + 1
		rowC <<- rowC + 1			
	}
}
# Main section
# open dataset
 data1 <- read.xport(file=dataSource)
 # filter out Placebo to get just the 2 treatments
 data <- data1[data1$TRT01P!="Placebo", ]
 # create rtf file
 rtf<-RTF(outputFileName, width=11,height=8.5,font.size=10,omi=c(.5,.5,.5,.5))
 # write out header
 setFontSize(rtf,13)
 addParagraph(rtf,tableName)
 setFontSize(rtf,10)
 # write out headers
	header[2]=getStudyName()
	for (t in 1:nHeader) {
		 addParagraph(rtf,header[t])
	} 
 addNewLine(rtf) 
 # determine the treatment names	
 treatments <<- xtabs(~TRT01P, data=data,drop.unused.levels=TRUE)
 nTreat <<- 2
 # start row counter
 rowC <<- 1
 # data for each section
 outputCategorical(1)	
 emptyRow()
 outputNumerical(1)	
 emptyRow()
 outputCategorical(4)	
 emptyRow()
 outputAgeGreater(65)	
 outputAgeGreater(75)	
 emptyRow()
 outputNumerical(2)	
 emptyRow()
 outputCategorical(2)	
 emptyRow()
 outputCategorical(3)	
 # output all the rows
 outputRows()
 setFontSize(rtf,10)
 # write out footers
	for (t in 1:nFooter) {
		 addParagraph(rtf,footer[t])
	}
 #closed file
 done(rtf)
