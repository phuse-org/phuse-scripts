library(phuse)

expect_equal(10, 10)

s1 <- "Testing is fun!"
expect_match(s1, "Testing")

a <- list(1:10, letters)
expect_output(str(a), "List of 2")
expect_output(str(a), "int [1:10]", fixed = TRUE)
