-- Purpose: Identify the top 5 and bottom 5 selling products based on total sales
-- Excludes test items, postage, manual entries, gift vouchers, and other non-products

-- Step 1: Filter and clean the raw data
WITH clean_products AS
(
	SELECT
		StockCode AS stock_code,                 -- Product identifier
		Description AS description,              -- Product description
		Quantity * Price AS total_sales          -- Revenue per row
	FROM online_retail
	WHERE
		StockCode IS NOT NULL                    -- Exclude missing product codes
		AND Quantity > 0                         -- Exclude returns or negative quantities
		AND Price > 0                            -- Exclude free items or refunds
		AND StockCode NOT IN ('POST','S','TEST001','M','m','DOT','C2','D','ADJUST','B')  -- Exclude non-products
		AND StockCode NOT LIKE 'gift%'           -- Exclude gift voucher items
),

-- Step 2: Aggregate revenue per product
grouped_revenue AS
(
	SELECT
		stock_code,
		description,
		SUM(total_sales) as total_revenue        -- Total revenue per product
	FROM clean_products
	GROUP BY
		stock_code,
		description
),

-- Step 3: Identify top 5 selling products
top_5_products AS
(
	SELECT TOP 5
		stock_code,
		description,
		total_revenue
	FROM grouped_revenue
	ORDER BY total_revenue DESC               -- Highest revenue first
),

-- Step 4: Identify bottom 5 selling products
bottom_5_products AS
(
	SELECT TOP 5
		stock_code,
		description,
		total_revenue
	FROM grouped_revenue
	ORDER BY total_revenue ASC                -- Lowest revenue first
)

-- Step 5: Combine top and bottom products with a category label
SELECT
	'TOP' AS category,                        -- Label for top sellers
	stock_code,
	description,
	ROUND(total_revenue,2) AS total_revenue   -- Round revenue for readability
FROM top_5_products
UNION ALL
SELECT
	'BOTTOM' AS category,                     -- Label for bottom sellers
	stock_code,
	description,
	ROUND(total_revenue,2) AS total_revenue
FROM bottom_5_products
ORDER BY
	category DESC;                             -- Top products listed first, then bottom
