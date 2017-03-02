# File Name: Func_comm.R
# PURPOSE: This file contains the commonly used functions.
# PROGRAMS CALLED: N/A
# NOTES:
#   1. Make sure the proper required libraries were called.
#   2. Make the name convention is followed
# PARAMETERS EXPLAINED: N/A
# HISTORY   MM/DD/YYYY (developer) - explanation
#   11/14/2016 (htu) - initial creation
#   11/14/2016 (htu) - added get_conn
#   02/15/2017 (htu) - added xml2DF
#

# Function Name: get_conn
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   11/14/2016 (htu) - initial creation

get_conn <- function (
  usr, pwd, host, sid="", service_name="", port=1521
  ) {
  drv <- dbDriver("Oracle")
  # (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = adevscan.adevgns.orst.com)(PORT = 1521))
  # (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = adevpdb)))
  cn1 <- "(CONNECT_DATA = (SERVER = DEDICATED) "
  if (nchar(sid) > 0) {
    cns <- paste(cn1, "(SID = ", sid, "))")
  } else if (nchar(service_name) > 0) {
    cns <- paste(cn1, "(SERVICE_NAME = ", service_name, "))")
  } else {
    print(paste0("SID or Service Name is required (0", sid, "_", service_name, "0)"))
    return ()
  }
  # Create the connection string
  connect.string <- paste(
    "(DESCRIPTION=",
    "(ADDRESS=(PROTOCOL=tcp)(HOST=", host, ")(PORT=", port, "))", cns, ")", sep = "")
  con <- dbConnect(drv, username = usr,
                 password = pwd, dbname=connect.string)
  return (con)
}

# Function Name: load.df2ora
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   03/02/2017 (htu) - initial creation

require(ROracle)
load.df2ora = function(con, df, table_name, tmp_tab = '' , drop_tmp = TRUE, trunc_tgt = TRUE) {
  # 1. set parameters
  Sys.setenv(TZ = "EST")
  Sys.setenv(ORA_SDTZ = "EST")

  if (! dbExistsTable(con, table_name, schema = NULL)) {
    r1.write_tab <- dbWriteTable(con,table_name,df)
    return(r1.write_tab)
  }

  if (nchar(tmp_tab) <= 0) {
    tmp_tab <- paste0('XX_', format(Sys.time(), "%Y%m%d_%H%M%S"))
  }

  # load to a temp table
  if (drop_tmp) {
    if (dbExistsTable(con, tmp_tab, schema = NULL)) {
      dbSendQuery(con, paste("drop table ", tmp_tab)) }
  }
  dbWriteTable(con,tmp_tab,df)

  # trucate the target table
  if (trunc_tgt) {
    if (dbExistsTable(con, table_name, schema = NULL)) {
     dbSendQuery(con, paste("truncate table", table_name)) }
  }

  # insert into target table
  if (dbExistsTable(con, table_name, schema = NULL)) {
    cmd <- paste("insert into ", table_name, "select * from ", tmp_tab)
    r1.ins <- dbSendQuery(con, cmd)
    if (dbHasCompleted(r1.ins)) { dbSendQuery(con, "commit") }
  } else {
    r1.ins <- dbWriteTable(con,table_name,df)
  }

  # drop the temp table
  if (drop_tmp) {
    if (dbExistsTable(con, tmp_tab, schema = NULL)) {
      dbSendQuery(con, paste("drop table ", tmp_tab)) }
  }
  return(r1.ins)
}

# Function Name: xml2DF
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   02/15/2016 (htu) - initial creation

require(XML)
xml2DF = function(doc, xpath, isXML = TRUE, usewhich = TRUE, verbose = TRUE) {

    tmp <- doc[which(names(doc) != "comment")]
    doc <- tmp
    if (!isXML)
        doc = xmlParse(doc)
    #### get the records for that form
    nodeset <- getNodeSet(doc, xpath)

    ## get the field names
    var.names <- lapply(nodeset, names)

    ## get the total fields that are in any record
    fields = unique(unlist(var.names))

    ## extract the values from all fields
    dl = lapply(fields, function(x) {
        if (verbose)
            print(paste0("  ", x))
        xpathSApply(doc, paste0(xpath, "/", x), xmlValue)
    })

    ## make logical matrix whether each record had that field
    name.mat = t(sapply(var.names, function(x) fields %in% x))
    df = data.frame(matrix(NA, nrow = nrow(name.mat), ncol = ncol(name.mat)))
    names(df) = fields

    ## fill in that data.frame
    for (icol in 1:ncol(name.mat)) {
        rep.rows = name.mat[, icol]
        if (usewhich)
            rep.rows = which(rep.rows)
        df[rep.rows, icol] = dl[[icol]]
    }

    return(df)
}

