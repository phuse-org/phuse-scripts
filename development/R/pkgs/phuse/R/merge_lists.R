#' Compare and merge two lists
#' @description compare two lists using the first list as a base;
#'   update the values of the first list if the second one has
#'   different values; add varibles to the first if they doe not
#'   exist in the first list.
#' @param a the 1st list
#' @param b the 2nd list
#' @return a list containing the merged configuration
#' @name merge_lists
#' @export
#' @author Hanming Tu
# Function Name: merge_lists
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#  06/08/2017 (htu) - initial creation
#
merge_lists <- function(a, b) {
  for (k1 in names(a)) {
    if (!is.list(a[[k1]])) {
      if (k1 %in% names(b) && b[[k1]] != '') {a[[k1]] <- b[[k1]]}
      next();
    }
    for (k2 in names(a[[k1]])) {
      if (!is.list(a[[k1]][[k2]])) {
        if (k2 %in% names(b[[k1]]) && b[[k1]][[k2]] != '') {a[[k1]][[k2]] <- b[[k1]][[k2]]}
        next();
      }
      for (k3 in names(a[[k1]][[k2]])) {
        if (!is.list(a[[k1]][[k2]][[k3]])) {
          if (k3 %in% names(b[[k1]][[k2]]) && b[[k1]][[k2]][[k3]] != '') {
            a[[k1]][[k2]][[k3]] <- b[[k1]][[k2]][[k3]]
          }
          next();
        }
        for (k4 in names(a[[k1]][[k2]][[k3]])) {
          if (k4 %in% names(b[[k1]][[k2]][[k3]]) && b[[k1]][[k2]][[k3]][[k4]] != '') {
            a[[k1]][[k2]][[k3]][[k4]] <- b[[k1]][[k2]][[k3]][[k4]]
          }
        }
      }
    }
  }
  # merge the two lists
  c <- a
  # c <- mapply(c, a, b, SIMPLIFY = FALSE)
  for (k1 in names(b)) {
    if (!k1 %in% names(c)) { c[[k1]] <- b[[k1]]; next() }
    # If it is just variable existing in both, we already processed it then go to next
    if (!is.list(b[[k1]])) { next() }
    # Since it is a list, we need to check further
    for (k2 in names(b[[k1]])) {
      if (!k2 %in% names(c[[k1]])) {c[[k1]][[k2]] <- b[[k1]][[k2]]; next() }
      if (!is.list(a[[k1]][[k2]])) { next() }
      for (k3 in names(b[[k1]][[k2]])) {
        if (!k3 %in% names(c[[k1]][[k2]])) { c[[k1]][[k2]][[k3]] <- b[[k1]][[k2]][[k3]]; next() }
        if (!is.list(b[[k1]][[k2]][[k3]])) { next() }
        for (k4 in names(b[[k1]][[k2]][[k3]])) {
          if (!k4 %in% names(c[[k1]][[k2]][[k3]])) {
            c[[k1]][[k2]][[k3]][[k4]] <- b[[k1]][[k2]][[k3]][[k4]]; next()
          }
        }
      }
    }
  }
  return(c)
}
