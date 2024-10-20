Here’s how you can convert the SQL logic to Python using Snowflake’s Python connector or the Snowpark library to create and manage the Snowflake tables within a notebook. I’ll assume you are using the Snowpark API, which is the preferred method for handling data in notebooks.

1. Initial Setup

First, make sure you have the Snowflake Snowpark installed:

pip install "snowflake-snowpark-python[pandas]"

Then, start by connecting to Snowflake from your notebook:

from snowflake.snowpark.session import Session
from snowflake.snowpark.functions import col, current_timestamp, lit

# Set up the connection parameters
connection_parameters = {
    "account": "<account_name>",
    "user": "<username>",
    "password": "<password>",
    "role": "<role>",
    "warehouse": "<warehouse>",
    "database": "<database>",
    "schema": "<schema>"
}

# Create a Snowpark session
session = Session.builder.configs(connection_parameters).create()

2. Create Source and Target Tables

Source Table DDL

session.sql("""
    CREATE OR REPLACE TABLE customer_source (
        customer_id INT PRIMARY KEY,
        first_name STRING,
        last_name STRING,
        email STRING,
        phone_number STRING,
        updated_at TIMESTAMP
    );
""").collect()

Target Table DDL

session.sql("""
    CREATE OR REPLACE TABLE customer_scd2 (
        customer_id INT,
        first_name STRING,
        last_name STRING,
        email STRING,
        phone_number STRING,
        start_date TIMESTAMP,
        end_date TIMESTAMP,
        current_flag BOOLEAN,
        PRIMARY KEY(customer_id, start_date)
    );
""").collect()

3. Insert Sample Data into Source Table

session.sql("""
    INSERT INTO customer_source (customer_id, first_name, last_name, email, phone_number, updated_at) VALUES
    (1, 'John', 'Doe', 'john.doe@example.com', '123-456-7890', '2023-01-01 12:00:00'),
    (2, 'Jane', 'Smith', 'jane.smith@example.com', '987-654-3210', '2023-01-01 12:00:00');
""").collect()

4. Insert Initial Data into Target Table

session.sql("""
    INSERT INTO customer_scd2 (customer_id, first_name, last_name, email, phone_number, start_date, end_date, current_flag) 
    SELECT customer_id, first_name, last_name, email, phone_number, CURRENT_TIMESTAMP, NULL, TRUE 
    FROM customer_source;
""").collect()

5. SCD Type 2 Logic for Tracking Changes

Step 1: Identify Changed Records

changes = session.sql("""
    SELECT s.customer_id, s.first_name, s.last_name, s.email, s.phone_number
    FROM customer_source s
    LEFT JOIN customer_scd2 t
    ON s.customer_id = t.customer_id AND t.current_flag = TRUE
    WHERE (s.first_name <> t.first_name OR s.last_name <> t.last_name OR 
           s.email <> t.email OR s.phone_number <> t.phone_number)
""")

Step 2: Expire the Old Records

session.sql("""
    UPDATE customer_scd2
    SET end_date = CURRENT_TIMESTAMP, current_flag = FALSE
    FROM ({changes})
    WHERE customer_scd2.customer_id = changes.customer_id
    AND customer_scd2.current_flag = TRUE;
""").collect()

Step 3: Insert the New Records

session.sql(f"""
    INSERT INTO customer_scd2 (customer_id, first_name, last_name, email, phone_number, start_date, end_date, current_flag)
    SELECT customer_id, first_name, last_name, email, phone_number, CURRENT_TIMESTAMP, NULL, TRUE
    FROM ({changes});
""").collect()

6. Testing with New Changes

You can now insert a change in the source table to simulate an update:

session.sql("""
    INSERT INTO customer_source (customer_id, first_name, last_name, email, phone_number, updated_at) VALUES
    (1, 'John', 'Doe', 'john.d.new@example.com', '123-456-7890', '2023-02-01 12:00:00'); -- email changed
""").collect()

7. Query Target Table to Check the Changes

result = session.sql("""
    SELECT * FROM customer_scd2 ORDER BY customer_id, start_date;
""").collect()

# Print the result for inspection
for row in result:
    print(row)

Final Remarks

	•	Ensure your connection_parameters are set correctly for your Snowflake instance.
	•	You can run this Python code in the Snowflake notebook directly to create and manage the tables, insert sample data, and implement SCD Type 2 tracking.

This code should work for your notebook, helping you track changes in the customer_source and maintain the customer_scd2 table with SCD Type 2 logic.
