-- Purpose: Calculate monthly sales totals and a cumulative (running) revenue across all months and years
-- Notes:
--   1. Only considers valid product sales (positive quantity and price, excludes returns, postage, gift vouchers, and manual adjustments)
--   2. Running total accumulates revenue chronologically across the entire dataset

WITH invoice_lines AS
(
    -- Step 1: Extract invoice-level revenue and date components
    SELECT
        YEAR(InvoiceDate) AS year,                      -- Extract the year of the invoice
        MONTH(InvoiceDate) AS month,                    -- Extract numeric month (used for ordering)
        DATENAME(MONTH, InvoiceDate) AS month_name,     -- Extract month name (for display)
        Quantity * Price AS total_sales                 -- Calculate revenue per invoice line
    FROM online_retail
    WHERE
        StockCode IS NOT NULL                           -- Exclude rows with missing product codes
        AND Quantity > 0                                -- Exclude negative or zero quantity (returns)
        AND Price > 0                                   -- Exclude free items or refunds
        AND StockCode NOT IN ('POST','S','TEST001','M','m','DOT','C2','D','ADJUST','B')  -- Exclude non-product codes and adjustments
        AND StockCode NOT LIKE 'gift%'                  -- Exclude gift voucher items
),

monthly_sales AS
(
    -- Step 2: Aggregate invoice lines to monthly totals
    SELECT
        year,                                           -- Group by year
        month,                                          -- Group by numeric month (for ordering)
        month_name,                                     -- Keep month name for display
        SUM(total_sales) AS total_revenue               -- Sum revenue for the month
    FROM invoice_lines
    GROUP BY
        year,
        month,
        month_name
)

-- Step 3: Final output with monthly revenue and running total across all months/years
SELECT
    year,                                              -- Year of sales
    month_name,                                        -- Month name for display
    ROUND(total_revenue,2) AS monthly_total_revenue,   -- Total revenue for the month (rounded)
    ROUND(
        SUM(total_revenue) OVER (ORDER BY year, month),2
    ) AS running_total_revenue                         -- Cumulative revenue across all months in chronological order
FROM monthly_sales
ORDER BY
    year,
    month                                              -- Ensure chronological order for reporting and running total
