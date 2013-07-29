# test summary of subject level dataset
mcsl <- read.table(
  file="http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/mcsl.csv",
  header=TRUE,
  sep=",")
summary(mcsl)