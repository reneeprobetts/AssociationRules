"""
Association Rules
Renee Probetts
IEMS 308 
"""
#import the necessary packages
import psycopg2
import mlxtend
import pandas as pd
import numpy as np
from mlxtend.preprocessing import OnehotTransactions
from mlxtend.frequent_patterns import apriori
from psycopg2 import extras
from mlxtend.frequent_patterns import association_rules

# connect to database
con = psycopg2.connect(host = "gallery.iems.northwestern.edu",user = 'rsp714', password = 'rsp714_pw',dbname = 'iems308')

# open a cursor
cur = con.cursor()

# download the necessary data table for association rules mining
cur.execute('SELECT sku, saledate, trannum from rsp714_schema.skutrnsact')
co_store = pd.DataFrame(cur.fetchall())
co_store.columns = ['sku','saledate','trannum']
co_store.head(10)

#close the connection
cur.close()
con.close()

"""
begin association rules analysis
"""

# create data frame with the trannum and saledate as the basket, then reduce to simply sku and basket
co_store["baskets"] = (co_store["saledate"].astype(str) + "," + co_store["trannum"].astype(str))
co_store.head(10)
transactions = co_store[["sku","baskets"]]

#remove sku that are not in at least 10 of the baskets
sku_counts = transactions['sku'].value_counts()
trans_counts = sku_counts.to_frame()
trans_counts = trans_counts.reset_index()
trans_counts.columns=["sku","n"]
trans_counts = trans_counts[trans_counts.n > 10]
transactions_to_encode = trans_counts.drop_duplicates()
                                  

# now perform one hot encoding on this smaller data set and group by the number of transactions 
baskets_encoded = pd.get_dummies(transactions_to_encode, columns = ['sku'])
del(baskets_encoded['n'])
trans_encoded = baskets_encoded.groupby('baskets').sum()
                                  
# using the mlxtend package, run the association mining after using apriori
frequent_items = apriori(baskets_encoded,min_support = 0.01, use_colnames = True)
rules = assocation_rules(frequent_items, metric = "confidence")
