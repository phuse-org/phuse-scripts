## Functions to read config files

## readConfig
# Input - List of configuration data.frames
# Output- List of configurations, which are lists of tests
readConfig <- function(configFile){
  
  if (class(configFile) != "data.frame") {
    stop(paste0("configFile must be a data.frame, it was ", class(configFile)))
  }
  
  #Detect columns for an observation configuration.
  configFileColumns <- names(configFile)
  catInd <- str_detect(configFileColumns, "(CAT)$")
  testInd <- str_detect(configFileColumns, "(TEST)$")
  testcdInd <- str_detect(configFileColumns, "(TESTCD)$")
  specInd <- str_detect(configFileColumns, "(SPEC)$")
  speciesInd <- str_detect(configFileColumns, "SPECIES")
  sexInd <- str_detect(configFileColumns, "SEX")
  meanInd <- str_detect(configFileColumns, "(STRESM)$")
  sdInd <- str_detect(configFileColumns, "(STRESSD)$")
  unitInd <- str_detect(configFileColumns, "(STRESU)$")
  factorInd <- str_detect(configFileColumns, "(FACT)$")
  proportionInd <- str_detect(configFileColumns,"(PROP)$")
  
  
  data.frame(
    cat = configFile[catInd],
    test = configFile[testInd],
    testcd = configFile[testcdInd],
    spec = configFile[specInd],
    species = configFile[speciesInd],
    sex = configFile[sexInd],
    mean = configFile[meanInd],
    sd = configFile[sdInd],
    unit = configFile[unitInd],
    fact = configFile[factorInd],
    prop = configFile[proportionInd]
  )
}

getConfig <- function(domain) {
  
  if(exists(paste0(domain, "config"))) {
    return(get0(paste0(domain, "config")))
  } else {
    if(file.exists(paste0(sourceDir,"/configs/", domain, "config.csv"))){
      print(paste0("Reading Configuration Files: ", domain))
      dfList = read.csv(paste0(sourceDir,"/configs/", domain, "config.csv"), stringsAsFactors = FALSE)
      dfRead = readConfig(dfList)
      assign(paste0(domain,"config"),dfRead,envir = .GlobalEnv)
    } else {
      warning(paste0("Config Not Found in ", paste0("configs/", 
                                                    domain, "config.csv")))
      NULL
    }
    
  }
}

getTestCDs <- function(aDomain, aSpecies) {
  switch(aDomain,
         "BW" = {aConfig <- getConfig("BW")},
         "CL" = {aConfig <- getConfig("CL")},
         "LB" = {aConfig <- getConfig("LB")},
         "MI" = {aConfig <- getConfig("MI")},
         "PM" = {aConfig <- getConfig("PM")},
         "MA" = {aConfig <- getConfig("MA")},
         "OM" = {aConfig <- getConfig("OM")},
         "PP" = {aConfig <- getConfig("PP")},
         "PC" = {aConfig <- getConfig("PC")}
  )
  testcd_ind <- str_which(names(aConfig), "TESTCD")
  aList <- aConfig[aConfig$SPECIES == aSpecies,testcd_ind]
  print(aList)
  as.data.frame(unique(aList))
}