library(RPostgreSQL)

pw <- "yourpassword"
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "nyc_housing", host = "localhost", port = 5432,
                 user = "madisonvolpe", password = pw)
rm(pw)

dbExistsTable(con, "marshal_evictions_17")
evictions17<- dbGetQuery(con, "SELECT * FROM marshal_evictions_17")

head(evictions17)

