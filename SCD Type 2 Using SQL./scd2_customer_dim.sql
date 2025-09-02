-- scd2_customer_dim.sql
-- ---------------------------------------------------------
-- Snowflake Implementation of Slowly Changing Dimension Type 2 (SCD2)
-- for the customer dimension table.
-- ---------------------------------------------------------

-- 1. Create Source Table (Landing Table)
CREATE OR REPLACE TABLE customer_source (
    customer_id    INT,
    first_name     STRING,
    last_name      STRING,
    email          STRING,
    phone_number   STRING,
    update_at      TIMESTAMP
);

-- Initial Data Load into Source
INSERT INTO customer_source (customer_id, first_name, last_name, email, phone_number, update_at) VALUES
(1, 'Prajwal',  'Bharsakale', 'pbhar@gmail.com',   '1234567890', '2024-01-22 12:44:00'),
(2, 'Shreyash', 'Nagpure',    'snag@gmail.com',   '0987654321', '2024-04-29 09:55:59'),
(3, 'Rudresh',  'Pasarkar',   'rpas@gmail.com',   '1234509876', '2024-10-12 12:24:09'),
(4, 'Abhijit',  'Katore',     'akat@gmail.com',   '0987612345', '2024-09-22 11:32:07'),
(5, 'Pradyumn', 'Dharmale',   'pdha@gmail.com',   '1234098567', '2024-12-25 02:04:00'),
(6, 'Suyog',    'Kulkarni',   'skul@gmail.com',   '8907652341', '2024-06-22 08:31:50');

------------------------------------------------------------
-- 2. Create Target Dimension Table (SCD2 Table)
------------------------------------------------------------
CREATE OR REPLACE TABLE customer_dim_scd2 (
    customer_id   INT,
    first_name    STRING,
    last_name     STRING,
    email         STRING,
    phone_number  STRING,
    start_date    TIMESTAMP,
    end_date      TIMESTAMP,
    current_flag  BOOLEAN
);

------------------------------------------------------------
-- 3. Initial Load from Source into Dimension
------------------------------------------------------------
INSERT INTO customer_dim_scd2
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    phone_number,
    CURRENT_TIMESTAMP AS start_date,
    NULL              AS end_date,
    TRUE              AS current_flag
FROM customer_source;

------------------------------------------------------------
-- 4. Simulating New Incoming Data (Example Update)
------------------------------------------------------------
-- Example: Customer ID 1 updated email
INSERT INTO customer_source (customer_id, first_name, last_name, email, phone_number, update_at) VALUES
(1, 'Prajwal', 'Bharsakale', 'pbharsakle@gmail.com', '1234567890', '2024-01-22 12:44:00');

------------------------------------------------------------
-- 5. SCD Type 2 Merge Logic
--    (Detect changes, expire old records, insert new)
------------------------------------------------------------
MERGE INTO customer_dim_scd2 AS tgt
USING (
    SELECT s.customer_id,
           s.first_name,
           s.last_name,
           s.email,
           s.phone_number
    FROM customer_source s
    JOIN customer_dim_scd2 d
      ON s.customer_id = d.customer_id
     AND d.current_flag = TRUE
    WHERE s.first_name   <> d.first_name
       OR s.last_name    <> d.last_name
       OR s.email        <> d.email
       OR s.phone_number <> d.phone_number
) AS src
ON tgt.customer_id = src.customer_id AND tgt.current_flag = TRUE

-- Step A: Expire Old Record
WHEN MATCHED THEN UPDATE SET
    tgt.end_date = CURRENT_TIMESTAMP,
    tgt.current_flag = FALSE

-- Step B: Insert New Record
WHEN NOT MATCHED THEN INSERT (
    customer_id, first_name, last_name, email, phone_number, start_date, end_date, current_flag
)
VALUES (
    src.customer_id, src.first_name, src.last_name, src.email, src.phone_number,
    CURRENT_TIMESTAMP, NULL, TRUE
);

------------------------------------------------------------
-- 6. Final Check
------------------------------------------------------------
SELECT * FROM customer_dim_scd2 ORDER BY customer_id, start_date;
