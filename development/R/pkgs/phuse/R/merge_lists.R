#' Compare and merge two lists
#' @description compare two lists using the first list as a base;
#'   update the values of the first list if the second one has
#'   different values; add varibles to the first if they doe not
#'   exist in the first list.
#' @param a the 1st list
#' @param b the 2nd list
#' @return a list containing the merged configuration
#' @export
#' @examples
#'   a <- "https://github.com/phuse-org/phuse-scripts/raw/master"
#'   b <- "development/R/scripts"
#'   c <- "Draw_Dist_R.yml"
#'   f1 <- paste(a,b,c, sep = '/')
#'   dr <- resolve(system.file("examples", package = "phuse"), "02_display")
#'   f2 <- paste(dr, "www", "Draw_Dist_R.yml", sep = '/')
#'   r1 <- read_yml(f1)
#'   r2 <- read_yml(f2)
#'   r3 <- merge_lists(r1, r2)
#' @author Hanming Tu
#' @name merge_lists
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  06/08/2017 (htu) - initial creation
#
merge_lists <- function(a, b) {
  for (k1 in 1:length(a)) {
    v1<- names(a[k1])
    if (is.null(v1) && !is.list(a[k1])) { next() }
    if (!is.null(v1) && !(v1 %in% names(b))) { next() }
    if (!is.list(a[[k1]])) {
      if (v1 %in% names(b) && length(b[[k1]])>0 ) {a[[k1]] <- b[[k1]]}
      next();
    }
    for (k2 in 1:length(a[[k1]])) {
      v2 <- names(a[[k1]][k2])
      if (is.null(v2) && !is.list(a[[k1]][k2])) { next() }
      if (!is.null(v2) && !(v2 %in% names(b[k1]))) { next() }
      if (!is.list(a[[k1]][[k2]])) {
        if ((v2 %in% names(b[[k1]])) && length(b[[k1]][[k2]])>0 ) {
          a[[k1]][[k2]] <- b[[k1]][[k2]]
        }
        next();
      }
      for (k3 in 1:length(a[[k1]][[k2]])) {
        v3 <- names(a[[k1]][[k2]][k3])
        if (is.null(v3) && !is.list(a[[k1]][[k2]][k3])) { next() }
        if (!is.null(v3) && !(v3 %in% names(b[[k1]][k2]))) { next() }
        if (!is.list(a[[k1]][[k2]][[k3]])) {
          if ((v3 %in% names(b[[k1]][[k2]])) && length(b[[k1]][[k2]][[k3]])>0 ){
            a[[k1]][[k2]][[k3]] <- b[[k1]][[k2]][[k3]]
          }
          next();
        }
        for (k4 in names(a[[k1]][[k2]][[k3]])) {
          v4 <- names(a[[k1]][[k2]][[k3]][k4])
          if (is.null(v4) && !is.list(a[[k1]][[k2]][[k3]][k4])) { next() }
          if (!is.null(v4) && !(v4 %in% names(b[[k1]][k2][k3]))) { next() }
          if ((v4 %in% names(b[[k1]][[k2]][[k3]])) &&
              length(b[[k1]][[k2]][[k3]][[k4]])>0 ) {
            a[[k1]][[k2]][[k3]][[k4]] <- b[[k1]][[k2]][[k3]][[k4]]
          }
        }
      }
    }
  }
  # merge the two lists
  c <- a
  # c <- mapply(c, a, b, SIMPLIFY = FALSE)
  for (k1 in 1:length(b)) {
    v1 <- names(b[k1])
    if (!v1 %in% names(c)) { c[[k1]] <- b[[k1]]; next() }
    # If it is just variable existing in both, we already processed it then go to next
    if (!is.list(b[[k1]])) { next() }
    # Since it is a list, we need to check further
    for (k2 in names(b[[k1]])) {
      v2 <- names(b[[k1]][k2])
      if (!v2 %in% names(c[[k1]])) {c[[k1]][[k2]] <- b[[k1]][[k2]]; next() }
      if (!is.list(a[[k1]][[k2]])) { next() }
      for (k3 in names(b[[k1]][[k2]])) {
        v3 <- names(b[[k1]][[k2]][k3])
        if (!v3 %in% names(c[[k1]][[k2]])) { c[[k1]][[k2]][[k3]] <- b[[k1]][[k2]][[k3]]; next() }
        if (!is.list(b[[k1]][[k2]][[k3]])) { next() }
        for (k4 in names(b[[k1]][[k2]][[k3]])) {
          v4 <- names(b[[k1]][[k2]][[k3]][k4])
          if (!v4 %in% names(c[[k1]][[k2]][[k3]])) {
            c[[k1]][[k2]][[k3]][[k4]] <- b[[k1]][[k2]][[k3]][[k4]]; next()
          }
        }
      }
    }
  }
  return(c)
}
