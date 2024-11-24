
-------------------------
-- EMPLOYEE PERFORMANCE
-------------------------
-- Q1) Which employees have performed the best in terms of sales

-- Save as view
CREATE VIEW public.employee_performance AS
-- Create table with each employee and their manager
WITH employee_manager AS ( 
SELECT e1.employee_id, 
	   e1.first_name || ' ' || e1.last_name AS employee_name, 
	   e1.title,
	   e1.reports_to,
	   e1.country,
	   e2.first_name || ' ' || e2.last_name AS manager_name
FROM employees AS e1
-- Self join of employees table to link employees to managers
LEFT JOIN employees AS e2 ON e1.reports_to = e2.employee_id
),

employee_orders AS (
    SELECT em.employee_id, 
    em.employee_name, 
    em.title, 
    em.reports_to,
    em.manager_name,
    em.country,
    o.order_id,
    -- Calculate revenue generated per order
    (od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount) AS product_order_revenue -- Assumes single discount applied over whole order
    FROM employee_manager em
    -- Join order info (employee responsibly for each order)
    LEFT JOIN orders AS o ON em.employee_id = o.employee_id
    -- Join order details (quantity, price and discount)
    LEFT JOIN order_details AS od ON o.order_id = od.order_id
)

SELECT eo.employee_id, 
       eo.employee_name, 
       eo.title, 
       eo.manager_name,
       eo.country,
       -- Calculate total revenue generated from all orders from a given employee
       ROUND(SUM(product_order_revenue)) AS total_rev, 
       -- Calculate average revenue per order genreated by an individual employee
       ROUND(SUM(product_order_revenue)/COUNT(DISTINCT eo.order_id)) AS avg_rev,
       -- Count total number of orders per employee
       COUNT(eo.order_id) AS n_sales
FROM employee_orders eo
GROUP BY eo.employee_id, eo.employee_name, eo.title, eo.manager_name, eo.country;


-- Use window function to rank employees within each country by their average revenue generated per order
SELECT *, RANK() OVER(PARTITION BY country ORDER BY total_rev DESC) AS country_rank
FROM employee_performance AS ep
ORDER BY country_rank;

---------------------------------------------
-- PRODUCT REVENUE & CATEGORY PERFORMANCE
---------------------------------------------

-- Q2) Which products and categories are sold most often? 
-- Q3) Which products and categories generate the most revenue?

/* 
Join orders, order_details, products, categories
Explore resulting table
	- Allows us to see info on unit price, qunatity per unit, quantity sold and discounts given 
*/

-- Select all columns & calculate revenue from each order
SELECT *, ROUND(((od.unit_price*od.quantity) - (od.unit_price*od.quantity*od.discount))::numeric,2) AS order_revenue
FROM orders AS o
JOIN order_details AS od ON o.order_id = od.order_id 
JOIN products AS p ON od.product_id = p.product_id 
JOIN categories AS c ON p.category_id = c.category_id;

-- Save view containing all relevant info for order, product and category quantities 
CREATE VIEW public.order_product_category AS 
-- Specifiies and renames certain columns to avoid ambiguitty when selecting from it in future queries
SELECT o.order_id AS o_order_id, o.customer_id, o.employee_id, o.order_date, o.required_date, o.shipped_date, o.ship_via, o.freight,
	   o.ship_name, o.ship_address, o.ship_city, o.ship_region, o.ship_postal_code, o.ship_country,
	   od.product_id AS od_product_id, od.unit_price, od.quantity, od.discount,
	   p.category_id AS p_category_id, p.product_name, p.supplier_id, p.category_id, p.quantity_per_unit, p.units_in_stock, p.units_on_order,
	   p.reorder_level, p.discontinued,
	   c.category_name, c.description,
	   -- Calculate the revenue from each order
	   ROUND(((od.unit_price*od.quantity) - (od.unit_price*od.quantity*od.discount))::numeric,2) AS order_revenue
