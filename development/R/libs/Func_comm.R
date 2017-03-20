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
#   03/02/2017 (htu) - added download.script.files
#   03/10/2017 (htu) - added download_script

# Function Name: init_cfg
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   03/10/2017 (htu) - initial creation
init_cfg <- function(cfg) {
  curWorkDir <- getwd()
  yml_file <- cfg$files$yml_file;
  if (is.null(yml_file)) { return(cfg)}
  lfn <- paste(curWorkDir,yml_file, sep = '/')
  if (!file.exists(lfn)) {return(cfg)}
  a <- cfg
  b <- yaml.load_file(lfn)

  for (k1 in names(a)) {
    if (!is.list(a[[k1]])) {
      if (k1 %in% names(b)) {a[[k1]] <- b[[k1]]}
      next();
    }
    for (k2 in names(a[[k1]])) {
      if (!is.list(a[[k1]][[k2]])) {
        if (k2 %in% names(b[[k1]])) {a[[k1]][[k2]] <- b[[k1]][[k2]]}
        next();
      }
      for (k3 in names(a[[k1]][[k2]])) {
        if (!is.list(a[[k1]][[k2]][[k3]])) {
          if (k3 %in% names(b[[k1]][[k2]])) {
            a[[k1]][[k2]][[k3]] <- b[[k1]][[k2]][[k3]]
          }
          next();
        }
        for (k4 in names(a[[k1]][[k2]][[k3]])) {
          if (k4 %in% names(b[[k1]][[k2]][[k3]])) {
            a[[k1]][[k2]][[k3]][[k4]] <- b[[k1]][[k2]][[k3]][[k4]]
          }
        }
      }
    }
  }
  # merge the two lists
  cfg <- mapply(c, a, b, SIMPLIFY = FALSE)
  return(cfg)
}

# Function Name: download.script.files
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   03/06/2017 (htu) - initial creation
create.dir <- function(r_dir, s_dir = NULL) {
  if (is.null(s_dir)) {f_dir <- r_dir} else {f_dir <- paste(r_dir, s_dir, sep = "/", collapse = "/") }
  if (file.exists(file.path(f_dir,'/'))) {
    cat(paste("Dir - ", f_dir, " exists."))
  } else if (file.exists(f_dir)) {
    cat(paste(f_dir, " exists but is a file"))
  } else {
    cat(paste(f_dir, " does not exist - creating"))
    dir.create(f_dir, recursive = TRUE)
  }
}

# Function Name: download_script
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   03/10/2017 (htu) - initial creation
download_script <- function(cfg
  , wkDir = "workdir"
  , source_lib = TRUE
  ) {
  prg <- "download_script"
  curWorkDir <- getwd()
  if (is.null(cfg[["files"]])) { stop(paste(prg, ": Could not find input files.")) }
  if (is.null(cfg[["dirs"]]))  { stop(paste(prg, ": Could not find dir names.")) }
  f <- cfg$files;   d <- cfg$dirs

  # create the local target workdir
  ymd_dir <- format(Sys.time(), "%Y/%m/%d/%H%M%S")
  tgtDir <- paste(curWorkDir,wkDir, ymd_dir, sep = '/')
  create.dir(tgtDir)
  # download files for running the script
  cat(paste("Downloading files to ", tgtDir, "..."))
  if ("files" %in% names(cfg) && "dirs" %in% names(cfg) ) {
    if (is.null(d[["baseDir"]]) && is.null(d[["scriptDir"]])) {
      download.script.files(f, tgtDir)
    } else if (is.null(d[["baseDir"]])) {
      download.script.files(f, tgtDir, scriptDir = d$scriptDir)
    } else if (is.null(d[["scriptDir"]])) {
      download.script.files(f, tgtDir, baseDir = d$baseDir)
    } else {
      download.script.files(f, tgtDir, baseDir = d$baseDir, scriptDir = d$scriptDir)
    }
  }
  if (source_lib) {
    if ("lib_file" %in% names(f)) { source(paste(tgtDir, f$lib_file, sep = '/')) }
  }
  return(tgtDir);
}

# Function Name: download.script.files
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   03/02/2017 (htu) - initial creation
download.script.files <- function(fns, tgtDir
  , baseDir="https://github.com/phuse-org/phuse-scripts/raw/master"
  , scriptDir="data/send/PDS/Xpt"
  # , repoDir="phuse-org/phuse-scripts"
  # , repoURL='https://api.github.com/repos'
  ) {
  for (i in seq(fns)) {
    ifn <- paste(baseDir,scriptDir,fns[[i]],sep = '/')
    ofn <- paste(tgtDir,fns[[i]], sep = '/')
    create.dir(tgtDir,dirname(fns[[i]]))
    download.file(ifn,ofn,mode = 'wb')
  }
}


# Function Name: get_conn
# ---------------------------------------------------------------------------
# HISTORY   MM/DD/YYYY (developer) - explanation
#   11/14/2016 (htu) - initial creation

get_conn <- function(
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
    return()
  }
  # Create the connection string
  connect.string <- paste(
    "(DESCRIPTION=",
    "(ADDRESS=(PROTOCOL=tcp)(HOST=", host, ")(PORT=", port, "))", cns, ")", sep = "")
  con <- dbConnect(drv, username = usr,
                 password = pwd, dbname = connect.string)
  return(con)
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

  if (!dbExistsTable(con, table_name, schema = NULL)) {
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
     dbSendQuery(con, paste("truncate table", table_name))
  }

  # insert into target table
  cmd <- paste("insert into ", table_name, "select * from ", tmp_tab)
  r1.ins <- dbSendQuery(con, cmd)
  if (dbHasCompleted(r1.ins)) { dbSendQuery(con, "commit") }

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

# End of File
