-- INSTAFOOD: A FICTIONAL FOOD DELIVERY COMPANY
-- OPERATIONAL LOGISTICS & PLATFORM PERFORMANCE ANALYTICS

USE instafood;

-- PILLAR 1: CUSTOMER & REVENUE ANALYTICS
-- Identifying VIP customers, lifetime value, and year-over-year churn.

-- Q1. Top Preferred Dishes Among Power Users (Scalable Top 5)
-- Evaluates dish preferences for high-frequency buyers in the last 365 days.
SELECT 
    c.customer_name,
    o.order_item,
    COUNT(o.order_id) AS total_orders
FROM Orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE DATEDIFF((SELECT MAX(order_date) FROM Orders), o.order_date) <= 365
GROUP BY c.customer_id, c.customer_name, o.order_item
HAVING COUNT(o.order_id) >= 5
ORDER BY total_orders DESC
LIMIT 10;

-- Q2. High-Frequency Account Analysis (Average Order Value)
-- Identifies loyal customers with over 750 lifetime orders and calculates their AOV.
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_order_count,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value_inr
FROM customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 750
ORDER BY avg_order_value_inr DESC;

-- Q3. VIP Cohort Identification (High Lifetime Value)
-- Identifies top-tier accounts generating over ₹100,000 in total platform spend
SELECT 
    c.customer_id,
    c.customer_name,
    ROUND(SUM(o.total_amount), 2) AS total_lifetime_spend_inr
FROM customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 100000
ORDER BY total_lifetime_spend_inr DESC;

-- Q4. Year-over-Year Customer Churn Diagnostics
-- Identifies the customers who placed orders in 2023, but not in 2024
SELECT 
    c.customer_id,
    c.customer_name,
    c.reg_date
FROM customers c
WHERE YEAR(c.reg_date) <= 2023 -- Ensures account was created in 2023 or earlier
  AND c.customer_id IN (
      SELECT DISTINCT customer_id 
      FROM Orders 
      WHERE YEAR(order_date) = 2023)
  AND c.customer_id NOT IN (
      SELECT DISTINCT customer_id 
      FROM Orders 
      WHERE YEAR(order_date) = 2024);


-- PILLAR 2: SUPPLY CHAIN & LOGISTICS OPERATIONS

-- Q5. Peak Demand Slots (2-Hour Windows)
-- Maps order volume across 2-hour intervals to guide delivery operations
SELECT 
    CASE
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        ELSE '22:00 - 00:00'
    END AS peak_time_slot,
    COUNT(order_id) AS total_orders
FROM Orders
GROUP BY peak_time_slot
ORDER BY total_orders DESC;

-- Q6. Unfulfilled Orders Index (By Restaurant & City)
-- Ranks partner restaurants generating the highest volume of undelivered or cancelled orders.
SELECT 
    r.restaurant_name, 
    r.city, 
    COUNT(o.order_id) AS unfulfilled_orders_count
FROM restaurants r
LEFT JOIN Orders o ON o.restaurant_id = r.restaurant_id
LEFT JOIN deliveries d ON o.order_id = d.order_id
WHERE d.delivery_id IS NULL OR d.delivery_status <> 'Delivered'
GROUP BY r.restaurant_id, r.restaurant_name, r.city
ORDER BY unfulfilled_orders_count DESC;

-- Q7. YoY Restaurant Cancellation Rate Comparison (%)
-- Evaluates percentage cancellation drift between 2023 and 2024 per restaurant.
WITH cancel_ratio_23 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL OR d.delivery_status <> 'Delivered' THEN 1 END) AS unfulfilled
    FROM Orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2023
    GROUP BY o.restaurant_id
),
cancel_ratio_24 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL OR d.delivery_status <> 'Delivered' THEN 1 END) AS unfulfilled
    FROM Orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY o.restaurant_id
)
SELECT 
    r.restaurant_name,
    ROUND((CAST(c23.unfulfilled AS DECIMAL(10,2)) / NULLIF(c23.total_orders,0)) * 100, 2) AS cancellation_rate_2023_pct,
    ROUND((CAST(c24.unfulfilled AS DECIMAL(10,2)) / NULLIF(c24.total_orders,0)) * 100, 2) AS cancellation_rate_2024_pct
FROM restaurants r
LEFT JOIN cancel_ratio_23 c23 ON r.restaurant_id = c23.restaurant_id
LEFT JOIN cancel_ratio_24 c24 ON r.restaurant_id = c24.restaurant_id
ORDER BY cancellation_rate_2023_pct DESC;

-- Q8. Rider Average Fulfillment Turnaround Time (SLA Benchmark)
-- Calculates true delivery duration per rider, taking overnight midnight shifts into account.
SELECT 
    d.rider_id,
    rd.rider_name,
    SEC_TO_TIME(ROUND(AVG(
        CASE 
            WHEN d.delivery_time < o.order_time 
                THEN TIME_TO_SEC(TIMEDIFF(ADDTIME(d.delivery_time, '24:00:00'), o.order_time))
            ELSE 
                TIME_TO_SEC(TIMEDIFF(d.delivery_time, o.order_time))
        END
    ))) AS avg_fulfillment_duration