FROM orders AS o
/*
 Use inner joins to keep only matching records between tables
We only want to select info about orders that have the needed details (unit_price, quantity, etc.)
*/
JOIN order_details AS od ON o.order_id = od.order_id 
JOIN products AS p ON od.product_id = p.product_id 
JOIN categories AS c ON p.category_id = c.category_id;


/* 
 Calculate total revenue, number of orders, average revenue and product rank for each product
 Generate table with:
	- Aggregate functions for times product ordered, total revenue generated from product and average revenue generated per order of product
	- Window functions showing rank of product within its category for total revenue, times ordered and average revenue
Save as view 
*/

CREATE VIEW public.products_catrank AS
SELECT product_name, category_name, description,
	   -- Sum product revenue from each time it was ordered to calculate total revenue from product
	   SUM(order_revenue) AS total_product_rev,
	   -- Window function to assign relative rank to each product within a category by total revenue generated 
	   RANK() OVER(PARTITION BY category_name ORDER BY SUM(order_revenue) DESC) AS catrank_totalrev,
	   -- Count number of times each product was ordered
	   COUNT(order_date) AS n__product_ordered,
	   -- Window function to assign relative rank to each product within a category by number of times it was ordered
	   RANK() OVER(PARTITION BY category_name ORDER BY COUNT(order_date) DESC) AS catrank_n_ordered,
	   -- Calculate the average reveneu generated per time each product was ordered
	   ROUND((SUM(order_revenue)/COUNT(order_date)),2) AS avg_rev_product_order,
	   -- Window function to assign relative rank to each product within a category by the average revenue generated per time it was ordered
	   RANK() OVER(PARTITION BY category_name ORDER BY ROUND((SUM(order_revenue)/COUNT(order_date)),2) DESC) AS catrank_avgrev
-- Selects from previously created view
FROM order_product_category AS opc 
GROUP BY product_name, category_name, description;


-- Use products_catrank view to find top 3 products overall by each metric */

/* 
 Select top 3 products overall from products_catrank view by :
	- total revenue generated
	- number of times ordered
	- average revenue generated
Use union to stack all results
*/
(
SELECT product_name, category_name, total_product_rev, n__product_ordered, avg_rev_product_order
FROM products_catrank
ORDER BY total_product_rev DESC
LIMIT 3
)

/*
 Use UNION to ensure that duplicate entries are removed
Products that occur in the top 3 by more than one metric will only be listed once
*/
UNION

(
SELECT product_name, category_name, total_product_rev, n__product_ordered, avg_rev_product_order
FROM products_catrank
ORDER BY n__product_ordered DESC 
LIMIT 3
)

UNION

(
SELECT product_name, category_name, total_product_rev, n__product_ordered, avg_rev_product_order
FROM products_catrank
ORDER BY avg_rev_product_order DESC 
LIMIT 3
);

-- Use products_catrank view to find top product within each category by each metric

-- Select only necessary columns from products_catrank view
WITH ranked_products AS (
    SELECT 
        category_name,
        product_name,
        catrank_totalrev,
        catrank_n_ordered,
        catrank_avgrev
    FROM products_catrank
),
-- Use previous CTE to select only products with the top rank in each metric
top_products AS (
    SELECT
        category_name,
        MAX(CASE WHEN catrank_totalrev = 1 THEN product_name END) AS top_product_by_totalrev,
        MAX(CASE WHEN catrank_n_ordered = 1 THEN product_name END) AS top_product_by_norders,
        MAX(CASE WHEN catrank_avgrev = 1 THEN product_name END) AS top_product_by_avgrev
    FROM ranked_products
    GROUP BY category_name
)
-- Output final table of only top product names and their category
SELECT category_name, 
       top_product_by_totalrev, 
       top_product_by_norders,
       top_product_by_avgrev
FROM top_products;

/* 
Generate table with:
 - number of orders per category
 - total revenue generated per category and average revenue generated per category order 
 */

SELECT category_name, description,
	   COUNT(order_date) AS n_orders,
	   SUM(order_revenue) AS total_cat_rev, 
	   -- Calculate average revenue generated per order in each category
       ROUND((SUM(order_revenue)/COUNT(order_date)),2) AS avg_cat_rev
