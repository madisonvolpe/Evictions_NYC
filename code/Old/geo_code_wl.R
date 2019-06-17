###########################################################################################################
###### Geocoding getting bbl for Buildings on Watch List using NYC GeoSearch #########
##########################################################################################################

#devtools::install_github("tarakc02/rmapzen", ref = "devel") 
#library(rmapzen)
#library(pillar)
library(sf)
library(tidyverse)
library(tidyr)

wl <- read.csv("data/data_created/buildings_watchlist.csv")
wl$building <- as.character(wl$building)

# code inspired by https://mltconsecol.github.io/post/20180210_geocodingnyc/

#Specify API
#rmapzen::mz_set_search_host_nyc_geosearch()

# only returns lat,lon 
#Y<-mz_search("87-40 165 STREET, QUEENS 11432")

# try w. url -- test! 
baseURL <- "https://geosearch.planninglabs.nyc/v1/search?text="
# test <- paste(baseURL, wl$building[1])
# test_urlencoded <- URLencode(test)
# x <- sf::st_read(test_urlencoded) #returns df, vey nice 

# CREATE URLs 
URLs <- paste(baseURL, wl$building)
URLs_encoded <- lapply(URLs, URLencode)

# loop through URLs 
geo_results <- do.call(rbind, lapply(URLs_encoded, sf::st_read))

# lets match with original dataset, can do something w. name it is pretty similar!
  
  # will add new column name  to match with the results from API, will only match on 'name' and 'postal code'
  wl<-wl %>%
    tidyr::separate(building, c("name", "postalcode"), ",") %>%
    mutate(postalcode = gsub(pattern = "\\D+", x = postalcode, replacement = ""))
  
  # before join manually change edgecombe bc its zipcode is wrong
  wl[wl$name=="409 EDGECOMBE AVENUE",10] <- 10032
  
  # join georesults with wl 
  joined<-dplyr::left_join(wl, geo_results, by = c("name", "postalcode"))
  
  #check for any nas 
  colSums(is.na(joined)) #all good 

# write to csv 
  write_csv(joined, "watchlistwBBL.csv")
