# SCD Type 2 Implementation in Snowflake Using Python Pandas

## Overview

This document outlines the steps to implement Slowly Changing Dimension (SCD) Type 2 for a customer table using Python's `pandas` library. The goal is to track changes in customer data over time while maintaining historical records.

## Steps to Implement SCD Type 2

### 1. Initial Setup

Install the required libraries:

```python
pip install pandas

#Import pandas and create DataFrames to simulate the source and target tables.

# Import python packages
import pandas as pd
from datetime import datetime

#If the dataframe is large pandas will truncating the output with ....
#for avoding truncating output setting up the display size

#Set display options to show all columns and rows
pd.set_option('display.max_columns',None) #Show all columns
pd.set_option('display.max_rows',None) #Show all rows
pd.set_option('display.max_colwidth',None) #Show full column width if needed


# Create a function to simulate current timestamp for simplicity
def current_timestamp():
    return datetime.now()
```

### 2. Create Source and Target Tables as DataFrames

#### Source Table (Customer Data)

Initial source data
```python
#Initial source table

data_source ={
    "customer_id"  : [1,2,3,4,5,6],
    "first_name"   : ["Prajwal","Shreyash","Rudresh","Abhijit","Pradyumn","Suyog"],
    "last_name"    : ["Bharsakale","Nagpure","Pasarkar","Katore","Dharmale","Kulkarni"],
    "email"        : ["pbhar@gmail.com","snag@gmail.com","rpas@gmail.com","akat@gmail.com","pdha@gmail.com","skul@gmail.com"],
    "phone_number" : ["1234567890","0987654321","1234509876","0987612345","1234098567","8907652341"],
    "update_at"    : [pd.Timestamp('2024-01-22 12:44:00'),pd.Timestamp('2024-04-29 09:55:59'),pd.Timestamp('2024-10-12 12:24:09'),pd.Timestamp('2024-09-22 11:32:07'),pd.Timestamp('2024-12-25 02:04:00'),pd.Timestamp('2024-06-22 08:31:50')]
}

df_source = pd.DataFrame(data_source)

#this will show the index by deault
print(df_source)

print('-------------------------------------------------------------------')
#To Avoid index in 1st column we can use
print(df_source.to_string(index=False))
```

#### Target Table (SCD Type 2)
```python
#Create an empty DataFrame for the target SCD2 table
df_scd2 = pd.DataFrame(columns=[
    "customer_id", "first_name", "last_name", "email", "phone_number", 
    "start_date", "end_date", "current_flag"
])

#Initial data population for the SCD2 table from the source
df_scd2 = df_source.copy()
df_scd2["start_date"] = current_timestamp()
df_scd2["end_date"] = pd.NaT
df_scd2["current_flag"] = True

print(df_scd2)

print('-------------------------------------------------------------------')
#To Avoid index in 1st column we can use
print(df_scd2.to_string(index=False))
```

### 3. Insert New Data into Source Table (Simulating Changes)

Insert new records or changes into the source DataFrame. For instance, a change in email for customer_id = 1:
```python
#New data inserted into source (simulating an update)
#Print pervious version of source
print('-------------------------------------------------------------------')
#To Avoid index in 1st column we can use
print(df_source.to_string(index=False))

new_data ={
      "customer_id"  : [1],
    "first_name"   : ["Prajwal"],
    "last_name"    : ["Bharsakale"],
    "email"        : ["pbharsakle@gmail.com"], #updated email
    "phone_number" : ["1234567890"],
    "update_at"    : [pd.Timestamp('2024-01-22 12:44:00')]
}

new_row = pd.DataFrame(new_data)
df_source = pd.concat([df_source,new_row],ignore_index=True)

print('-------------------------------------------------------------------')
print(df_source.to_string(index=False))

```

### 4. SCD Type 2 Logic to Track Changes

#### Step 1: Identify Changed Records
```python
#We'll compare the source and target DataFrame and find any differences in non-key columns for active
#records in the target

#print orginal data
print('-------------------------------------------------------------------')
#To Avoid index in 1st column we can use
print(df_source.to_string(index=False))


#Indentify records with changes by comparing current active records
df_active_scd2 = df_scd2[df_scd2["current_flag"] == True]


#print the records with current flag true
print('-------------------------------------------------------------------')
print(df_active_scd2.to_string(index=False))


#Join source with target (active records only) to find the differences
df_changes = pd.merge(df_source, df_active_scd2, on ="customer_id", how="left", suffixes=('_src','_tgt'))

#print the change rows
print('-------------------------------------------------------------------')
print(df_changes.to_string(index=False))


#Find rows with changes in any of the columns except 'customer_id'
df_changes = df_changes [
    (df_changes ["first_name_src"] != df_changes["first_name_tgt"]) |
    (df_changes ["last_name_src"] != df_changes["last_name_tgt"]) |
    (df_changes ["email_src"] != df_changes["email_tgt"]) |
    (df_changes ["phone_number_src"] != df_changes["phone_number_tgt"])
]

#select only changed records
df_changes = df_changes[["customer_id","first_name_src","last_name_src","email_src","phone_number_src"]]

#print the change rows
print('-------------------------------------------------------------------')
print(df_changes.to_string(index=False))

```

#### Step 2: Expire the Old Record
```python
# Expire old records in the target table by setting end_date and current_flag = False
df_scd2.loc[df_scd2["customer_id"].isin(df_changes["customer_id"]), "end_date"] = current_timestamp()
df_scd2.loc[df_scd2["customer_id"].isin(df_changes["customer_id"]), "current_flag"] = False
```


#### Step 3: Insert the New Record
```python
#Prepare the new records for insertion
df_new_records = df_changes.rename(columns={
    "first_name_src":"first_name",
    "last_name_src":"last_name",
    "email_src":"email",
    "phone_number_src":"phone_number"
})

#Add SCD2-specific columns to new records
df_new_records["start_date"] = current_timestamp()
df_new_records["end_date"] = pd.NaT
df_new_records["current_flag"] = True

#Append the new records to the SCD2 table
df_scd2 = pd.concat([df_scd2,df_new_records], ignore_index=True)

```

### 5. Final Check for the Target Table
```python
#Drop unwanted columns such as 'update_at'
df_scd2 = df_scd2.drop(columns=["updated_at"], errors='ignore')

#Ensure no duplicate 'current_flag' column
df_scd2 = df_scd2.loc[:, ~df_scd2.columns.duplicated()]

#Select only the required columns for the final SCD2 table

df_scd2 = df_scd2[["customer_id", "first_name", "last_name", "email", "phone_number",
                   "start_date", "end_date", "current_flag" 
]]
#Print source data
print('-------------------------------------------------------------------')
#To Avoid index in 1st column we can use
print(df_source.to_string(index=False))

#Print Target data
print('-------------------------------------------------------------------')
#To Avoid index in 1st column we can use
print(df_scd2.to_string(index=False))

```

## Troubleshooting

### Common Issues

	•	Duplicate Columns: Ensure to drop or rename any columns that may be duplicated during merging or processing.
	•	NaN Values: Check for any unexpected NaN values in the DataFrame, especially in key fields.

### Conclusion

This document provides a clear outline for implementing SCD Type 2 using pandas in Python. By following these steps, you can effectively track changes in your customer data while maintaining historical records.
