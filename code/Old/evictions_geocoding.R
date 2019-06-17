#################################
###### Geocoding Evictions Data from housingdb #########
#################################

# connect to db 
pw <- "yourpassword"
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "nyc_housing", host = "localhost", port = 5432,
                 user = "madisonvolpe", password = pw)
rm(pw)

dbExistsTable(con, "marshal_evictions_17")
evictions17<- dbGetQuery(con, "SELECT * FROM marshal_evictions_17")

# connecting to geoclient API to get BIN number 
  # install.packages("remotes")
  # remotes::install_github("austensen/geoclient")
  library(geoclient)
  library(tibble)
  library(tidyr)
  library(tidyverse)

  # API call 
  #readRenviron("~/.Renviron")
  Sys.getenv("GEOCLIENT_APP_ID")
  Sys.getenv("GEOCLIENT_APP_KEY")
  
  # Make API CALL
  api_results <- geoclient::geo_search_data(.data = evictions17, location = cleanedaddress1, rate_limit = T)
  
  write.csv(api_results, "evictions_geoclient.csv")
  