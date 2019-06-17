##### PUMA  + Tidycensus #####
library(tidyverse)
library(tidycensus)
library(data.table)

# use census API Key
Sys.getenv("CENSUS_API_KEY")

#find appropriate ACS variables
v17 <- load_variables(2017, "acs5", cache = TRUE)

#B25064_001 - Median Gross Rent Variable -- MEDIAN GROSS RENT (DOLLARS)
#B25071_001 - Median Gross Rent % income -- MEDIAN GROSS RENT AS A PERCENTAGE OF HOUSEHOLD INCOME IN THE PAST 12 MONTHS
#B19001_001 - Househould Income  -- HOUSEHOLD INCOME IN THE PAST 12 MONTHS (IN 2017 INFLATION-ADJUSTED DOLLARS)
#B19013_001 - Median HHINC -- MEDIAN HOUSEHOLD INCOME IN THE PAST 12 MONTHS (IN 2017 INFLATION-ADJUSTED DOLLARS)
#B15003_022 - EDUCATIONAL ATTAINMENT FOR THE POPULATION 25 YEARS AND OVER (Estimate!!Total!!Bachelor's degree)
#B01003_001 - TOTAL POPULATION (Estimate!!Total)
#B02001_002 - RACE (Estimate!!Total!!White alone)

mgr <- get_acs(geography = 'public use microdata area', variables = c('B25064_001', 'B25071_001',
                                                                      'B19001_001', 'B19013_001',
                                                                      'B15003_022', 'B01003_001',
                                                                      'B02001_002'),
               year = 2017)

# filter for NYC 
mgr.nyc <- filter(mgr, grepl("NYC", NAME))

# make dataset wide 
acs.stats <- dcast(setDT(mgr.nyc), GEOID+NAME ~ variable, value.var = c("estimate", "moe"), sep = "")
acs.stats <- as.data.frame(acs.stats)
acs.stats <- acs.stats[1:9]

# Give better variable names 
names(acs.stats) <- c("GEOID", "Geo.Name","Total.Population","White.Alone","Bachelors.Degree","HH.Income.Year", "Median.HH.Income.Year",
                      "Median.Gross.Rent", "Median.Gross.Rent.Per.HH.Income.Year")

# Tidy neighborhood names 
acs.stats$Geo.Name <- gsub(".*--","",acs.stats$Geo.Name)
acs.stats$Geo.Name <- gsub("PUMA.*", "", acs.stats$Geo.Name)
acs.stats$Geo.Name <- trimws(acs.stats$Geo.Name)

acs.stats<- acs.stats %>%
  mutate(NonWhite = Total.Population - White.Alone) %>%
  mutate(Prop.Nonwhite = NonWhite/Total.Population)

# write.csv
write_csv(acs.stats, 'data/ACS_Data/ACS.2017.Stats.csv')
