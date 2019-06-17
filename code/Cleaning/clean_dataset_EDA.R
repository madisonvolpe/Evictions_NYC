suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(tidyverse))

## Read in data 

## read in complete 2017 NYC HVS dataset 
hvs <- read.csv("data/NYC_HVS/NYC_HVS_2017_HO.csv")

#The more detailed variable names are the first row - extract them out 
varnames <- hvs[1,]

#remove more detailed names 
hvs_clean <- hvs[-1,]

## Add sub borough area names to dataset 

# get name for subborough areas

# read in shapefile 
shp <- rgdal::readOGR(dsn = "/Users/madisonvolpe/Desktop/NYC_Sub_borough_Area")
shp@data$id = shp@data$bor_subb

# transform shape for ggplot2
shp.points = fortify(shp, region="id")
shp.df = plyr::join(shp.points, shp@data, by="id")
rm(shp.points)
names(shp.df)[8] <- "sba"

# add sub-borough name from shpfile data to dataset it will make analysis easier!
hvs_clean$sba <- as.numeric(as.character(hvs_clean$sba))
hvs_clean$sba.name <- shp.df$NAME[match(hvs_clean$sba, shp.df$sba)]
sum(is.na(hvs_clean$sba.name)) #check none missing 

rm(shp, shp.df)

## Subset data for only those households that marked a reason for recently moving 

