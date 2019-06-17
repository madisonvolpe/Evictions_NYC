library(haven)
library(plyr)
library(tidyverse)

ind <- haven::read_dta(file = "data/NYC_HVS/personlevel/persondata.dta")
ind <- as.data.frame(ind)

# The original dataset came with Household Info, I want to get extra information about the householder that responded 
# and combine with that dataset (kind of making a nested dataset)

# check that these are individual records
unique(ind$recid) 

# filter for householder (the respondent's)
hh <- filter(ind, uf92 == 1)

# hispanic
hh$hspanic <- factor(hh$hspanic) 
levels(hh$hspanic) <- list(No = c("1"), Yes = c("2", "3", "4", "5", "6", "7"))

# race
hh$uf62 <- factor(hh$uf62)

levels(hh$uf62) <- list(White = c("1"), Black = c("2"), Native = c("3"),
                        Asian = c("4", "5", "6", "7", "8"), PI = c("9"), MultiRace = c("10"))
colnames(hh)[colnames(hh)=='uf62'] <- "HH.Race"

# currently working 
hh$item40a <- factor(hh$item40a)
levels(hh$item40a) <- list(Yes = c("1"), No =c("2"))
colnames(hh)[colnames(hh)=='item40a'] <- "HH.Worked.Last.Week"

# hours worked 
hh$uf95 <- as.numeric(as.character(hh$uf95))
colnames(hh)[colnames(hh)=='uf95'] <- "HH.Hours.Worked.Last.Week"

# vacation / laid off / last weel 
hh$item41 <- factor(hh$item41)
levels(hh$item41) <- list(Laidoff = c("1"), Temporary = c("2"), No = c("3"), WorkedLastWeek = c("9"))
colnames(hh)[colnames(hh)=='item41'] <- "HH.Laidoff.Vacation.Last.Week"

# looking for work 
hh$item42 <- factor(hh$item42)
levels(hh$item42) <- list(Yes = c("1"), No = c("2"), WorkedLastWeek = c("9"))
colnames(hh)[colnames(hh)=='item42'] <- "HH.Looking.Work"

# Last time worked 
hh$item44 <- factor(hh$item44)
levels(hh$item44) <- list(Y2017=c("1"), Y2016 =c("2"), Y2012to2015 = c("3"),
                          B2011=c("4"), NeverWorked = c("5"), CurrentlyWorking = c("9"))

colnames(hh)[colnames(hh)=='item44'] <- "HH.Last.Time.Worked"

# Industry Type
hh$item45c <- factor(hh$item45c)
levels(hh$item45c) <- list(Manufacturing = c("1"), WholsaleTrade = c("2"), RetailTrade = c("3"),
                           Other = c("4"), NotApplicable = c("9"))
colnames(hh)[colnames(hh)=='item45c'] <- "HH.Industry"

# Worker Type
hh$uf90 <- factor(hh$uf90)
levels(hh$uf90) <-list(PrivateProfit = c("1"), PrivateNonProfit = c("2"),
                       FederalGovernment = c("3"), StateGovernment = c("4"),
                       SelfEmployed = c("5"), NotApplicable = c("9"))
colnames(hh)[colnames(hh)=='uf90'] <- "HH.Worker.Type"

# Weeks Worked in 2016 
hh$item48a <- factor(hh$item48a)
colnames(hh)[colnames(hh)=='item48a'] <- "HH.Weeks.Worked"

# Currently in School 
hh$item50a <- factor(hh$item50a)
levels(hh$item50a) <- list(GED = c("1"), HS = c("2"), College = c("3"),
                           Grad = c("4"), Vocational = c("5"),
                           ESL = c("6"), NotEnrolled = c("7"), 
                           NotReported = c("8"),
                           NotApplicable = c("15"))
colnames(hh)[colnames(hh)=='item50a'] <- "HH.Enrolled.School"

# Educational Attainment 
hh$eductn <- factor(hh$eductn)
levels(hh$eductn) <- list(None = c("1"), Sixth = c("2"),
                          SeventhEighth = c("3"),
                          HSnoDiploma = c("4"),
                          HS =c("5"),
                          SomeCollege = c("6"),
                          Associate = c("7"),
                          College = c("8"),
                          SomeGrad = c("9"),
                          Graduate = c("10"))
colnames(hh)[colnames(hh)=='eductn'] <- "HH.Education"

# Person Income
hh$uf41 <- as.numeric(as.character(hh$uf41))
colnames(hh)[colnames(hh)=='uf41'] <- "TotalPersonIncome"

write.csv(hh, "personlevelNYCHVS.csv")

