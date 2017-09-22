#' Convert a class to data fram
#' @description Convert class or list to a data frame
#' @param x a class or list
#' @param exc exclude pattern
#' @param condition condition for excluding
#' @export
#' @examples
#'   r1 <- Sys.getenv()
#'   r2 <- cvt_class2df(r1)
#' @author Hanming Tu
#' @name cvt_class2df
# ---------------------------------------------------------------------------
cvt_class2df <- function (x, exc = "^__", condition = FALSE) {
  i <- 0; var <- list(); val <- list()
  for (k in names(x)) {
    if (grepl(exc, k) && condition) { next() }
    i <- i+1; var[i] <- k; val[i] <- x[[k]]
  }
  r <- setNames(data.frame(matrix(ncol=2, nrow=length(var))),
               c("variable", "value"))
  for (i in 1:length(var)) {
    r$variable[i] <- var[i]; r$value[i] <- val[i];
  }
  return(r)
}
