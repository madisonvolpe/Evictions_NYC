## Scrape SBA from Furman ## 
library(plyr)
library(tidyverse)


#Through some inspection, I was able to see the URL to download the .xlsx 
# is of the type:
# http://furmancenter.org/files/soc2017/2017_Data_Profiles_DOWNLOADS/NAME[i]_NeighborhoodDataProfile.xlsx

# save base urls 
base  <- "http://furmancenter.org/files/soc2017/2017_Data_Profiles_DOWNLOADS/"
base2 <- "_NeighborhoodDataProfile.xlsx"

# create neighborhood vector
  
  #BK01 - BK18
  #BX01 - BX12
  #MN01 - MN12
  #QN01 - QN14
  #SI01 - SI03
  
  # create padded neighborhoods 

  pad_sba <- function(amts, nms){
    amts <- str_pad(string = amts, width = 2, side = "left", pad  = "0")
    final <- paste(nms, amts , sep = "")
    return(final)
  }
  
  
  boro.amt <- list(list("BK", 1:18), list("BX", 1:12), list("MN", 1:12) ,list("QN", 1:14), list("SI", 1:3))
  
  sba_list <- list()
  
  for(i in 1:length(boro.amt)){
    sba_list[[i]] <- pad_sba(boro.amt[[i]][[2]], boro.amt[[i]][[1]])
  }
  
# unlist to one vector of names 
  
sba <- unlist(sba_list)
  
# create urls for each sba 
sba.links <- paste(base, sba, base2, sep = "")

# for  loop to download files 

for(i in 1:length(sba.links)){
  download.file(sba.links[i], destfile = paste(getwd(),"/data/SBA_Profiles/", sba[i], ".xlsx", sep=""))
}


#### Part 2 ####

## Compile individual xlsxs into one dataset ## 
library(readxl)

# list files 
sba.files <- list.files("data/SBA_Profiles")
sba.files <- sba.files[sba.files != 'SBA.combined.csv']
sba.files <- paste("data/SBA_Profiles/", sba.files, sep = "")

# read in 2nd sheet from every excel sheet 
sba.list <- list()

for(i in 1:length(sba.files)){
sba.list[[i]] <- readxl::read_xlsx(path = sba.files[i], sheet = 2)
}

# create one df from lists
sba.df <- bind_rows(sba.list)

# data cleaning of df 
  
  names(sba.df)[6:14] <- c("Y2000", "Y2006", "Y2010", "Y2016", "Y2017", 
                           "Y2000.Rank", "Y2006.Rank", "Y2010.Rank",
                           "Y16.17.Rank")
  
# check that all cds are entered  
 length(unique(sba.df$`Community District`)) 

# write df to csv 
 write_csv(sba.df, path = "data/SBA_Profiles/SBA.combined.csv")
