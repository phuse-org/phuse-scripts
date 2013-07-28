# boxplot.R script
# copied verbatim from
# https://www.ctspedia.org/do/view/CTSpedia/StatGraphTopic000
# on July 28 2013
# by Mike Carniello

set.seed(123)
drug <- as.integer(rnorm(200, 2, 2))
drug[drug<0] <- 0
    
placebo <- as.integer(rnorm(200, 4, 3))
placebo[placebo<0] <- 0

duration <- c(drug, placebo)
trt <- factor(rep(c('Drug','Placebo'), each=200))

ddrug <- density(drug)
dplac <- density(placebo)

#png('C:/Research/Graphics/Graphs4Display/webpages/classes/pages/images/boxplotbasic.png',
#         width=500, height=500)
    
boxplot(duration~trt, col=c('blue','grey60'), horizontal=TRUE,
           main='horizontal=TRUE', varwidth=TRUE, notch=TRUE)
#dev.off()
