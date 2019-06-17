suppressPackageStartupMessages(library(raster))
suppressPackageStartupMessages(library(survey))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(sf)) # for shapefiles
suppressPackageStartupMessages(library(maptools))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(rgeos))
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(kableExtra))
suppressPackageStartupMessages(library(gridExtra))
suppressPackageStartupMessages(library(plotly))
suppressPackageStartupMessages(library(geosphere))

## Pre-processing! 
options(scipen = 999)
# Before anything else read in shapefile and join the sub-borough areas to dataset 
  
    # read in shapefile 
    shp <- rgdal::readOGR(dsn = "data/NYC_HVS/NYC_Sub_borough_Area")
    shp@data$id = shp@data$bor_subb
    
    # transform shape for ggplot2
    shp.points = fortify(shp, region="id")
    shp.df = plyr::join(shp.points, shp@data, by="id")
    rm(shp.points)
    names(shp.df)[8] <- "sba"
    
# Bring in code for creating SEs from replicate weights 
    source("code/ReplicateWeights.R")
   
# Some notes this is data aggregated by the NYC HPD for their 2019 Data Expo - it is simplified, which is good for me
# It only includes only household-level occupied records
# It has both household weights + replicate weights !


# Load in Data 

  hvs <- read.csv("data/NYC_HVS/NYC_HVS_2017_HO.csv")
  
# The more detailed variable names are the first row - extract them out 
  
  varnames <- hvs[1,]

# remove more detailed names 
  hvs <- hvs[-1,]
  
# add sub-borough name from shpfile data to dataset it will make analysis easier!
  hvs$sba <- as.numeric(as.character(hvs$sba))
  hvs$sba.name <- shp.df$NAME[match(hvs$sba, shp.df$sba)]
  sum(is.na(hvs$sba.name)) #check none missing 
  
# recode race - hispanic origin 
  levels(hvs$X_1e) <- list(No=c("1"), Yes=c("2", "3", "4", "5", "6", "7"))

# recode race - all
  levels(hvs$X_1f) <- list(White = c("1"), Black = c("2"), Asian = c("4", "5", "6", "7", "8"), PI = c("9"), Native = c("3"),
       TwoRaces = c("10"))

# make a white v. minority categpry for simpler evaluation 
  
hvs <- hvs %>%
    mutate(RaceSimplified = case_when(
    X_1e == "No" & X_1f == "White" ~ "White", #white people
    X_1e == "Yes"& X_1f == "White" ~ "Minority", # white hispanics as minority
    X_1e == "No" & X_1f != "White" ~ "Minority", # nonwhite non hispanics as minority
    X_1e == "Yes"& X_1f != "White" ~ "Minority")) 
  
  
  
# recode income, rather make continuous and then make income categories 
  hvs$hhinc  <- as.numeric(as.character(hvs$hhinc))
  hvs$hhinc[hvs$hhinc < 0] <- -1
  hvs$hhinc[hvs$hhinc == 9999999] <- 0
  #hvs$hhinc<-
  cut(hvs$hhinc, seq(-1,3000000,25000))
  
# recode hh moving variable (add labels)
  hvs$X_6 <- factor(hvs$X_6, levels =   c("1","2","3","4","5","6","7","8",
                             "9", "10", "11", "12", "13", "14",
                             "15", "16", "17", "18", "19", "20", 
                             "98", "99", "Reason for Moving"),
         labels = c("Change in Employment Status", "Looking for Work", "Commuting Reasons", "School",
                    "Other Financial/ Employment Reason", "Needed Larger House or Apartment", 
                    "Widowed, Divorced, Deceased", "Newly Married", "To be close to Relatives", 
                    "Establish Separate Household", "Other Family Reason", "Wanted this neighborhood/ better services",
                    "Other neighborhood reason", "Wanted to own residence", "Wanted to rent residence",
                    "Wanted greater housing affordability", "Wanted better quality housing", 
                    "Evicted, displaced, landlord harassment", "Other housing reason", "Any other reason",
                    "Not Reported", "Not Applicable", "X"))

