# Databricks Notebook: SCD Type 2 Implementation using Spark SQL

# 1. Create Source and Target Tables
spark.sql("""
CREATE OR REPLACE TABLE customer_source (
    customer_id INT,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone_number STRING,
    updated_at TIMESTAMP
)
""")

spark.sql("""
CREATE OR REPLACE TABLE customer_scd2 (
    customer_id INT,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone_number STRING,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    current_flag BOOLEAN
)
""")

# 2. Insert Sample Data into Source Table
spark.sql("""
INSERT INTO customer_source VALUES
(1, 'John', 'Doe', 'john.doe@example.com', '123-456-7890', '2023-01-01 12:00:00'),
(2, 'Jane', 'Smith', 'jane.smith@example.com', '987-654-3210', '2023-01-01 12:00:00')
""")

# 3. Initial Load to Target Table
spark.sql("""
INSERT INTO customer_scd2
SELECT customer_id, first_name, last_name, email, phone_number, current_timestamp(), NULL, TRUE
FROM customer_source
""")

# 4. SCD Type 2 Logic

# Step 1: Identify Changed Records
spark.sql("""
CREATE OR REPLACE TEMP VIEW changes AS
SELECT s.customer_id, s.first_name, s.last_name, s.email, s.phone_number
FROM customer_source s
JOIN customer_scd2 t
ON s.customer_id = t.customer_id AND t.current_flag = TRUE
WHERE s.first_name <> t.first_name
   OR s.last_name <> t.last_name
   OR s.email <> t.email
   OR s.phone_number <> t.phone_number
""")

# Step 2: Expire Old Records
spark.sql("""
UPDATE customer_scd2
SET end_date = current_timestamp(), current_flag = FALSE
WHERE current_flag = TRUE
AND customer_id IN (SELECT customer_id FROM changes)
""")

# Step 3: Insert New Records
spark.sql("""
INSERT INTO customer_scd2
SELECT customer_id, first_name, last_name, email, phone_number, current_timestamp(), NULL, TRUE
FROM changes
""")

# 5. Test with Changed Source Data
spark.sql("""
INSERT INTO customer_source VALUES
(1, 'John', 'Doe', 'john.d.new@example.com', '123-456-7890', '2023-02-01 12:00:00')
""")

# Repeat SCD Steps 1-3 for new changes

# 6. Final Check
display(spark.sql("SELECT * FROM customer_scd2 ORDER BY customer_id, start_date"))
