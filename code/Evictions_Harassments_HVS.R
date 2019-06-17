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

# read in shapefile 
shp <- rgdal::readOGR(dsn = "data/NYC_HVS/NYC_Sub_borough_Area")
shp@data$id = shp@data$bor_subb

# bring in 2017 Marshal Evictions from db on git 
evic <- read.csv("data/data_created/MarshalEvictionsHDB.csv")

# bring in harassment cases 
harass <- read.csv("data/data_created/harass_pluto.csv")

# bring in landlord watchlist
ll <- read.csv("data/data_created/watchlistwBBL.csv")

# bring in the shapefile dfs 
shp.df <- read.csv("data/data_created/SBA.Shapedf.csv")
shp.df.evic <- read.csv("data/data_created/SBA.EvictionsStats.csv")
shp.df.ha <- read.csv("data/data_created/SBA.HAStats.csv")


# Plot evictions on the evictions shapefile (Are evictions happening where people are moving to after being
                                            #evicted/displaced)? 

  # transform long/lat to right CRS
  evic.long.lat <- data.frame(long = evic$lng, lat = evic$lat)
  evic.long.lat <- evic.long.lat[complete.cases(evic.long.lat),]
  
  coordinates(evic.long.lat) <- c("long", "lat")
  proj4string(evic.long.lat) <- CRS("+init=epsg:4326") # WGS 84
  CRS.new <- CRS("+proj=lcc +lat_1=40.66666666666666 +lat_2=41.03333333333333 +lat_0=40.16666666666666 +lon_0=-74 +x_0=300000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs +ellps=GRS80 +towgs84=0,0,0")
  evic.long.lat <- spTransform(evic.long.lat, CRS.new)
  
  #coords
  evic.long.lat  <- data.frame(evic.long.lat@coords)
  
ggplot(shp.df.evic) + 
  aes(long,lat,group=group) +
  geom_polygon(aes(fill=N0)) + 
  scale_fill_continuous(low = '#E0EEEE', high = '#0000FF')+
  labs(fill='Level of Evicted/Displaced')+ 
  geom_point(data = evic.long.lat, aes(x=long, y =lat), alpha=0.15, inherit.aes=FALSE) +
  geom_path(color="white") + 
  theme_bw() +
  ggtitle("2017 Scheduled Marshal Evictions on Where the Evicted Move")
  
  
# Plot landlord watchlist buildings on evictions shapefile (Are these buildings located where people are moving to
                                                            # after being evicted/displaced)? 

ll$geometry <- as.character(ll$geometry)
ll$geometry <- str_remove_all(pattern = "\\(", string = ll$geometry)
ll$geometry <- str_remove_all(pattern = "c", string = ll$geometry)
ll$geometry <- str_remove_all(pattern = "\\)", string = ll$geometry)

llpoints <- data.frame(points=ll$geometry)

llpoints <- llpoints %>%
              separate(col = points, into = c("long", "lat"), sep = ",", remove = T)

llpoints <- mutate_all(llpoints, as.numeric)             

coordinates(llpoints) <- c("long", "lat")
proj4string(llpoints) <- CRS("+init=epsg:4326") # WGS 84
CRS.new <- CRS("+proj=lcc +lat_1=40.66666666666666 +lat_2=41.03333333333333 +lat_0=40.16666666666666 +lon_0=-74 +x_0=300000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs +ellps=GRS80 +towgs84=0,0,0")
llpoints <- spTransform(llpoints, CRS.new)

#coords
llpoints  <- data.frame(llpoints@coords)

ggplot(shp.df.evic) + 
  aes(long,lat,group=group) +
  geom_polygon(aes(fill=N0)) + 
  scale_fill_continuous(low = '#E0EEEE', high = '#0000FF')+
  labs(fill='Level of Evicted/Displaced')+ 
  geom_point(data = llpoints, aes(x=long, y =lat), alpha=0.2, inherit.aes=FALSE) +
  geom_path(color="white") + 
  theme_bw() +
  ggtitle("Landlord Watchlist Buildings on Where the Evicted Move")


# Plot landlord tenant harassment cases on evictions shapefile (Are the landlord tenant harassment cases occuring
                                                              # in neighborhoods people move to after evicted/displaced)?

harasspts <- harass %>% select(findingofharassment, xcoord, ycoord) #the x,y came in right format already!
harasspts <- harasspts[complete.cases(harasspts),]
harasspts <- harasspts %>%
                mutate(harassrecode = case_when(
                  findingofharassment %in% c("After Trial", "After Inquest") ~ 1,
                  findingofharassment == 'No Harassment' ~ 0
                ))

ggplot(shp.df.evic) + 
  aes(long,lat,group=group) +
  geom_polygon(aes(fill=N0)) + 
  scale_fill_continuous(low = '#E0EEEE', high = '#0000FF')+
  labs(fill='Level of Evicted/Displaced')+ 
  geom_point(data = harasspts, aes(x=xcoord, y=ycoord, col = factor(harassrecode)), alpha=0.4, inherit.aes=FALSE) +
  geom_path(color="white") + 
  theme_bw() +
  ggtitle("Harassment Cases on Where the Evicted Move")


