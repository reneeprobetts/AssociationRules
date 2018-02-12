# Association Rules Analysis Dillards 
# Renee Probetts
# IEMS 308



# install the necessary packages for SQL. NOTE this requires connection to the Northwestern VPN 
install.packages("RPostgreSQL")
install.packages("plyr")
install.packages("dplyr")
install.packages("sqldf")
install.packages("data.table")
install.packages("mltools")
install.packages("arules")
library("RPostgreSQL")
library("plyr")
library("dplyr")
library("sqldf")
library("data.table")
library("mltools")
library("arules")

# connect to the server
pw <- "rsp714_pw"
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname ="iems308",host ="gallery.iems.northwestern.edu", port = "5432",user = "rsp714", password = pw)
options(sqldf.RPostgreSQL.user ="rsp714", 
        sqldf.RPostgreSQL.password =pw,
        sqldf.RPostgreSQL.dbname ="iems308",
        sqldf.RPostgreSQL.host ="gallery.iems.northwestern.edu", 
        sqldf.RPostgreSQL.port =5432)

# import the subsetted data from pgAdmin 
co_store <- sqldf('select distinct sku, store, saledate, trannum from rsp714_schema.skutrnsact')

# double check the numbers are correct
number_trans <- sqldf('select count (distinct trannum) from rsp714_schema.skutrnsact')
number_sku <- sqldf('select count (sku) from rsp714_schema.skutrnsact')

# close the connection to pgAdmin, it won't be necessary for the next portion of the analysis 
dbDisconnect(con)

#######
# Begin Association Rules Analysis 
#######

# create data table with just sku and trannum, sort by sku
baskets_df <- data_frame(co_store$sku, co_store$saledate,co_store$trannum)
names(baskets_df) <- c("sku","saledate","trannum")
baskets_df$basket <- paste(baskets_df$saledate, baskets_df$trannum,sep =',')
names(baskets_df) <-c("sku","saledate", "trannum","basket")
arrange(baskets_df,baskets_df$sku,baskets_df$basket)
sku_count <- count(baskets_df,sku)
baskets_count<-merge.data.frame(baskets_df,sku_count)
names(baskets_count)<-c("sku","trannum","saledate","basket","n")
baskets_count <- arrange(baskets_count,desc(baskets_count$n))

# remove skus not included in at least 10% of the transactions 
ten_percent <- (0.10 * number_trans)
baskets_trimmed <- subset(baskets_count, n > 86.9)
# this reduces our number of transactions to 34049 and 154 skus which is much more maneagable 

# need to one-hot encode the data to run apriori
baskets_sorted <- baskets_trimmed[order(baskets_trimmed$basket),]
basket_format <- ddply(baskets_sorted,c("basket"), function(df1)paste(df1$sku, collapse = ","))
names(basket_format) <- c("basket","sku list")
basket_format$basket <- NULL

# write into csv to easily get unique IDs 
write.csv(basket_format,"SkuList.csv",quote=FALSE, row.names = TRUE)

# read back the csv as transactions
trnsactions <- read.transactions(file = "SkuList.csv",rm.duplicates = TRUE, format = "basket",sep=",",cols=1)
# run the apriori rules anl
basket_rules <- apriori(trnsactions,parameter = list(supp = 0.0001, conf = 0.5, target = "rules"))
df_basket <- as(basket_rules,"data.frame")
View(df_basket)
