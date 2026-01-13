/*
    Purpose: Analyze monthly sales trends per product, including month-over-month changes 
             and 3-month rolling averages, to identify seasonal patterns or growth trends.
*/

-- Step 1: Aggregate monthly sales per product
WITH product_monthly_sales AS
(
    SELECT
        StockCode AS stock_code,                    -- Unique product code
        Description AS description,                 -- Product description
        YEAR(InvoiceDate) AS year,                  -- Year of the invoice
        MONTH(InvoiceDate) AS month,                -- Month number
        DATENAME(MONTH, InvoiceDate) AS month_name, -- Month name (e.g., January)
        SUM(Quantity * Price) AS monthly_sales_per_product  -- Total sales of the product in that month
    FROM online_retail
    WHERE
        StockCode IS NOT NULL                       -- Exclude missing product codes
        AND Quantity > 0                            -- Exclude returns or negative quantities
        AND Price > 0                               -- Exclude free items or refunds
        AND StockCode NOT IN ('POST','S','TEST001','M','m','DOT','C2','D','ADJUST','B')  -- Exclude non-products or adjustments
        AND StockCode NOT LIKE 'gift%'              -- Exclude gift vouchers
    GROUP BY
        StockCode,
        Description,
        YEAR(InvoiceDate),
        MONTH(InvoiceDate),
        DATENAME(MONTH, InvoiceDate)
),

-- Step 2: Add previous month sales to calculate month-over-month change
previous_sales AS
(
    SELECT
        stock_code,
        description,
        year,
        month,
        month_name,
        monthly_sales_per_product,
        LAG(monthly_sales_per_product,1,NULL) 
            OVER (PARTITION BY stock_code ORDER BY year, month) AS previous_month_sales -- Previous month sales per product
    FROM product_monthly_sales
)

-- Step 3: Calculate monthly percent change and 3-month rolling average
SELECT
    stock_code,
    description,
    year,
    month_name,
    monthly_sales_per_product,                          -- Current month sales
    previous_month_sales,                               -- Previous month sales
    ROUND(COALESCE((monthly_sales_per_product - previous_month_sales) / previous_month_sales * 100,0),2) 
        AS monthly_percent_change,                      -- Month-over-month % change; 0 if previous month is NULL
    ROUND(
        AVG(COALESCE((monthly_sales_per_product - previous_month_sales) / previous_month_sales * 100,0)) 
            OVER (PARTITION BY stock_code               -- Calculate separately per product
                ORDER BY year, month                    -- Order months chronologically
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) 
        AS three_month_avg_change                       -- 3-month rolling average of monthly % change
FROM previous_sales;
