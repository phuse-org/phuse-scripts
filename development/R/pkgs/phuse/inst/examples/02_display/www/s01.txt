sliderInput("nn","Number of observations:",value = 500,min = 1,max = 1000),
radioButtons("dn","Distribution type:",
             c("Normal"="rnorm","Uniform"="runif","Log-normal"="rlnorm","Exponential"="rexp"))
