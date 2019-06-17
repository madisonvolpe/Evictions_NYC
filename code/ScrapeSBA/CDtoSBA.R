# According to NYC Health:
  
  # Neighborhood Definition:Sub-borough areas are groups of census tracts summing to at least 100,000
  # residents, determined by the NewYork City Department of Housing Preservation and Development.
  # The boundaries of sub-borough areas often approximate those of Community Districts.

# For some of our SBA we want to add the community district it roughly maps to so we can get the
# community district indicators 

  # For Queens, SI, and Brooklyn they match 
  # For Manhattan + the Bronx they do not

  dat <- read_csv("data/data_final/HVS_HH_Ind.csv")
   
  dat <- dplyr::distinct(dat, dat$borough, dat$sba.name)
  
  dat[dat$`dat$borough` == 1,1] <- "Bronx"
  dat[dat$`dat$borough` == 2,1] <- "Brooklyn"
  dat[dat$`dat$borough` == 3,1] <- "Manhattan"
  dat[dat$`dat$borough` == 4,1] <- "Queens"
  dat[dat$`dat$borough` == 5,1] <- "Staten Island"
  
  names(dat) <- c("Borough", "SBA.Name")
  
  # Add mapping to community district indicator 'Community District'
  
  dat$Map.CommunityDistrict <- NA
    
    # SI  
    dat[dat$Borough == "Staten Island", 3] <- c("SI 01", "SI 02", "SI 03")
    
    # Queens 
    dat[dat$Borough == 'Queens', 3] <- c("QN 01", "QN 02", "QN 03", "QN 04",
                                         "QN 05", "QN 06", "QN 07", "QN 08",
                                         "QN 09", "QN 10", "QN 11", "QN 12",
                                         "QN 13", "QN 14")
    
    # Brooklyn 
    dat[dat$Borough == 'Brooklyn', 3] <- c("BK 01", "BK 02", "BK 03", "BK 04",
                                           "BK 05", "BK 06", "BK 07", "BK 08",
                                           "BK 09", "BK 10", "BK 11", "BK 12", 
                                           "BK 13", "BK 14", "BK 15", "BK 16",
                                           "BK 17", "BK 18")
   # Manhattan 
    dat[dat$Borough == 'Manhattan', 3] <- c("MN 12", "MN 01/MN 02", "MN 03",
                                            "MN 04/MN 05", "MN 06", "MN 07", 
                                            "MN 08", "MN 09", "MN 10",
                                            "MN 11")
    # Bronx 
    dat[dat$Borough == 'Bronx', 3] <- c("BX 01/BX 02", "BX 03/BX 06", "BX 04",
                                        "BX 05", "BX 07", "BX 08", "BX 09","BX 10",
                                        "BX 11","BX 12")
    
  # write to csv 
    write.csv(dat, "data/data_created/sbatocd.csv")
  