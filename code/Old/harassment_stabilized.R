#################################
###### Harassment Cases - Rent Stabilization and Multiple Dwelling Registrations#########
#################################
library(RSocrata)
library(tidyr)
library(tidyverse)

harass_cases <- read.csv("data/data_created/harass_pluto.csv")

##### Check to see if Building is Registered as "Multiple Dwelling" #####

  ## multiple dwelling = residential buildings w. 3+ units or one- or two-family homes (where they or family do not live)! 
  ## read in dataset from open data

  mdr <- read.socrata(url = "https://data.cityofnewyork.us/resource/tesw-yqqr.csv")
  
  ## actually do not have to join yet 
  #joined <- dplyr::inner_join(harass_cases, mdr, by = "bin")

  ## lets check if all building ids that are duplicated are do to multiple tenant harassment cases ! 
    unq_n <- as.numeric(length(unique(harass_cases$buildingid)))
   
    ## duplicated cases
    duplicated.ids <- sort(harass_cases[duplicated(harass_cases$buildingid),"buildingid"])
    duplicatedd <- filter(harass_cases, buildingid %in% duplicated.ids)
    
    ## will create indicator that tells whether the street name, street num, borough and zip are equal by building id
    duplicatedd <- duplicatedd %>%
      group_by(buildingid) %>%
      mutate(streetname_c= paste0(streetname, collapse = ","),
             streetnum_c = paste0(housenumber, collapse = ","),
             borough_c  = paste0(borough, collapse = ","),
             zip_c = paste0(zip,collapse = ",")) %>%
      select(buildingid, streetname_c, streetnum_c, borough_c, zip)%>%
      arrange(desc(buildingid)) %>%
      filter(!duplicated(buildingid)) #everything looks good so we will go by building id
      
  ## create indicator variable to see where harass_cases are registered as MDR 
  harass_cases <- harass_cases %>%
    mutate(MDR = ifelse(harass_cases$buildingid %in% mdr$buildingid, 1, 0))
  
  ## now lets join and see whats going on
  joined <- dplyr::inner_join(harass_cases, mdr, by = "buildingid")
  
  