# http://www.ats.ucla.edu/stat/r/pages/looping_strings.htm

hsb2 <- read.csv("http://www.ats.ucla.edu/stat/data/hsb2.csv")
names(hsb2)

varlist <- names(hsb2)[8:11]

models <- lapply(varlist, function(x) {
  lm(substitute(read ~ i, list(i = as.name(x))), data = hsb2)
})

models[[1]]

lapply(models, summary)

par(mfrow = c(2, 2))
# ask = TRUE
invisible(lapply(models, plot))

# https://www.r-bloggers.com/using-apply-sapply-lapply-in-r/

m <- matrix(data=cbind(rnorm(30, 0), rnorm(30, 2), rnorm(30, 5)), nrow=30, ncol=3)
apply(m, 1, mean)
apply(m, 2, mean)
apply(m, 2, function(x) length(x[x<0]))
apply(m, 2, function(x) mean(x[x>0]))
apply(m, 2, is.vector)

sapply(1:3, function(x) x^2)
unlist(lapply(1:3, function(x) x^2))      # this is the same as above sapply
lapply(1:3, function(x) x^2)
sapply(1:3, function(x) x^2, simplify=F)  # this is the same as above lapply

# https://hopstat.wordpress.com/2014/01/14/faster-xml-conversion-to-data-frames/



function (x, i, j, ..., addFinalizer = NA)
{
  kids = xmlChildren(x, addFinalizer = addFinalizer)
  if (is.logical(i))
    i = which(i)
  if (is(i, "numeric"))
    structure(kids[i], class = c("XMLInternalNodeList",
                                 "XMLNodeList"))
  else {
    id = as.character(i)
    which = match(sapply(kids, xmlName), id)
    structure(kids[!is.na(which)], class = c("XMLInternalNodeList",
                                             "XMLNodeList"))
  }
}


# http://stackoverflow.com/questions/25315381/using-xpathsapply-to-scrape-xml-attributes-in-r

'<div class="offer-name">
  <a href="http://www.somesite.com" itemprop="name">Fancy Product</a>
  </div>' -> xData
library(XML)
parsedHTML <- xmlParse(xData)
Products <- xpathSApply(parsedHTML, "//div[@class='offer-name']", xmlValue)
hrefs <- xpathSApply(parsedHTML, "//div/a", xmlGetAttr, 'href')
> hrefs
[1] "http://www.somesite.com"