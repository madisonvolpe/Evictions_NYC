###########################################################################################################
###### Analysis of 2017 Housing Litigations (Department of Housing Preservation and Development) #########
##########################################################################################################

library(RSocrata)
library(plyr)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(RPostgreSQL)

#back up in case url is down  
#HPD<- read.csv("data/Housing_Litigations_Backup.csv")

HPD<-read.socrata(url = "https://data.cityofnewyork.us/resource/59kj-x8nc.csv")

  ## filter for harassment 
  harass <- filter(HPD, casetype == "Tenant Action/Harrassment")

  ## find cases where we definitlely know the outcome
  harass_fil <- filter(harass, findingofharassment != "")

  ## filter for cases where the case status is closed 
  harass_fil <- filter(harass_fil, casestatus == "CLOSED")

  ## clean dates 
  harass_fil$caseopendate <- lubridate::mdy_hms(harass_fil$caseopendate) 
    #should see the majority of cases from 2015+, this was when the Tenant Harassment Prevention Task Force (THPT)
    #was created 
  
  ## clean nta names 
  ntas <- read.socrata("https://data.cityofnewyork.us/resource/swpk-hqdp.csv")
    
    ## save vector of ntas names
    ntas_nms <- unique(ntas$nta_name)
    
    ## for loop to extract right nta name 
    harass_fil$nta_clean <- NA
    indx <- NA
    
    for(i in 1:nrow(harass_fil)){
      indx <- grep(harass_fil$nta[i], ntas_nms, ignore.case = T)
        if(length(indx) > 1 & length(indx) < 195){
          harass_fil$nta_clean[i] <- paste(ntas_nms[c(indx)],collapse = ", ")
        } else if (length(indx) == 195){
          harass_fil$nta_clean[i] <- ""
        } else {
          harass_fil$nta_clean[i] <- ntas_nms[indx]
        }
    }
  
#### Some Exploratory Graphs #### 
  
  harass_fil %>%
    mutate(year = lubridate::year(caseopendate)) %>%
    count(year) %>%
    filter(year != 2019) %>%
    ggplot(aes(x = year, y = n)) +
      geom_line() +
      ggtitle("Number of Tenant Action/Harassment Cases by Year")
  
  harass_fil %>%
    group_by(nta_clean) %>%
    summarise(n = n()) %>%
    arrange(desc(n)) %>%
    slice(1:20) %>%
    ggplot(aes(x=nta_clean, y = n)) +
      geom_bar(stat = 'identity') +
      coord_flip() +
      ggtitle("Number of Tenant Action/Harassment Cases by NTA")
  
  harass_fil$zip <- as.character(harass_fil$zip)
  
  harass_fil %>%
    group_by(zip) %>%
    summarise(n=n()) %>%
    arrange(desc(n)) %>%
    slice(1:20) %>%
    ggplot(aes(x=zip, y =n)) +
      geom_bar(stat = 'identity') + 
      coord_flip() +
      ggtitle("Number of Tenant Action/Harassment Cases by Zip")


#### Link to Pluto Data #### 
  
  # database 
  pw <- "yourpassword"
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = "nyc_housing", host = "localhost", port = 5432,
                   user = "madisonvolpe", password = pw)
  rm(pw)
  
  pluto<- dbGetQuery(con, "SELECT * FROM pluto_18v1")
  length(unique(pluto$bbl))  # one bbl makes up each row in entire dataset
  length(unique(pluto$address)) #there can be more than one address on a bbl 
  
  #check to see if the bbl from harass_gil connect to the bbl in the pluto dataset 
  sum(harass_fil$bbl %in% pluto$bbl)
    #the majority are 
    #SEE WHY ARENT BEING JOINED LATER
  
  #join harass_fil to pluto dataset 
  harass.pluto <-join(harass_fil, pluto, by = "bbl", type ="inner")
  
  #change same names 
  names(harass.pluto)[28] <- "lot_pluto"
  names(harass.pluto)[27] <- "block_pluto"
  
  #write to csv 
  
  
  #bldingclass 
  unique(harass.pluto$bldgclass)
  table(harass.pluto$bldgclass)
  
  #bldingclass
  harass.pluto %>%
    group_by(bldgclass) %>%
    summarise(n=n()) %>%
    arrange(desc(n))%>%
    slice(1:20) %>%
    ggplot(aes(x=bldgclass, y = n))+
      geom_bar(stat = "identity") +
      ggtitle("Top 20 Tenant Harassment Cases by Building Class")
  
    #c1 - multifamily walkup 
    #c0 - multifamily walkup 
    #d1 - multifamily elevator
    #b1, b2 - multifamily walkup buildings 
  
  #landuse
  harass.pluto %>%
    group_by(landuse) %>%
    summarise(n=n()) %>%
    arrange(desc(n))%>%
    filter(!is.na(landuse)) %>%
    ggplot(aes(x=factor(landuse), y = n))+
    geom_bar(stat = "identity") +
    ggtitle("Tenant Harassment Cases by landuse")
  
    #2 - Multi-Family Walk-Up Buildings
    #1 - One & Two Family Buildings
    #3 - Multi-Family Elevator Buildings
    #4 - Mixed Residential & Commercial Buildings
  
  #harassment findings v. no harassment findings graphs
  
  
  
##### Link to Landlord Watchlist #####
  
  bldgs_wl <- read.csv("data/data_created/watchlistwBBL.csv")

  # see if there are any tenant harrasmments in the watchlist 
  sum(harass_fil$bbl %in% bldgs_wl$pad_bbl) # okay there is only 8 
  
  # lets look at these eight 
  harass_fil[harass_fil$bbl %in% bldgs_wl$pad_bbl,]
  

##### Link to Evictions 2017 ##### 
  
  evictions <- dbGetQuery(con, "SELECT * FROM marshal_evictions_17")
  
  
  
##### Problems #####  
  #this could be problematic maybe ? 
  table(harass.pluto$findingofharassment, harass.pluto$bldgclass)
  table(harass.pluto$findingofharassment, harass.pluto$landuse)  
  
  
    
  