FROM deliveries d
JOIN Orders o ON d.order_id = o.order_id
JOIN riders rd ON d.rider_id = rd.rider_id
WHERE d.delivery_status = 'Delivered'
GROUP BY d.rider_id, rd.rider_name
ORDER BY avg_fulfillment_duration ASC;


-- PILLAR 3: MENU & REGIONAL MARKET ANALYSIS
-- Evaluating city-level revenue, seasonal demand shifts, and peak partner days.

-- Q9. Regional Revenue Leaderboard (City Rankings)
-- Ranks geographic hubs by overall gross sales performance.
SELECT 
    r.city,
    ROUND(SUM(o.total_amount), 2) AS gross_revenue_inr,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS city_revenue_rank
FROM Orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;

-- Q10. Intra-City Restaurant Revenue Rankings
-- Ranks individual restaurants within their respective city markets for local benchmarking.
WITH city_revenue_cte AS (
    SELECT 
        r.restaurant_name, 
        r.city, 
        ROUND(SUM(o.total_amount), 2) AS total_revenue
    FROM restaurants r
    JOIN Orders o ON r.restaurant_id = o.restaurant_id
    WHERE DATEDIFF((SELECT MAX(order_date) FROM Orders), o.order_date) <= 365
    GROUP BY r.restaurant_id, r.restaurant_name, r.city),
city_revenue_cte2 as (
SELECT 
    restaurant_name, 
    city,
    total_revenue,
    DENSE_RANK() OVER (PARTITION BY city ORDER BY total_revenue DESC) AS rank_within_city
FROM city_revenue_cte)
select
	restaurant_name, 
    city,
    total_revenue,
    rank_within_city
FROM city_revenue_cte2
WHERE rank_within_city <= 10;

-- Q11. Top Selling Dish per City
-- Extracts the single most popular menu item in each metropolitan market.
WITH city_dish_ranks AS (
    SELECT 
        r.city, 
        o.order_item,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS item_rank
    FROM restaurants r
    JOIN Orders o ON r.restaurant_id = o.restaurant_id
    GROUP BY r.city, o.order_item
)
SELECT city, order_item AS top_selling_dish, total_orders
FROM city_dish_ranks
WHERE item_rank = 1;

-- Q12. Operational Peak Day per Restaurant
-- Identifies the specific day of the week with the highest order volume for kitchen planning.
WITH restaurant_day_ranks AS (
    SELECT 
        r.restaurant_name,
        DAYNAME(o.order_date) AS peak_day_of_week,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY r.restaurant_id ORDER BY COUNT(o.order_id) DESC) AS day_rank
    FROM Orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_id, r.restaurant_name, DAYNAME(o.order_date)
    )
SELECT restaurant_name, peak_day_of_week, total_orders
FROM restaurant_day_ranks
WHERE day_rank = 1;

-- Q13. Month-over-Month (MoM) Growth Trends
-- Evaluates monthly revenue momentum using window lag functions.
WITH monthly_sales AS (
    SELECT 
        YEAR(order_date) AS sales_year,
        MONTH(order_date) AS sales_month_num,
        MONTHNAME(order_date) AS sales_month_name,
        SUM(total_amount) AS total_monthly_sales,
        COALESCE(LAG(SUM(total_amount), 1) OVER (ORDER BY YEAR(order_date), MONTH(order_date)), 0) AS prev_month_sales
    FROM Orders
    GROUP BY YEAR(order_date), MONTH(order_date), MONTHNAME(order_date))
SELECT 
    sales_year, 
    sales_month_name, 
    ROUND(total_monthly_sales, 2) AS current_month_sales, 
    ROUND(prev_month_sales, 2) AS previous_month_sales,
    CASE 
        WHEN total_monthly_sales > prev_month_sales THEN 'UP'
        ELSE 'DOWN'
    END AS mom_revenue_growth
FROM monthly_sales;

-- Q14. Seasonal Demand Spikes per Menu Category
-- Groups dish demand across Spring, Summer, and Winter seasons to aid inventory forecasting.
WITH seasonal_orders AS (
    SELECT 
        order_item,
        CASE 
            WHEN MONTH(order_date) BETWEEN 4 AND 6 THEN 'Spring'
            WHEN MONTH(order_date) BETWEEN 7 AND 9 THEN 'Summer'
            ELSE 'Winter'
        END AS demand_season,
        order_id
    FROM Orders)
SELECT 
    order_item,
    demand_season,
    COUNT(order_id) AS total_orders
FROM seasonal_orders
GROUP BY order_item, demand_season
ORDER BY order_item, total_orders DESC;