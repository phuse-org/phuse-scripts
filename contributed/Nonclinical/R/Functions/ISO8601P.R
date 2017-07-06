# R script designed to convert ISO 8601 intervals starting with a P into seconds
# This assumes that a month has 365.25/12 days and that a year has 365.25 days.
# Other ISO 8601 date times may be handled using https://cran.r-project.org/web/packages/parsedate/parsedate.pdf
# 
library(stringr)
input="P1Y2M3DT4H5M6S"
s<-"^(\\+|-)?P((((([0-9]+(\\.[0-9]+)?)Y)?(([0-9]+(\\.[0-9]+)?)M)?(([0-9]+(\\.[0-9]+)?)D)?)(T(([0-9]+(\\.[0-9]+)?)H)?(([0-9]+(\\.[0-9]+)?)M)?(([0-9]+(\\.[0-9]+)?)S)?)?)|([0-9]+(\\.[0-9]+)?)W)$"
result  <- str_match(input,s)
if(str_detect(input,s))
{
  # we have a time interval this script can handle
  result[is.na(result)] <- 0  # replace NA values with 0
  if(str_detect(input,"^-P"))
  {
    sign <- (-1)
  } else
  {
    sign <- (1)
  }
  year<-as.numeric(result[7])
  month<-as.numeric(result[10])
  day<-as.numeric(result[13])
  hour<-as.numeric(result[17])
  minute<-as.numeric(result[20])
  second<-as.numeric(result[23])
  week<-as.numeric(result[25])
  time<-sign*(((year*365.25+month*(365.25/12)+7*week+day)*24+hour)*60+minute)*60+second
} else 
{
   print("This is not an interval this script can handle\n")
}
time
