library(tidyverse)
library(lubridate)
library(RPostgreSQL)
library(ggplot2)

#################################
###### Analysis of 2017 Evictions #########
#################################

# connect to db 

pw <- "yourpassword"
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "nyc_housing", host = "localhost", port = 5432,
                 user = "madisonvolpe", password = pw)
rm(pw)

dbExistsTable(con, "marshal_evictions_17")
evictions17<- dbGetQuery(con, "SELECT * FROM marshal_evictions_17")

# check date ranges 
range(evictions17$executeddate)

# make sure that all evictions are residential 
unique(evictions17$evictiontype)

# group by bbl and count number of evictions for 2017 

evic_total_17 <- evictions17 %>%
  group_by(bbl)%>%
  summarise(n_evictions=n())%>%
  filter(!grepl("\\s+", bbl))

# group by bbl + address and count number of evictions for 2017 

# evic_total_17 <- evictions17 %>%
#   group_by(bbl, cleanedaddress2)%>%
#   summarise(n_evictions=n()) %>%
#   filter(!grepl("\\s+", bbl))


#################################
###### Bring in Pluto Data #########
#################################

pluto<- dbGetQuery(con, "SELECT * FROM pluto_18v1")
length(unique(pluto$bbl))  # one bbl makes up each row in entire dataset
length(unique(pluto$address)) #there can be more than one address on a bbl 

#################################
###### Join Count Data and Pluto #########
#################################

# left join evictions total counts by address and bbl
#names(evic_total_17)[2] <- "address"
#evic_join<-dplyr::left_join(evic_total_17, pluto, by = c("bbl", "address")) , this wasnt as effective alot of NAs 

# left join evictions total counts by bbl only 
evic_join <- dplyr::left_join(evic_total_17, pluto, by = "bbl")
sum(is.na(evic_join$borough))
problems <- evic_join[is.na(evic_join$borough),]

# exploratory graph to see evictions by land use 

evic_join %>%
  count(landuse) %>%
  ggplot(aes(x=factor(landuse), y=n)) +
  geom_bar(stat = "identity") # The majority of evictions are coming from cat 2, which is multi-family walkups,
                              # the next likely cat 1, which is  1+2 family homes 
                              # also cat 3, which is multifamily elevator! 