FROM order_product_category AS opc 
GROUP BY category_name, description
ORDER BY total_cat_rev DESC;


-----------------
-- SALES TRENDS
-----------------

-- Q4) Which periods of the year account for highest and lowest revenue?

-- Save view that calculates number of orders, total revenue generated and revenue rank per month
CREATE VIEW public.orders_over_time AS 
SELECT EXTRACT(YEAR FROM(o.order_date)) AS order_year, 
	   EXTRACT(MONTH FROM(o.order_date)) AS order_month, 
	   COUNT(o.order_id) AS n_orders, 
	   -- Calculate total revenue per month
	   ROUND(SUM((od.unit_price*od.quantity)-(od.quantity*od.unit_price*od.discount))::numeric,2) AS total_revenue,
	   -- Use window function calculate percentile rank for revenue total
	   ROUND(PERCENT_RANK() OVER(ORDER BY ROUND(SUM((od.unit_price*od.quantity)-(od.quantity*od.unit_price*od.discount))::numeric,2) ASC)::numeric,2) AS revenue_percent_rank
FROM orders AS o
LEFT JOIN order_details AS od ON o.order_id = od.order_id
-- Group data by year and month
GROUP BY EXTRACT(YEAR FROM(o.order_date)), EXTRACT(MONTH FROM(o.order_date))
ORDER BY order_year, order_month;


-- Find months above the 75th percentile in terms of revenue
SELECT *
  FROM orders_over_time
 WHERE revenue_percent_rank > 0.75
 ORDER BY order_year, order_month;

-- Find months below the 25th percentile in terms of revenue
SELECT *
  FROM orders_over_time
 WHERE revenue_percent_rank < 0.25
 ORDER BY order_year, order_month;

-------------------------------
-- CUSTOMER PURCHASE BEHAVIOR
-------------------------------
-- Q6) Which customers return most often?

-- Find top customers by total number of orders placed 
SELECT o.customer_id AS customer_id, 
	   c.company_name AS company_name, 
	   COUNT(order_id) AS n_orders
FROM orders AS o
-- Join customers table for company names
JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.company_name
ORDER BY n_orders DESC
-- Look at top 10 customers
LIMIT 10;


-- Q7) What is the average number of items per order?

-- Find average number of items per order overall 

-- CTE for calculating total number of unique products per order_id
WITH products_per_order AS (
SELECT o_order_id AS order_id, 
	   COUNT(od_product_id)  AS n_products
FROM order_product_category opc 
GROUP BY o_order_id
ORDER BY n_products DESC
)

-- Calculate average number of products per order overall
SELECT ROUND(AVG(n_products)) AS avg_n_products
FROM products_per_order;

-- Find average number of unique products per order for each customer 

-- CTE for calculating total number of products per order_id
WITH products_per_order AS (
SELECT o_order_id AS order_id, 
	   COUNT(od_product_id) AS n_products
FROM order_product_category opc 
GROUP BY o_order_id
ORDER BY n_products DESC
)
-- Select company information; calculate average number of products per order
SELECT o.customer_id, c.company_name, ROUND((SUM(ppo.n_products)/COUNT(o.order_id)),2) AS avg_products_perorder
FROM orders AS o
-- Join customer information table
JOIN customers AS c ON o.customer_id = c.customer_id
-- Join CTE with number of products per order_id
JOIN products_per_order AS ppo ON o.order_id = ppo.order_id
GROUP BY o.customer_id, c.company_name
ORDER BY avg_products_perorder DESC;


-- Q5) Which products are commonly bought together? 

SELECT p1.product_name AS product_name_1,
	   p2.product_name AS product_name_2,
       COUNT(*) AS times_bought_together
FROM order_details AS od1
-- Self join order_details to get unique combinations of product id's
JOIN order_details AS od2 ON od1.order_id = od2.order_id AND od1.product_id < od2.product_id
-- Join products to od1 to access product name of first product id
JOIN products AS p1 ON od1.product_id = p1.product_id
-- Join products to od2 to access product name of second product id
JOIN products AS p2 ON od2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
-- Look at top 10 combinations
LIMIT 10;




