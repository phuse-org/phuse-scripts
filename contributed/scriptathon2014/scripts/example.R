library(SASxport)

adsl <- read.xport(file="http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adsl.xpt")

plot(adsl$AGE,adsl$WEIGHTBL)
title(main="ADSL: Baseline Weight vs Age")
