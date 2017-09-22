#' Convert list to data frame
#' @description convert list to a data frame with the following structure:
#'   variable, level, type, value
#' @param a a list returned by read_yml or any list
#' @return data frame
#' @name cvt_list2df
#' @importFrom stats setNames
#' @export
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist2_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   r1 <- read_yml(f1)
#'   r2 <- cvt_list2df(r1)
#' @author Hanming Tu
#' @name cvt_list2df
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  08/29/2017 (htu) - initial creation
#
cvt_list2df <- function(a) {
  # r1 <- setNames(data.frame(matrix(ncol = 5, nrow=1)), c("varname", "level", "seq", "type","value"))

  var <- list(); lvl <- list(); typ <- list(); val <- list(); seq <- list()
  i <- 0
  for (k1 in 1:length(a)) {
    i <- i + 1; var_name <- names(a[k1])
    var[i]  <- ifelse(is.null(var_name), k1, var_name);
    lvl[i]  <- 1; typ[i] <- typeof(a[[k1]]); seq[i] <- k1
    if (!is.list(a[[k1]])) { val[i] <- a[[k1]]; next(); } else {val[i] <- '' }
    for (k2 in 1:length(a[[k1]])) {
      i <- i + 1; var_name <- names(a[[k1]][k2])
      var[i] <- ifelse(is.null(var_name), k2, var_name);
      lvl[i] <- 2; typ[i] <- typeof(a[[k1]][[k2]]); seq[i] <- k2
      if (!is.list(a[[k1]][[k2]])) { val[i] <- a[[k1]][[k2]]; next();
      } else {
        val[i] <- ''
      }
      for (k3 in 1:length(a[[k1]][[k2]])) {
        i <- i + 1; var_name <- names(a[[k1]][[k2]][k3])
        var[i] <- ifelse(is.null(var_name), k3, var_name);
        lvl[i] <- 3
        typ[i] <- typeof(a[[k1]][[k2]][[k3]])
        seq[i] <- k3
        if (!is.list(a[[k1]][[k2]][[k3]])) { val[i] <- a[[k1]][[k2]][[k3]]; next();
        } else {
          val[i] <- ''
        }
        for (k4 in 1:length(a[[k1]][[k2]][[k3]])) {
          i <- i + 1; var_name <- names(a[[k1]][[k2]][[k3]][k4])
          var[i] <- ifelse(is.null(var_name), k4, var_name);
          lvl[i] <- 4
          typ[i] <- typeof(a[[k1]][[k2]][[k3]][[k4]])
          seq[i] <- k4
          if (!is.list(a[[k1]][[k2]][[k3]][[k4]])) {
            val[i] <- a[[k1]][[k2]][[k3]][[k4]]
            next();
          } else {
            val[i] <- ''
          }
          for (k5 in 1:length(a[[k1]][[k2]][[k3]][[k4]])) {
            i <- i + 1; var_name <- names(a[[k1]][[k2]][[k3]][[k4]][k5])
            var[i] <- ifelse(is.null(var_name), k5, var_name);
            lvl[i] <- 5; seq[i] <- k5
            typ[i] <- typeof(a[[k1]][[k2]][[k3]][[k4]][[k5]])
            val[i] <- a[[k1]][[k2]][[k3]][[k4]][[k5]]
            next();
          }
        }
      }
    }
  }
  n <- i
  r <- setNames(data.frame(matrix(ncol=5, nrow=length(var))), c("varname", "level", "seq", "type","value"))
  for (i in 1:length(var)) {
    r$varname[i] <- var[i]; r$level[i] <- lvl[i]; r$seq[i] <- seq[i]
    if (is.null(typ[i]) || typ[i] == 'NULL') { r$type[i] <- 'character'} else { r$type[i] <- typ[i] }
    if (is.null(val[i]) || val[i] == 'NULL') { r$value[i] <- ''} else { r$value[i] <- val[i] }
  }
  # r <- data.frame("varname"= var, "level" = lvl, "type" = typ, "value" = val)
  # r <- mapply(data.frame, "varname"=var, "level"=lvl, "type"=typ, "value"=val, SIMPLIFY = FALSE)
  # r <- do.call(rbind, Map(data.frame, "varname"=var, "level"=lvl, "type"=typ, "value"=val))
  # r <- data.frame(var,lvl,seq,typ,val)

  return(r)
}


