library(tidyverse)

hvs.moved <- read.csv("data/data_final/HVS_Moved_Cleaned.csv")
hvs.all <- read.csv("data/data_final/HVS_HH_All_Cleaned.csv")
ind <- read.csv("data/data_final/personlevelNYCHVS.csv")

#joins moved households to reference person 
hvs.moved.ind <- dplyr::left_join(hvs.moved, ind, by = c("seqn" = "seqno"))


#joins all households to reference person
hvs.all.ind <- dplyr::left_join(hvs.all, ind, by = c("seqn" = "seqno"))


# write to csvs 
write.csv(hvs.moved.ind,"data/data_final/HVS_Moved_HH_Ind.csv")
write.csv(hvs.all.ind,"data/data_final/HVS_All_HH_Ind.csv")

