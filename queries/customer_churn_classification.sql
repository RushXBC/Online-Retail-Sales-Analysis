/*
    Purpose: Identify and classify customer churn based on purchase history.
    - Determine which customers are too new to classify, and which are eligible for churn analysis.
    - Eligible customers are flagged as 'active' or 'churned' based on their last purchase relative to the latest invoice date.
    - This structured approach ensures accurate churn metrics while excluding recent customers from misclassification.
*/

-- Step 1: Create a CTE with first and last purchase dates per customer
WITH min_max_purchase AS
(
    SELECT 
        Customer_ID AS customer_id,          -- Unique customer identifier
        MIN(InvoiceDate) AS first_purchase,  -- Earliest purchase date
        MAX(InvoiceDate) AS last_purchase    -- Most recent purchase date
    FROM dbo.online_retail
    GROUP BY Customer_ID
),

-- Step 2: Create a CTE to determine the latest invoice date in the dataset
last_recorded_date AS
(
    SELECT
        MAX(InvoiceDate) AS reference_date   -- Reference date for churn calculations
    FROM dbo.online_retail
),

-- Step 3: Flag customers who are too new to classify for churn
churn_flag AS
(
    SELECT
        m.customer_id,
        m.first_purchase,
        m.last_purchase,
        l.reference_date,
        CASE
            -- Step 3a: Customers with first purchase within 90 days of reference date
            WHEN DATEDIFF(DAY, m.first_purchase, l.reference_date) < 90
                THEN 'too new to classify'
            ELSE 'ok'  -- Step 3b: Eligible for churn classification
        END AS churn_eligibility
    FROM min_max_purchase AS m
    CROSS JOIN last_recorded_date AS l
)

-- Step 4: Classify eligible customers as 'active' or 'churned'
SELECT
    customer_id,
    first_purchase,
    last_purchase,
    reference_date,
    churn_eligibility,  -- Indicates if customer is eligible for churn classification
    CASE
        -- Step 4a: Customers whose last purchase was more than 90 days before reference date → churned
        WHEN DATEDIFF(DAY, last_purchase, reference_date) > 90
            THEN 'churned'
        ELSE 'active'  -- Step 4b: Otherwise → active
    END AS churn_classification
FROM churn_flag
-- Step 5: Only classify customers who are eligible
WHERE churn_eligibility = 'ok'

-- Step 6: Optional: sort results by most recent last purchase
ORDER BY
    last_purchase DESC;
