##### Scrape 2018 NYC Landlord Watchlist #####

library(rvest)
library(XML)
library(tidyverse)
library(stringr)

## LANDLORD BASE TABLE

## base website 
url <- "https://landlordwatchlist.com/landlords"

## get landlord names 
ll <- NA

ll <- url %>%
  read_html()%>%
  html_nodes(xpath = "//div[@class='col-lg-12']/h2") %>%
  html_text()

ll <- ll %>%
  str_remove_all("^\\d+.") %>%
  trimws()

## each landlord on the page, has a box with six pieces of info we can use this to build a base dataset
## that gives us info about each landlord 

headers <- url %>%
  read_html()%>%
  html_nodes(xpath = "//div[@class='col-md-12']/h4/text()")%>%
  html_text()

  #clean headers so that they can be used as dataframe columns
  headers <-headers %>%
            str_remove_all(":")%>%
            trimws()%>%
            unique(headers)

rows <- url %>%
  read_html()%>%
  html_nodes(xpath = "//div[@class='col-md-12']/h4/d") %>%
  html_text()

  #make rows into a matrix to make dataframe rows
  rows <- matrix(rows, ncol=6, byrow = T)
  rows <- data.frame(rows)

## make one dataframe
colnames(rows) <- headers
ll_df <- rows

## add landlords to df 
ll_df$landlord <- ll

## BUILDING TABLES DETAILS 

## strip off numbers and add 20% bc this will allow us to build custom URLs for each landlord
ll2 <- ll %>%
      str_replace_all("\\s", "%20")

## create URL for each landlord 
base <- "https://landlordwatchlist.com/landlord-"
urls <- paste(base,ll2,sep="")

## scrape tables for each person 
source("code/clean_functions.R")
buildings <- build_df(urls)



