/*
    Purpose: Calculate yearly customer churn rate for an online retail dataset.
    - Churn is defined as 180 days of inactivity since the last purchase.
    - For previous years, Dec 31 of that year is used as the reference date.
    - For the most recent year, the last recorded invoice date in the dataset is used.
    - The output includes the total number of customers, number of churned customers, and churn rate (%) per year.
*/

-- Step 1: Find the last recorded invoice date in the dataset
WITH customer_churn_maxdate AS
(
    SELECT MAX(InvoiceDate) AS max_invoice_date         -- Latest purchase in the dataset; used as reference for the most recent year
    FROM online_retail
),

-- Step 2: Get last purchase date for each customer per year
customer_churn_last_purchase AS
(
    SELECT
        Customer_ID AS customer_id,                     -- Unique customer identifier
        YEAR(InvoiceDate) AS purchase_year,            -- Extract the year of purchase
        MAX(InvoiceDate) AS last_purchase_date         -- Most recent purchase of the customer in that year
    FROM online_retail
    WHERE Customer_ID IS NOT NULL                       -- Exclude records without a customer ID
    GROUP BY Customer_ID, YEAR(InvoiceDate)            -- Group to calculate last purchase per customer per year
),

-- Step 3: Determine reference date for churn evaluation
customer_churn_reference AS
(
    SELECT
        lp.customer_id,                                 -- Customer ID
        lp.purchase_year,                               -- Year of the purchase
        lp.last_purchase_date,                          -- Last purchase date for the customer in that year
        md.max_invoice_date,                            -- Overall last recorded date in the dataset
        CASE 
            -- If this is the most recent year in the dataset, use the dataset MaxDate as reference
            WHEN lp.purchase_year = YEAR(md.max_invoice_date) THEN md.max_invoice_date
            -- Otherwise, use Dec 31 of that year as reference
            ELSE CAST(CAST(lp.purchase_year AS VARCHAR(4)) + '-12-31' AS DATETIME)
        END AS reference_date                            -- Reference date for inactivity/churn calculation
    FROM customer_churn_last_purchase lp
    CROSS JOIN customer_churn_maxdate md                -- Attach max_invoice_date to all rows
),

-- Step 4: Flag customers as churned or active
customer_churn_flagged AS
(
    SELECT
        customer_id,                                   -- Customer ID
        purchase_year,                                 -- Year of purchase
        last_purchase_date,                             -- Last purchase date
        reference_date,                                -- Reference date for churn evaluation
        CASE 
            -- Step 4a: If more than 180 days since last purchase, customer is considered churned
            WHEN DATEDIFF(DAY, last_purchase_date, reference_date) >= 180 THEN 1
            -- Step 4b: Otherwise, customer is still active
            ELSE 0
        END AS is_churned                               -- Flag indicating churn (1) or active (0)
    FROM customer_churn_reference
)

-- Step 5: Aggregate results to calculate yearly churn rate
SELECT
    purchase_year AS [year],                            -- Year
    COUNT(customer_id) AS number_of_customers,          -- Total number of customers for that year
    SUM(is_churned) AS number_of_churned_customers,    -- Number of customers classified as churned
    CAST(SUM(is_churned) * 100.0 / COUNT(customer_id) AS DECIMAL(5,2)) AS churn_rate_percent  -- Churn rate as a percentage
FROM customer_churn_flagged
GROUP BY purchase_year                                 -- Aggregate by year
ORDER BY purchase_year;                                -- Order results by ascending year
