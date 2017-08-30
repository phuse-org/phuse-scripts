#' Convert list to data frame
#' @description convert list to a data frame with the following structure:
#'   variable, level, type, value
#' @param a the 1st list
#' @return data frame
#' @name list2df
#' @importFrom stats setNames
#' @export
#' @author Hanming Tu
# Function Name: cvt_list2df
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  08/29/2017 (htu) - initial creation
#
cvt_list2df <- function(a) {
  # r <- setNames(data.frame(matrix(ncol = 4), nrow=0), c("varname", "level", "type","value"))
  var <- list(); lvl <- list(); typ <- list(); val <- list()
  i <- 0
  for (k1 in names(a)) {
    if (!is.list(a[[k1]])) {
      i <- i + 1
      var[i]  <- k1; lvl[i]  <- 1; typ[i] <- typeof(a[[k1]]); val[i] <- a[[k1]]
      next();
    }
    for (k2 in names(a[[k1]])) {
      if (!is.list(a[[k1]][[k2]])) {
        i <- i + 1
        var[i] <- k2; lvl[i] <- 2; typ[i] <- typeof(a[[k1]][[k2]]); val[i] <- a[[k1]][[k2]]
        next();
      }
      for (k3 in names(a[[k1]][[k2]])) {
        if (!is.list(a[[k1]][[k2]][[k3]])) {
          i <- i + 1
          var[i] <- k3; lvl[i] <- 3
          typ[i] <- typeof(a[[k1]][[k2]][[k3]])
          val[i] <- a[[k1]][[k2]][[k3]]
          next();
        }
        for (k4 in names(a[[k1]][[k2]][[k3]])) {
          if (!is.list(a[[k1]][[k2]][[k3]][[k4]])) {
            i <- i + 1
            var[i] <- k4; lvl[i] <- 4
            typ[i] <- typeof(a[[k1]][[k2]][[k3]][[k4]])
            val[i] <- a[[k1]][[k2]][[k3]][[k4]]
            next();
          }
          for (k5 in names(a[[k1]][[k2]][[k3]][[k4]])) {
            i <- i + 1
            var[i] <- k5; lvl[i] <- 5
            typ[i] <- typeof(a[[k1]][[k2]][[k3]][[k4]][[k5]])
            val[i] <- a[[k1]][[k2]][[k3]][[k4]][[k5]]
            next();
          }
        }
      }
    }
  }
  n <- i
  r <- setNames(data.frame(matrix(ncol=4, nrow=length(var))), c("varname", "level", "type","value"))
  for (i in 1:length(var)) {
    r$varname[i] <- var[i]
    r$level[i] <- lvl[i]
    if (is.null(typ[i]) || typ[i] == 'NULL') { r$type[i] <- 'character'} else { r$type[i] <- typ[i] }
    if (is.null(val[i]) || val[i] == 'NULL') { r$value[i] <- ''} else { r$value[i] <- val[i] }
  }
  # r <- data.frame("varname"= var, "level" = lvl, "type" = typ, "value" = val)
  # r <- mapply(data.frame, "varname"=var, "level"=lvl, "type"=typ, "value"=val, SIMPLIFY = FALSE)
  # r <- do.call(rbind, Map(data.frame, "varname"=var, "level"=lvl, "type"=typ, "value"=val))

  return(r)
}
