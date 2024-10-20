# SCD Type 2 Implementation in Snowflake Using Python Pandas

## Overview

This document outlines the steps to implement Slowly Changing Dimension (SCD) Type 2 for a customer table using Python's `pandas` library. The goal is to track changes in customer data over time while maintaining historical records.

## Steps to Implement SCD Type 2

### 1. Initial Setup

Install the required libraries:

```bash
pip install pandas

Import pandas and create DataFrames to simulate the source and target tables.

import pandas as pd
from datetime import datetime

# Create a function to simulate current timestamp for simplicity
def current_timestamp():
    return datetime.now()
```

### 2. Create Source and Target Tables as DataFrames

#### Source Table (Customer Data)

Initial source data
```bash
data_source = {
    "customer_id": [1, 2],
    "first_name": ["John", "Jane"],
    "last_name": ["Doe", "Smith"],
    "email": ["john.doe@example.com", "jane.smith@example.com"],
    "phone_number": ["123-456-7890", "987-654-3210"],
    "updated_at": [pd.Timestamp('2023-01-01 12:00:00'), pd.Timestamp('2023-01-01 12:00:00')]
}

df_source = pd.DataFrame(data_source)
```

#### Target Table (SCD Type 2)
```bash
# Create an empty DataFrame for the target SCD2 table
df_scd2 = pd.DataFrame(columns=[
    "customer_id", "first_name", "last_name", "email", "phone_number",
    "start_date", "end_date", "current_flag"
])
```

```bash
# Initial data population for the SCD2 table from the source
df_scd2 = df_source.copy()
df_scd2["start_date"] = current_timestamp()
df_scd2["end_date"] = pd.NaT
df_scd2["current_flag"] = True
```

### 3. Insert New Data into Source Table (Simulating Changes)

Insert new records or changes into the source DataFrame. For instance, a change in email for customer_id = 1:
```bash
# New data inserted into source (simulating an update)
new_data = {
    "customer_id": [1],
    "first_name": ["John"],
    "last_name": ["Doe"],
    "email": ["john.d.new@example.com"],  # Updated email
    "phone_number": ["123-456-7890"],
    "updated_at": [pd.Timestamp('2023-02-01 12:00:00')]
}

new_row = pd.DataFrame(new_data)
df_source = pd.concat([df_source, new_row], ignore_index=True)
```

### 4. SCD Type 2 Logic to Track Changes

#### Step 1: Identify Changed Records
```bash
# Get only active records from the target (df_scd2)
df_active_scd2 = df_scd2[df_scd2["current_flag"] == True]
# Join the source with active records from the target to find differences
df_changes = pd.merge(df_source, df_active_scd2, on="customer_id", how="left", suffixes=('_src', '_tgt'))
# Filter the records where there are changes in any non-key columns
df_changes = df_changes[
    (df_changes["first_name_src"] != df_changes["first_name_tgt"]) |
    (df_changes["last_name_src"] != df_changes["last_name_tgt"]) |
    (df_changes["email_src"] != df_changes["email_tgt"]) |
    (df_changes["phone_number_src"] != df_changes["phone_number_tgt"])
]
# Keep only the necessary columns from the source table (without _src suffix)
df_changes = df_changes[["customer_id", "first_name_src", "last_name_src", "email_src", "phone_number_src"]]
```

#### Step 2: Expire the Old Record
```python
# Expire old records in the target table by setting end_date and current_flag = False
df_scd2.loc[df_scd2["customer_id"].isin(df_changes["customer_id"]), "end_date"] = current_timestamp()
df_scd2.loc[df_scd2["customer_id"].isin(df_changes["customer_id"]), "current_flag"] = False
```


#### Step 3: Insert the New Record
```python
# Prepare new records from the changed data
df_new_records = df_changes.rename(columns={
    "first_name_src": "first_name",
    "last_name_src": "last_name",
    "email_src": "email",
    "phone_number_src": "phone_number"
})
# Add SCD2-specific columns to new records
df_new_records["start_date"] = current_timestamp()
df_new_records["end_date"] = pd.NaT
df_new_records["current_flag"] = True
# Append the new records to the target (SCD2) table
df_scd2 = pd.concat([df_scd2, df_new_records], ignore_index=True)
```

### 5. Final Check for the Target Table
```bash
# Select only the required columns for the final SCD2 table
df_scd2 = df_scd2[[
    "customer_id", "first_name", "last_name", "email", "phone_number", 
    "start_date", "end_date", "current_flag"
]]

# Print the final DataFrame
print(df_scd2)
```

## Troubleshooting

### Common Issues

	•	Duplicate Columns: Ensure to drop or rename any columns that may be duplicated during merging or processing.
	•	NaN Values: Check for any unexpected NaN values in the DataFrame, especially in key fields.

### Conclusion

This document provides a clear outline for implementing SCD Type 2 using pandas in Python. By following these steps, you can effectively track changes in your customer data while maintaining historical records.