hvs_clean$X_6 <- factor(hvs_clean$X_6, levels =   c("1","2","3","4","5","6","7","8",
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


## Create Outcome Variable - Note to self, the 2014 NYC HVS had better options for the hvs_clean ques (maybe go back to it)

hvs_clean <- hvs_clean %>%
  mutate(Evicted.Displaced = ifelse(hvs_clean$X_6 == "Evicted, displaced, landlord harassment", 1, 0))

hvs_clean$Evicted.Displaced <- factor(hvs_clean$Evicted.Displaced, levels = c(0,1), labels = c("No", "Yes"))

## Clean Demographic/Income Variables 

## HH sex (1b)
## HH age (1c)
## HH hispanic origin (1e)
## HH race (1f)
## Place of HH birth (7a)
## Receipt of Welfare/ Public Assistance (51)
## Any postponement of healthcare in the past 12 months (53b)
## Dental - 53b1
## Check up - 53b2 
## Mental Helth - 53b3
## treatment/diagnosis -53b4
## prescription/drugs - 53b5
## General Health of Respondent - (54a) 
## Any postponement in service (55)
## utility - 55a
## ll tele - 55b
## cell phone - 55c 
## cable - 55d
## other - 55e 
## Household composition recode (hcr)
## Total household income recode (hhinc)
## Household member under 18 - children (under18)

## sex
hvs_clean <- hvs_clean %>%
  mutate(X_1b = factor(X_1b, levels = c(1,2), labels = c("Male", "Female")))

colnames(hvs_clean)[colnames(hvs_clean)=="X_1b"] <- "Sex"

## age 
hvs_clean$X_1c  <- as.numeric(as.character(hvs_clean$X_1c))
hvs_clean$AgeCat <- NA 

for(i in 1:nrow(hvs_clean)){
  if(hvs_clean$X_1c[i] < 25){
    hvs_clean$AgeCat[i] <- '<25'
  } else if (hvs_clean$X_1c[i] == 25 | hvs_clean$X_1c[i] < 35){
    hvs_clean$AgeCat[i] <- '25-34'
  } else if (hvs_clean$X_1c[i] == 35 | hvs_clean$X_1c[i] < 45){
    hvs_clean$AgeCat[i] <- '35-44'
  } else if (hvs_clean$X_1c[i] == 45 | hvs_clean$X_1c[i] < 55){
    hvs_clean$AgeCat[i] <- '45-54'
  } else if (hvs_clean$X_1c[i] == 55 | hvs_clean$X_1c[i] < 65){
    hvs_clean$AgeCat[i] <- '55-64'
  } else {
    hvs_clean$AgeCat[i] <- '65+'
  }
}

colnames(hvs_clean)[colnames(hvs_clean)=="X_1c"] <- "Age"

## hispanic origin
levels(hvs_clean$X_1e) <- list(No=c("1"), Yes=c("2", "3", "4", "5", "6", "7"))
colnames(hvs_clean)[colnames(hvs_clean)=='X_1e'] <- 'Hispanic'

## HH race 
levels(hvs_clean$X_1f)  <- list(White = c("1"), Black = c("2"), Native = c("3"),
                            Asian = c("4", "5", "6", "7", "8"), PI = c("9"), MultiRace = c("10"))
colnames(hvs_clean)[colnames(hvs_clean)=='X_1f'] <- "Race"

## combine hispanic origin + race 
hvs_clean <- hvs_clean %>%
  mutate(Race.Ethnicity = case_when(
    hvs_clean$Hispanic == "No" & hvs_clean$Race == 'White' ~ 'White',
    hvs_clean$Hispanic == "No" & hvs_clean$Race == 'Black' ~ 'Black',
    hvs_clean$Hispanic == "No" & hvs_clean$Race == 'Native' ~ 'Native',
    hvs_clean$Hispanic == "No" & hvs_clean$Race == 'Asian' ~ 'Asian',
    hvs_clean$Hispanic == "No" & hvs_clean$Race == 'PI' ~ 'PI',
    hvs_clean$Hispanic == "No" & hvs_clean$Race == 'MultiRace' ~ 'MultiRace',
    hvs_clean$Hispanic== "Yes"& hvs_clean$Race %in% c("White", "Black", "Native", "Asian", "PI", "MultiRace") ~ 'Hispanic',
  ))

## place of HH birth 
levels(hvs_clean$X_7a) <- list(US = c('7', '9'), PR = c("10"), NotReported = c("98"), 
                           OutsideUS = c("11", "12", "13", "14", "15", "16",
                                         "17", "18", "19", "20", "21", "22",
                                         "23", "24", "25", "26"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_7a"] <- "Place.Birth"

## welfare 
levels(hvs_clean$X_51) <- list(Yes = c("1"), No = c("2"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_51"] <- "Welfare"

## health of respondment 
levels(hvs_clean$X_54a)  <- list(Excellent = c("1"), VG = c("2"), Good = c("3"), Fair = c("4"),
                             Poor = c("5"), DK = c("6"), NotReported = c("8"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_54a"] <- "Health"

## Any postponement of healthcare in the past 12 months (54c)
levels(hvs_clean$X_53b1) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_53b2) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_53b3) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_53b4) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_53b5) <- list(Yes = c("1"), No = c("2"), NR = c("8"))

hvs_clean <- hvs_clean %>%
  mutate(Postpone.Health = ifelse(hvs_clean$X_53b1 == 'Yes'| hvs_clean$X_53b2 == 'Yes' |
                                    hvs_clean$X_53b3 == 'Yes'| hvs_clean$X_53b4 == 'Yes' |
                                    hvs_clean$X_53b5 == 'Yes', 'Yes', 'No')) 
## service (55)
levels(hvs_clean$X_55a) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_55b) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_55c) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_55d) <- list(Yes = c("1"), No = c("2"), NR = c("8"))
levels(hvs_clean$X_55e) <- list(Yes = c("1"), No = c("2"), NR = c("8"))

hvs_clean <- hvs_clean %>%
  mutate(Service.Interruptions = ifelse(hvs_clean$X_55a == 'Yes'| hvs_clean$X_55b == 'Yes' |
                                          hvs_clean$X_55c == 'Yes'| hvs_clean$X_55d == 'Yes' |
                                          hvs_clean$X_55e == 'Yes', 'Yes', 'No'))

## Household composition recode (hcr)
levels(hvs_clean$hcr) <- list(SolelyMarried = c("1"), Marriedw.KidsOnly = c("2"), Marriedw.AdultsOnly = c("3"),
                          Marriedw.AdultsKids = c("4"), SoleFemale = c("6"), Femalew.Kids = c("7"), 
                          Femalew.Adults = c("8"), Femalew.AdultsKids = c("9"),SoleMale = c("11"),
                          Malew.Kids = c("12"), Malew.Adults = c("13"), Malew.AdultsKids = c("14"))

colnames(hvs_clean)[colnames(hvs_clean)=="hcr"] <- "Household.Composition"

## Total household income recode (hhinc)
hvs_clean$hhinc  <- as.numeric(as.character(hvs_clean$hhinc))

hvs_clean <- hvs_clean %>%
  mutate(Income.Cat = case_when(
    hhinc == 9999999 ~ "No Income",
    hhinc < 0 | hhinc == 0 ~ "No Income",
    hhinc > 0 | hhinc < 10000 ~ "less than 10,000",
    hhinc == 10000 | hhinc < 25000 ~ "10,000 - 24,999",
    hhinc == 25000 | hhinc > 40000 ~ "25,000 - 39,999", 
    hhinc == 40000 | hhinc < 55000 ~ "40,000 - 54,999",
    hhinc == 55000 | hhinc < 70000 ~ "55,000 - 69,999", 
    hhinc == 70000 | hhinc < 85000 ~ "70,000 - 84,999",
    hhinc == 85000 | hhinc < 100000 ~ "85,000 - 99,999",
    hhinc == 100000 | hhinc < 150000 ~ "100,000 - 149,999",
    hhinc == 150000 | hhinc < 200000 ~ "150,000 - 199,999",
    hhinc == 200000 | hhinc > 200000 ~ "200,000 +"
  ))


## Household member under 18 - children (under18)
levels(hvs_clean$under18) <- list(No = c("1"), Yes = c("2", "3", "4", "5", "6"))


## Clean Housing Type 

# Condo 
levels(hvs_clean$X_8) <- list(No = c("1"), Condo = c("2"), Coop = c("3"), DK = c("4"))
colnames(hvs_clean)[colnames(hvs_clean)=="X_8"] <- "Condo.Coop"

# Owner/Renter
levels(hvs_clean$X_9a) <- list(Owner = c("1"), Renter = c("9"))
colnames(hvs_clean)[colnames(hvs_clean)=="X_9a"] <- "Owner.Renter1"

# Rent Type
levels(hvs_clean$X_9c) <- list(PayCash = c("2"), RentFree = c("3"), Owner = c("9"))
colnames(hvs_clean)[colnames(hvs_clean)=="X_9c"] <- "Pay.Rent"

# Number of units 
levels(hvs_clean$X_20) <- list(OneNoBusiness = c("1"), OneWithBusiness = c("2"),
                           TwoNoBusiness = c("3"), TwoWithBusiness = c("4"),
                           Three = c("5"), Four = c("6"), Five = c("7"), 
                           SixtoNine = c("8"), TentoTwelve = c("9"), ThirteentoNineteen = c("10"), 
                           TwentytoFortyNine = c("11"),
                           FiftytoNinetyNine = c("12"), OneHundredPlus = c("13"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_20"] <- "No.Units"

# Number of stories 
levels(hvs_clean$X_22a) <- list(OnetoTwo = c("1"), Three = c("2"), Four = c("3"),
                            Five = c("4"), SixtoTen = c("5"), EleventoTwenty = c("6"),
                            TwentyonePlus = c("7"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_22a"] <- "No.Stories"

# Number of rooms (X_24a)
levels(hvs_clean$X_24a) <- list(One = c("1"), Two = c("2"), Three = c("3"),
                            Four = c("4"), Five = c("5"), Six = c("6"),
                            Seven = c("7"), EightPlus = c("8"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_24a"] <- "No.Rooms"

# Number of bedrooms (X_24b)
levels(hvs_clean$X_24b) <- list(None = c("1"), One = c("2"), Two = c("3"),
                            Three = c("4"), Four = c("5"), Five = c("6"), 
                            SixPlus = c("7"))
colnames(hvs_clean)[colnames(hvs_clean)== "X_24b"] <- "No.Bedrooms"

# Section8 ? (_31a1)
levels(hvs_clean$X_31a1) <- list(Yes = c("1"), No = c("2"), DK = c("3"),
                             NotReported = c("8"), NotApplicable = c("9"))

colnames(hvs_clean)[colnames(hvs_clean)== "X_31a1"] <- "Section8"

# Rental Subsidy (_31a12)
levels(hvs_clean$X_31a12) <- list(Yes = c("1"), No = c("2"), NotApplicable = c("3"))
colnames(hvs_clean)[colnames(hvs_clean)== "X_31a12"] <- "Rental.Subsidy"

# Control Staus Recode
levels(hvs_clean$csrr) <- list(OwnerOccupiedConventional = c("1"),
                           OwnerOccupiedPrivateCoop = c("2"),
                           PublicHousing = c("5"),
                           OwnerOccupiedCondo = c("12"),
                           HUD = c("21"),
                           StabilizedPre1947 = c("30"),
                           StabilizedPost1947 = c("31"),
                           OtherRental = c("80"),
                           MitchellLamaRentalArticle4 = c("85"),
                           MitchellLamaCoop = c("86"),
                           Controlled = c("90"),
                           InRem = c("95"))

colnames(hvs_clean)[colnames(hvs_clean)== "csrr"] <- "Contrl.Status.Recode"

# Strcuture Class Recode 
levels(hvs_clean$scr) <- list(OldLawTenement = c("1"), NewLawTenement = c("2"),
                          Multipleafter1929 = c("3"), ApartmentHotel = c('4'),
                          OneTwoFamilyConvertedApartments = c("5"),
                          CommercialAlteredApartments = c("6"),
                          SingleRoomOccupancy = c("7"),
                          MiscClassB = c("8"),
                          NotReported = c("9"),
                          NotFound = c("10"),
                          NoData = c("11"),
                          OneTwoFamilyHome = c("12"))

colnames(hvs_clean)[colnames(hvs_clean)== "scr"] <- "Structure.Type"

# Schedule Type 
levels(hvs_clean$tsc) <- list(Owner = c("1", "2", "3"), Renter = c("12", "13", "15", "16"))
colnames(hvs_clean)[colnames(hvs_clean)== "tsc"] <- "Owner.Renter"

# Year Built 
levels(hvs_clean$ybr) <- list(Y2000orLater = c("1"), Y1990to1999 = c("2"),
                          Y1980to1989 = c("3"), Y1974to1979 = c("4"),
                          Y1960to1973 = c("5"), Y1947to1959 = c("6"),
                          Y1930to1946 = c("7"), Y1920to1929 = c("8"),
                          Y1901to1919 = c("9"), B1900 = c("10"))

colnames(hvs_clean)[colnames(hvs_clean)== "ybr"] <- "Year.Built"

# Number of persons 
colnames(hvs_clean)[colnames(hvs_clean)== "npr"] <- "Number.Persons.Household"

## Clean Rent + Costs

## Electricity (X_28a1)
levels(hvs_clean$X_28a1) <- list(Yes = c("1"), YeswGas = c("2"), 
                             NowRent = c("3"))

colnames(hvs_clean)[colnames(hvs_clean)== "X_28a1"] <- "Electricity.Separate"

## Electricity Monthly Cost  (X_28a2)
hvs_clean$X_28a2 <- as.numeric(as.character(hvs_clean$X_28a2))

hvs_clean$Electricity.Monthly.Cost <- NA

hvs_clean <- hvs_clean %>%
  mutate(Electricity.Monthly.Cost = case_when(
    X_28a2 < 50 ~ "<50",
    X_28a2 == 50 | X_28a2 < 100 ~ "50-99",
    X_28a2 == 100 | X_28a2 < 150 ~ "100-149",
    X_28a2 == 150 | X_28a2 < 200 ~ "150-199",
    X_28a2 == 200 | X_28a2 < 281 ~ "200-280",
    X_28a2 == 0408 ~ "Greater than topcode (280)",
    X_28a2 == 9999 ~ "NotApplicable"
  ))

## Gas  (X_28b1)
levels(hvs_clean$X_28b1) <- list(Yes = c("1"), NowRent = c("2"),
                             NonotUsed = c("3"), YeswElectric = c("9"))

colnames(hvs_clean)[colnames(hvs_clean)== "X_28b1"] <- "Gas.Separate"

## Gas Monthly Cost
hvs_clean$X_28b2 <- as.numeric(as.character(hvs_clean$X_28b2))
hvs_clean$Gas.Monthly.Cost <- NA

hvs_clean <- hvs_clean %>%
  mutate(Gas.Monthly.Cost = case_when(
    X_28b2 < 50 ~ "<50",
    X_28b2 == 50 | X_28b2 < 100 ~ "50-99",
    X_28b2 == 100 | X_28b2 < 150 ~ "100-149",
    X_28b2 == 150 | X_28b2 < 200 ~ "150-199",
    X_28b2 == 200 | X_28b2 < 241 ~ "200-240",
    X_28b2 == 0344 ~ "Greater than topcode (240)",
    X_28b2 == 9999 ~ "NotApplicable"
  ))


## Combined Gas + Electricity Monthly Cost
hvs_clean$X_28c <- as.numeric(as.character(hvs_clean$X_28c))

hvs_clean <- hvs_clean %>%
  mutate(Electric.Gas.Combined = case_when(
    X_28c < 50 ~ "<50",
    X_28c == 50 | X_28c < 100 ~ "50-99",
    X_28c == 100 | X_28c < 150 ~ "100-149",
    X_28c == 150 | X_28c < 200 ~ "150-199",
    X_28c == 200 | X_28c < 250 ~ "200-249",
    X_28c == 250 | X_28c < 300 ~ "250-299",
    X_28c == 0362 ~ "Greater than topcode (299)",
    X_28c == 9999 ~ "NotApplicable"
  ))


## Water + Sewer (_28d1)
levels(hvs_clean$X_28d1) <- list(Yes = c("1"), NowRent = c("2"))
colnames(hvs_clean)[colnames(hvs_clean)== "X_28d1"] <- "Water.Sewer.Separate"

## Water + Sewer Annual Cost (_28d2)
hvs_clean$X_28d2 <- as.numeric(as.character(hvs_clean$X_28d2)) #not going to do this 

## MONTHLY CONTRACT RENT (_30a)
hvs_clean$X_30a <- as.numeric(as.character(hvs_clean$X_30a))
colnames(hvs_clean)[colnames(hvs_clean)== "X_30a"] <- "Monthly.Contract.Rent"

## Length of Lease (_29)
levels(hvs_clean$X_29) <- list(LessthanYear = c("1"), OneYear = c("2"),
                           MorethanOneLessthanTwo = c("3"), TwoYears = c("4"),
                           MorethanTwoYears = c("5"), NoLease = c("6"), 
                           DK = c("7"), NotReported = c("8"), NotApplicable = c("9"))

colnames(hvs_clean)[colnames(hvs_clean)== "X_29"] <- "Length.Lease"

# Out of Pocket Rent (_31b)
hvs_clean$X_31b <- as.numeric(as.character(hvs_clean$X_31b))
colnames(hvs_clean)[colnames(hvs_clean)== "X_31b"] <- "Out.Pocket.Rent"

# Monthly Gross Rent 
hvs_clean$mgrent <- as.numeric(as.character(hvs_clean$mgrent))
colnames(hvs_clean)[colnames(hvs_clean)== "mgrent"] <- "Monthly.Gross.Rent"

## Clean Housing Quality 

# Condition of the building (X_h)

# Complete Plumbing Facilities (X_25a)
levels(hvs_clean$X_25a) <- list(Yes = c("1"), No = c("2"))
colnames(hvs_clean)[colnames(hvs_clean)== "X_25a"] <- "Complete.Plumbing"

# Toilet Breakdowns (X_25c)
levels(hvs_clean$X_25c) <- list(Yes = c("1"), No = c("2"),
                            NotRepoted = c("8"), NotApplicable = c("9"))

colnames(hvs_clean)[colnames(hvs_clean)== "X_25c"] <- "Toilet.Breakdowns"

# Complete Kitchen Facilities (X_26a)
levels(hvs_clean$X_26a) <- list(Yes = c("1"), No = c("2"))
colnames(hvs_clean)[colnames(hvs_clean)== "X_26a"] <- "Kitchen.Facilities"

# Kitchen Facilities Functioning (X_26c)
levels(hvs_clean$X_26c) <- list(Yes = c("1"), No = c("2"), NotReported = c("8"),
                            NotApplicable = c("9"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_26c"] <- "Kitchen.Functioning"

# Heating Equipment Breakdown  (X_32a)
levels(hvs_clean$X_32a) <- list(Yes = c("0"), No = c("1"), NotReported = c("8"))
colnames(hvs_clean)[colnames(hvs_clean)=="X_32a"] <- "Heating.Breakdown"

# Number Heating Breakdown (X_32b)
levels(hvs_clean$X_32b) <- list(One = c("2"), Two = c("3"), Three = c("4"), 
                            FourPlus = c("5"), NotReported = c("8"),
                            None = c("9"))
colnames(hvs_clean)[colnames(hvs_clean)=="X_32b"] <- "No.Heating.Breakdown"

# Air Conditioning (X_34)
levels(hvs_clean$X_34) <- list(YesCentral = c("1"), YesWall = c("2"),
                           No = c("3"), DK = c("4"),
                           NotReported = c("4"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_34"] <- "Air.Conditioning"

# Presence Mice + Rats
levels(hvs_clean$X_35a) <- list(Yes = c("1"), No = c("2"), NotReported = c("8"))
colnames(hvs_clean)[colnames(hvs_clean)=="X_35a"] <- "Mice.Rats"

# Presence Cockroaches 
levels(hvs_clean$X_35b) <- list(None = c("1"), OnetoFive = c("2"),
                            SixtoNineteen = c("3"), TwentyPlus = c("4"),
                            DK =c("5"), NotReported = c("8"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_35b"] <- "No.Cockroaches"

# Water Leakage 
levels(hvs_clean$X_38a) <- list(Yes = c("1"), No = c("2"), NotReported = c("8"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_38a"] <- "Water.Leakage"

## Clean Extra 

# Year Householder hvs_clean into this unit (X_4a)

# Rating of Neighborhood (X_39)

levels(hvs_clean$X_39) <- list(Excellent= c("1"), Good = c("2"), 
                           Fair = c("3"), Poor = c("4"),
                           NotReported = c("8"))


colnames(hvs_clean)[colnames(hvs_clean)=="X_39"] <- "Rating.Neighborhood"

#Affordability

levels(hvs_clean$X_56a) <- list(StronglyAgree = c("1"), Agree = c("2"),
                            NeitherAgreenorDisagree = c("3"),
                            Disagree = c("4"), 
                            StronglyDisagree = c("5"),
                            NotReported = c("8"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_56a"] <- "Housing.Affordable"

#Expensive given condition
levels(hvs_clean$X_56b) <- list(StronglyAgree = c("1"), Agree = c("2"),
                            NeitherAgreenorDisagree = c("3"),
                            Disagree = c("4"), 
                            StronglyDisagree = c("5"),
                            NotReported = c("8"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_56b"] <- "Housing.Expensive.Given.Condition"


#Expensive given location 
levels(hvs_clean$X_56c) <- list(StronglyAgree = c("1"), Agree = c("2"),
                            NeitherAgreenorDisagree = c("3"),
                            Disagree = c("4"), 
                            StronglyDisagree = c("5"),
                            NotReported = c("8"))

colnames(hvs_clean)[colnames(hvs_clean)=="X_56c"] <- "Housing.Expensive.Given.Location"


## write clean dataset
write_csv(hvs_clean, "data/data_final/HVS_HH_All_Cleaned.csv")