# Examine the Reason for HH Moving Variable 
  # Subset moved people 
  moved <- filter(hvs, X_6 != "Not Reported" & X_6 != "Not Applicable") 
  
  # Okay so we see that (from respondents there are only 3,266 observations that moved) - obviously 
  # this is more when we add up the sampling weights etc, so let's do that now 
  # The full Sample ('Recently Moved') Estimated 
    # just add up the household weights! 
    # note household weights have 5 implied decimal places (so after will divide by 100,000)
    moved$hhweight <- as.numeric(as.character(moved$hhweight))
    sum(moved$hhweight)/100000
    # The Full-Sample Recently Moved Estimate for all of NYC is : 781,263 (those who moved after 2013)
  # Calculate the SE for this estimate 
    rep.wts.SE(moved) # the SE is 10,945.73 


         
    
        
# Which reason for moving categories dominated? 
    
    moved %>% 
      select(X_6) %>%
      group_by(X_6) %>%
      summarise(n = n()) %>%
      arrange(desc(n)) %>%
    ggplot(aes(x=X_6, y = n)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      ggtitle('Moved Reason - 2017 NYC HVS')
    
# When people said 'they were evicted/displaced', where do they reside now?
    
    moved %>%
      select(sba.name, X_6) %>%
      filter(X_6 == 'Evicted, displaced, landlord harassment') %>%
      group_by(sba.name) %>%
      summarise(n=n()) %>%
      arrange(desc(n)) %>%
    ggplot(aes(x=sba.name, y=n))+
      geom_bar(stat = 'identity') + 
      coord_flip() +
      ggtitle("Where do Evicted/Displaced People Move?")

# Naive analysis! 
    
# Estimates for how many people are moving to these neighborhoods after being evicted/displaced 
# Will include the full sample estimate (sum of hhweight)
# Will also include the SE estimate from the replicate weights 
# Basically Estimates by Neighborhood ! 
    # will include estimate (sum of hhweight)
    # SE estimate (using replicate weights)
    
    evicted.displaced <- moved %>%
      filter(X_6 == 'Evicted, displaced, landlord harassment')
    
    EstbyNeighborhood.ed <- rep.wts.grp.SE(evicted.displaced, sba.name)

    #create table estimate 
    # kable(EstbyNeighborhood.ed, format = 'html', col.names = c('SBA', 'Sample Estimate', 'Var', 'SE'))
      
# Let's map this so people could see where people move/stay after being evicted/displaced 
    
    # add neighborhoods to EstbyNeighborhood that are not in original df 
    SBA <- unique(shp.df$NAME)
    SBAnoEvicted <- SBA[!SBA %in% EstbyNeighborhood.ed$sba.name]
    SBAnoEvicted <- data.frame(sba.name = SBAnoEvicted, N0 = 0, Var = 0, SE = 0)
    
    # adds those neighborhoods, where evicted/displaced people were not residing 
    EstbyNeighborhood.ed <- rbind(EstbyNeighborhood.ed, SBAnoEvicted) 
    names(EstbyNeighborhood.ed)[1] <- "NAME"
    
    #now join these figures to shapefile 
    shp.df.evic <-join(shp.df, EstbyNeighborhood.ed, by = "NAME")
    
    # lets map this 
    map.evic <- ggplot(shp.df.evic) + 
      aes(long,lat,group=group) +
      geom_polygon(aes(fill=N0)) + 
      scale_fill_continuous(type = "viridis")+
      geom_path(color="white") + 
      theme_bw() +
      ggtitle("Neighborhoods where Evicted/Displaced/Harassed People Reside")

# How About People who Move for Greater Housing Affordability? Do people who move from displacement move to same areas
# as people seeking greater Housing Affordability? 
    
    moved %>%
      select(sba.name, X_6) %>%
      filter(X_6 == 'Wanted greater housing affordability') %>%
      group_by(sba.name) %>%
      summarise(n=n()) %>%
      arrange(desc(n)) %>%
      ggplot(aes(x=sba.name, y=n))+
      geom_bar(stat = 'identity') + 
      coord_flip() +
      ggtitle("Where do People that Want Housing Affordability Move?")
    
    housing.afford <- moved %>%
      filter(X_6 == 'Wanted greater housing affordability')
    
    EstbyNeighborhood.ha <- rep.wts.grp.SE(housing.afford, sba.name)
    # kable(EstbyNeighborhood.ha, format = 'html', col.names = c('SBA', 'Sample Estimate', 'Var', 'SE'))
    
    # add neighborhoods to EstbyNeighborhood.ha that are not in original df 
    SBA <- unique(shp.df$NAME)
    SBAnoha <- SBA[!SBA %in% EstbyNeighborhood.ha$sba.name]
    SBAnoha <- data.frame(sba.name = SBAnoha, N0 = 0, Var = 0, SE = 0)
    
    # adds those neighborhoods, where evicted/displaced people were not residing 
    EstbyNeighborhood.ha <- rbind(EstbyNeighborhood.ha, SBAnoha) 
    names(EstbyNeighborhood.ha)[1] <- "NAME"
    
    #now join these figures to shapefile 
    shp.df.ha <-join(shp.df, EstbyNeighborhood.ha, by = "NAME")
    
    # create map 
    map.ha<-ggplot(shp.df.ha) + 
      aes(long,lat,group=group) +
      geom_polygon(aes(fill=N0)) + 
      scale_fill_continuous(type = "viridis")+
      geom_path(color="white") + 
      theme_bw() +
      ggtitle("Neighborhoods where People that Moved Seeking Housing Affordability Reside")

# Combination of maps
    map.evic
    map.ha


    
######### Go a Level Deeper and Expand on this Analysis Adding some Racial Component ##### 

#### EVICTIONS/ DISPLACEMENT 
    
    # Evicted/displaced/harassed in total 
    sum(evicted.displaced$hhweight)/100000  #13,623.21 in total were evicted in 2017 
    rep.wts.SE(evicted.displaced) # the SE is 1816.878
    
    
    # How many people are evicted/displaced/harassed that are a minority (Full Sample Estimate)
    evicted.minority <- moved %>%
                        filter(X_6 == 'Evicted, displaced, landlord harassment' & RaceSimplified == 'Minority')
    
    sum(evicted.minority$hhweight)/100000  #9,692.036 minorities are displaced throughout NYC 
    rep.wts.SE(evicted.minority) # the SE is 1574.457! 
    
    # How many people are evicted/displaced/harassed that are white (Full Sample Estimate)
    evicted.white <-  moved %>%
      filter(X_6 == 'Evicted, displaced, landlord harassment' & RaceSimplified == 'White')
    
    sum(evicted.white$hhweight)/100000  #3931.175 whites are displaced throughout NYC 
    rep.wts.SE(evicted.white) # the SE is 1030.248!  
    
  # Not a surprise but most evictions/displaced/landlord harassments are for minorities (blacks, hispanics, asians,etc.)
    
  # What neighborhoods are recently evicted/displaced people ending up in based on minority v. nonminority status ? 
    
    moved %>%
      select(sba.name,borough,X_6, RaceSimplified, hhweight) %>%
      filter(X_6 == 'Evicted, displaced, landlord harassment') %>%
      group_by(sba.name, RaceSimplified) %>%
      summarise(n=n(),amt=ceiling((sum(hhweight)/100000))) %>%
      arrange(desc(amt)) %>%
   ggplot(aes(x=sba.name, y = n, fill = RaceSimplified)) +
      geom_bar(stat = 'identity', position = 'dodge') +
      facet_grid(~RaceSimplified) +
      coord_flip() +
      ggtitle("Where do Evicted/Displaced People Reside based on Race?")
    
  
  # create a table for this with Full Sample estimate, Var, and SE 
    EstbyNeighborhood.edRace <- rep.wts.2grps.SE(evicted.displaced, sba.name, RaceSimplified)
  # kable(EstbyNeighborhood.edRace, format = 'html', col.names = c('SBA',"Status",'Sample Estimate', 'Var', 'SE'))
    

 # let's map this 
    
    #before I join with shpfile I need to make this wide and where only interested in Full Sample estimate so that is what I'll keep
    EstbyNeighborhood.edRaceWide <- spread(EstbyNeighborhood.edRace[1:3], RaceSimplified, N0)
    
    EstbyNeighborhood.edRaceWide <- EstbyNeighborhood.edRaceWide %>% mutate_at(vars(Minority, White),
                                                                               function(x) as.numeric(as.character(x)))
    
    
    EstbyNeighborhood.edRaceWide$Minority[is.na(EstbyNeighborhood.edRaceWide$Minority)] <- 0
    EstbyNeighborhood.edRaceWide$White[is.na(EstbyNeighborhood.edRaceWide$White)] <- 0
    
    # add in neighborhoods not in EstbyNeighborhood.edRaceWide
    SBA <- unique(shp.df$NAME)
    SBAnoEvictedRaceWide <- SBA[!SBA %in% EstbyNeighborhood.edRaceWide$sba.name]
    SBAnoEvictedRaceWide <- data.frame(sba.name = SBAnoEvictedRaceWide, Minority = 0, White = 0)
    
    # adds those neighborhoods, where evicted/displaced people were not residing 
    EstbyNeighborhood.edRaceWide<- rbind(EstbyNeighborhood.edRaceWide, SBAnoEvictedRaceWide) 
    names(EstbyNeighborhood.edRaceWide)[1] <- "NAME"
    
    # join to shapefile with (N0 estimate for all evicted/displaced already -- shp.df.evic)
     
    shp.df.evic <-join(shp.df.evic, EstbyNeighborhood.edRaceWide, by = "NAME")
    
    # make map
    
    #need to find centroid 
    
    # Get polygons centroids
    centroids <- as.data.frame(centroid(shp))
    colnames(centroids) <- c("long_cen", "lat_cen") 
    centroids <- data.frame("id" = shp$bor_subb, centroids)
    
    # Join centroids with dataframe 
    
    shp.df.evic <- plyr::join(shp.df.evic, centroids, by = "id")
  
    
    # Minority Map  
    ggplot(shp.df.evic) + 
      aes(long,lat,group=group) +
      geom_polygon(aes(fill=N0)) + 
      scale_fill_continuous(low = '#E0EEEE', high = '#0000FF')+
      labs(fill='Level of Evicted/Displaced') + 
      geom_point(aes(x=long_cen,y=lat_cen,col = Minority), alpha = 0.9)+
      scale_color_continuous(low = '#FFFFFF', high = '#CD0000')+
      geom_path(color="white") + 
      theme_bw() +
      ggtitle("Where do Evicted/Displaced Minorities Reside?")
    
    
    # White Map 
    ggplot(shp.df.evic) + 
      aes(long,lat,group=group) +
      geom_polygon(aes(fill=N0)) + 
      scale_fill_continuous(low = '#E0EEEE', high = '#0000FF')+
      labs(fill='Level of Evicted/Displaced') + 
      geom_point(aes(x=long_cen,y=lat_cen,col = White), alpha = 0.9)+
      scale_color_continuous(low = '#FFFFFF', high = '#CD0000')+
      geom_path(color="white") + 
      theme_bw() +
      ggtitle("Where do Evicted/Displaced White People Reside?")
    
  
#### WANTED GREATER HOUSING AFFORDABILITY 
    
# Let's make the white vs/ minority affordability estimates (tables + maps)
    
    # How many people moved for greater affordability 
    sum(housing.afford$hhweight)/100000  #36,101.14 moved for greater housing affordability
    rep.wts.SE(housing.afford) # the SE is 3027.933
    
    # How many people moved for greater housing affordability that are a minority (Full Sample Estimate)
    ha.minority <- moved %>%
      filter(X_6 == "Wanted greater housing affordability" & RaceSimplified == 'Minority')
    
    sum(ha.minority$hhweight)/100000  #22550.74 minorities moved for greater housing affordability
    rep.wts.SE(ha.minority) # the SE is 2681.442! 
    
    # How many people moved for greater housing affordability that are white (Full Sample Estimate)
    ha.white <-  moved %>%
      filter(X_6 == "Wanted greater housing affordability" & RaceSimplified == 'White')
    
    sum(ha.white$hhweight)/100000  #13550.4 whites moved for greater housing affordability
    rep.wts.SE(ha.white) # the SE is 1842.22!  

# where do whites v. minorities move when they seek greater housing affordability... 
    moved %>%
      select(sba.name,borough,X_6, RaceSimplified, hhweight) %>%
      filter(X_6 == "Wanted greater housing affordability") %>%
      group_by(sba.name, RaceSimplified) %>%
      summarise(n=n(),amt=ceiling((sum(hhweight)/100000))) %>%
      arrange(desc(amt)) %>%
      ggplot(aes(x=sba.name, y = n, fill = RaceSimplified)) +
      geom_bar(stat = 'identity', position = 'dodge') +
      facet_grid(~RaceSimplified) +
      coord_flip() +
      ggtitle("Where do People Move for Greater Housing Affordability?")
    
    
    # create a table for this with Full Sample estimate, Var, and SE 
    EstbyNeighborhood.haRace <- rep.wts.2grps.SE(housing.afford, sba.name, RaceSimplified)
    # kable(EstbyNeighborhood.haRace, format = 'html', col.names = c('SBA',"Status",'Sample Estimate', 'Var', 'SE'))
    
# making maps 
    
    # let's map this 
    
    #before I join with shpfile I need to make this wide and where only interested in Full Sample estimate so that is what I'll keep
    EstbyNeighborhood.haRaceWide <- spread(EstbyNeighborhood.haRace[1:3], RaceSimplified, N0)
    
    EstbyNeighborhood.haRaceWide <- EstbyNeighborhood.haRaceWide %>% mutate_at(vars(Minority, White),
                                                                               function(x) as.numeric(as.character(x)))
    
    
    EstbyNeighborhood.haRaceWide$Minority[is.na(EstbyNeighborhood.haRaceWide$Minority)] <- 0
    EstbyNeighborhood.haRaceWide$White[is.na(EstbyNeighborhood.haRaceWide$White)] <- 0
    
    # add in neighborhoods not in EstbyNeighborhood.edRaceWide
    SBAnohaRaceWide <- SBA[!SBA %in% EstbyNeighborhood.haRaceWide$sba.name]
    SBAnohaRaceWide <- data.frame(sba.name = SBAnohaRaceWide, Minority = 0, White = 0)
    
    # adds those neighborhoods, where evicted/displaced people were not residing 
    EstbyNeighborhood.haRaceWide<- rbind(EstbyNeighborhood.haRaceWide, SBAnohaRaceWide) 
    names(EstbyNeighborhood.haRaceWide)[1] <- "NAME"
    
    # join to shapefile with (N0 estimate for all evicted/displaced already -- shp.df.evic)
    shp.df.ha <-join(shp.df.ha, EstbyNeighborhood.haRaceWide, by = "NAME")
    
    # join centroids 
    shp.df.ha <- plyr::join(shp.df.ha, centroids, by = "id")
    

# Maps 
  
    # Minority Map  
    ggplot(shp.df.ha) + 
      aes(long,lat,group=group) +
      geom_polygon(aes(fill=N0)) + 
      scale_fill_continuous(low = '#E0EEEE', high = '#0000FF')+
      labs(fill='Level of Housing Affordability') + 
      geom_point(aes(x=long_cen,y=lat_cen,col = Minority), alpha = 0.9)+
      scale_color_continuous(low = '#FFFFFF', high = '#CD0000')+
      geom_path(color="white") + 
      theme_bw() +
      ggtitle("Where do Minorities seeking Housing Affordability Reside?")
    
    
    # White Map 
    ggplot(shp.df.ha) + 
      aes(long,lat,group=group) +
      geom_polygon(aes(fill=N0)) + 
      scale_fill_continuous(low = '#E0EEEE', high = '#0000FF')+
      labs(fill='Level of Evicted/Displaced') + 
      geom_point(aes(x=long_cen,y=lat_cen,col = White), alpha = 0.9)+
      scale_color_continuous(low = '#FFFFFF', high = '#CD0000')+
      geom_path(color="white") + 
      theme_bw() +
      ggtitle("Where do White People seeking Housing Affordability Reside?")
    
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    
######### Go another Level Deeper and Expand on this Analysis Adding Income  #####   



    
      

    
    
    