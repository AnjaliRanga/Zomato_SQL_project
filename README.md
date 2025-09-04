# SQL Project: Data Analysis for Zomato  

## 📌 Overview  
This project demonstrates my SQL problem-solving skills through the analysis of Zomato data, a popular food and restaurant platform.  
It involves setting up the database, importing data, cleaning null values, and solving a variety of business problems using SQL queries.  

## 🗂️ Project Structure  
-**Database Setup**: Created zomato_db with required tables.
-**Data Import**: Inserted sample dataset into the database.
-**Data Cleaning**: Handled null values and ensured data integrity.
-**Business Queries**: Solved 20 real-world business queries such as restaurant insights, cuisine trends, cost analysis, and ratings distribution using SQL.

## 🛠️ Database Setup  
```sql
CREATE DATABASE zomato_db;
```

### 1️⃣ Dropping Existing Tables
```sql
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS riders;
DROP TABLE IF EXISTS deliveries;
```
###  2️⃣ Creating Tables
```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(25),
    reg_date DATE
);

CREATE TABLE restaurants (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(55),
    city VARCHAR(15),
    opening_hours VARCHAR(55)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_item VARCHAR(55),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(25),
    total_amount FLOAT
);

-- Foreign Key Constraints
ALTER TABLE orders 
ADD CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE orders 
ADD CONSTRAINT fk_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id);

CREATE TABLE riders (
    rider_id INT PRIMARY KEY,
    rider_name VARCHAR(55),
    sign_up DATE
);

CREATE TABLE deliveries (
    delivery_id INT PRIMARY KEY,
    order_id INT,
    delivery_status VARCHAR(35),
    delivery_time TIME,
    rider_id INT,
    CONSTRAINT fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_riders FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);
```

## 🍴 Food Delivery Business SQL Case Study

This repository contains SQL queries that solve a variety of business problems for a food delivery platform.  
The queries cover **customer analytics, restaurant performance, rider efficiency, and sales trends**.  

## 📌 Business Problems Solved

### 1. Most Frequently Ordered Dishes
**Question:** Find the top 5 most frequently ordered dishes by a specific customer in the last 1 year.
```sql
SELECT 
   customer_name,
   dishes,
   total_orders
FROM
    (
       SELECT 
       c.customer_id ,
       c.customer_name,
	     o.order_item as dishes,
       COUNT(*) as total_orders 
       FROM orders as o 
       JOIN customers as c
       ON  c.customer_id = o.customer_id
       WHERE  o.order_date >= CURRENT_DATE - INTERVAL '1 year'
       AND   c.customer_name = 'Shreya Yadav'
       GROUP BY 1,2,3
       ORDER BY 1,4 DESC
   ) as t1
```

### 2. Popular Time Slots
**Question:** Identify time slots (2-hour intervals) during which most orders are placed.

### APPROACH 1
 ```sql
SELECT 
   CASE
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
       WHEN EXTRACT (HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
   END AS time_slot ,
COUNT(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;
```

### APPROACH 2
```sql
SELECT 
	FLOOR(EXTRACT (HOUR FROM order_time)/2)*2 as start_time,
	FLOOR(EXTRACT (HOUR FROM order_time)/2)*2 + 2 as end_time,
	COUNT(*) AS total_orders
FROM orders
GROUP BY 1,2
ORDER BY 3 DESC
```

### 3. Average Order Value (AOV)
**Question:** Find the average order value per customer who has placed more than 750 orders.
```sql
SELECT 
   c.customer_name,
   AVG(o.total_amount) AS aov
FROM orders as o 
   JOIN customers as c
   ON c.customer_id = o.customer_id
GROUP BY 1
HAVING COUNT(order_id) > 4
```

### 4. High-Value Customers
**Question:** List customers who have spent more than 10000 on food orders.
```sql
SELECT 
   c.customer_name,
   SUM(o.total_amount) AS total_spent
FROM orders as o 
     JOIN customers as c
	 ON c.customer_id = o.customer_id
GROUP BY 1
HAVING SUM(o.total_amount) > 10000
```

### 5. Orders Without Delivery
**Question:** Find orders that were placed but not delivered, grouped by restaurant and city.
### APPROACH 1
```sql
SELECT 
    r.restaurant_name,
	  r.city,
	  COUNT(o.order_id) AS cnt_not_delivered_orders
FROM orders as o
LEFT JOIN restaurants as r
ON r.restaurant_id = o.restaurant_id
LEFT JOIN deliveries AS d
ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY 1,2
ORDER BY 2 DESC
```

### APPROACH 2
 ```sql
SELECT 
    r.restaurant_name,
   	r.city,
	  COUNT(o.order_id) AS cnt_not_delivered_orders
FROM orders as o
LEFT JOIN restaurants as r
ON r.restaurant_id = o.restaurant_id
WHERE o.order_id NOT IN ( SELECT order_id FROM deliveries) 
GROUP BY 1,2
ORDER BY 2 DESC
```

### 6. Restaurant Revenue Ranking
**Question:** Rank restaurants by their total revenue from the last year, within each city.
```sql
WITH ranking_table 
AS 
(
  SELECT
    r.city,
    r.restaurant_name,
    SUM(o.total_amount) AS revenue, 
    RANK() OVER(PARTITION BY r.city ORDER BY  SUM(o.total_amount) DESC) as rank
  FROM orders as o
  JOIN restaurants as r
  ON r.restaurant_id = o.restaurant_id
  WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 Year'
  GROUP BY 1,2
)
SELECT *
FROM ranking_table 
WHERE rank = 1
```

### 7. Most Popular Dish by City
**Question:** Identify the most popular dish in each city.
```sql
SELECT *
FROM
(
  SELECT 
     r.city,
	   o.order_item AS dish,
	   COUNT(order_id) AS total_orders,
	   RANK() OVER(PARTITION BY r.city ORDER BY  COUNT(order_id) DESC) as rank
   FROM orders as o
   JOIN restaurants as r
    ON r.restaurant_id = o.restaurant_id
	GROUP BY 1,2
 ) AS t1
 WHERE rank = 1

```

### 8. Customer Churn
**Question:** Find customers who ordered in **2025** but not in **2024**.
```sql
SELECT DISTINCT customer_id FROM orders
WHERE
       EXTRACT (YEAR FROM order_date)  = 2025
       AND
	   customer_id NOT IN
	              ( SELECT DISTINCT customer_id FROM orders
                   WHERE EXTRACT (YEAR FROM order_date)  = 2024 )

```

### 9. Cancellation Rate Comparison
**Question:** Compare order cancellation rates for each restaurant between the current year and the previous year.
```sql
WITH cancel_ratio_2023
AS
   (
      SELECT 
	    o.restaurant_id,
	    COUNT(o.order_id) as total_orders,
	    COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) not_delivered
      FROM orders as o
	  LEFT JOIN deliveries as d
	  ON o.order_id = d.order_id
	  WHERE EXTRACT (YEAR FROM order_date)  = 2023
	  GROUP BY 1
   ),
cancel_ratio_2024
AS
   (
      SELECT 
	    o.restaurant_id,
	    COUNT(o.order_id) as total_orders,
	    COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) not_delivered
      FROM orders as o
	  LEFT JOIN deliveries as d
	  ON o.order_id = d.order_id
	  WHERE EXTRACT (YEAR FROM order_date)  = 2024
	  GROUP BY 1
   ),
last_year_data
AS(
     SELECT 
       restaurant_id,
       total_orders,
       not_delivered,
       ROUND( not_delivered::numeric / total_orders:: numeric * 100 ,2 ) AS  cancel_ratio 
     FROM cancel_ratio_2023
   ),
current_year_data
AS(
     SELECT 
       restaurant_id,
       total_orders,
       not_delivered,
       ROUND( not_delivered::numeric / total_orders:: numeric * 100 ,2 ) AS  cancel_ratio 
     FROM cancel_ratio_2024
   )

SELECT 
    c.restaurant_id as restaurant_id,
	  c.cancel_ratio as current_year_cancel_ratio,
    l.cancel_ratio as last_year_cancel_ratio
FROM current_year_data AS c
JOIN  last_year_data AS l
ON c.restaurant_id = l.restaurant_id;
```

### 10. Rider Average Delivery Time
**Question:** Determine each rider's average delivery time.
```sql
SELECT 
  o.order_id,
	o.order_time,
	d.delivery_time,
	d.rider_id,
	d.delivery_time - o.order_time AS time_difference,
	EXTRACT ( EPOCH FROM(d.delivery_time - o.order_time + 
	          CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
	          INTERVAL ' 0 day' END ))/60  AS time_difference_insec
FROM orders as o
JOIN deliveries as d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';
```

### 11. Monthly Restaurant Growth Ratio
**Question:** Calculate each restaurant's monthly growth ratio based on delivered orders.
```sql
WITH growth_ratio
AS (
    SELECT 
       o.restaurant_id,
	     TO_CHAR(o.order_date , 'mm-yy') as month,
	     COUNT(o.order_id) as current_month_orders,
	     LAG( COUNT(o.order_id) ,1) OVER (PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date , 'mm-yy'))
		    AS prev_month_orders
     FROM orders as o
     JOIN deliveries as d
     ON o.order_id = d.order_id
     WHERE d.delivery_status = 'Delivered'
     GROUP BY 1,2
     ORDER BY 1,2
    )
SELECT
    restaurant_id,
	  month,
	  prev_month_orders,
	  current_month_orders,
	  ROUND((current_month_orders::numeric - prev_month_orders::numeric)/prev_month_orders::numeric *100,2)
	  as growth_ratio
FROM growth_ratio

```

### 12. Customer Segmentation
**Question:** Segment customers into **Gold** (above AOV spenders) and **Silver** groups.  Report total orders and revenue per segment.
```sql
SELECT
   customer_category,
	SUM(total_orders) as total_orders,
	SUM(total_spent) as total_revenue
FROM 
    (
      SELECT 
	      customer_id,
	      SUM(total_amount) as total_spent,
	      COUNT(order_id) as total_orders,
        CASE 
        WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
         ELSE 'Silver'
		    END AS customer_category
	  FROM orders
	  GROUP BY 1
     ) AS t1
GROUP BY 1	 
```

### 13. Rider's Monthly Earnings
**Question:** Calculate monthly rider earnings (assuming 8% commission per order).
```sql
SELECT 
   d.rider_id,
	TO_CHAR(o.order_date , 'mm-yy') as month,
	SUM(total_amount) as revenue,
	SUM(total_amount)*0.08 as rider_earning
FROM orders as o
JOIN deliveries as d
ON o.order_id = d.order_id
GROUP BY 1,2
ORDER BY 1,2	
```

### 14. Rider Rating Analysis
**Question:** Assign riders ratings based on delivery speed:
  - ⭐⭐⭐⭐⭐ → < 15 minutes  
  - ⭐⭐⭐⭐ → 15–20 minutes  
  - ⭐⭐⭐ → > 20 minutes  
```sql
SELECT 
    rider_id,
  	stars,
	  COUNT(*) AS total_stars
FROM 
    (
	SELECT
	    rider_id,
		 delivery_took_time,
		 CASE 
		  WHEN delivery_took_time < 15 THEN '5-star'
		  WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4-star'
		  ELSE  '3-star'
		 END AS stars
	FROM
	    (
			SELECT 
        o.order_id,
				o.order_time,
				d.delivery_time,
				d.rider_id,
				d.delivery_time - o.order_time AS time_difference,
				EXTRACT ( EPOCH FROM(d.delivery_time - o.order_time + 
				          CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
				          INTERVAL '0 day' END ))/60  AS delivery_took_time
			FROM orders as o
			JOIN deliveries as d
			ON o.order_id = d.order_id
			WHERE d.delivery_status = 'Delivered'	    
	     ) AS t1
	) AS t2 
GROUP BY 1,2
ORDER BY 1,3 DESC	
```

### 15. Order Frequency by Day
**Question:** Analyze order frequency by day of the week. Identify the peak day for each restaurant.
```sql
SELECT *
FROM
(
  SELECT 
        r.restaurant_name,
	      TO_CHAR(o.order_date, 'Day') AS day,
	      COUNT(o.order_id) AS total_orders,
	      RANK() OVER(PARTITION BY r.restaurant_name ORDER BY  COUNT(order_id) DESC) as rank
  FROM orders as o
  JOIN restaurants as r
  ON r.restaurant_id = o.restaurant_id
	GROUP BY 1,2
	ORDER BY 1,3 DESC
 ) AS t1
 WHERE rank=1
```

### 16. Customer Lifetime Value (CLV)
**Question:** Calculate the total revenue generated by each customer.
```sql
SELECT 
   o.customer_id,
	 c.customer_name,
	 SUM(o.total_amount) AS CLV
FROM orders as o
JOIN customers as c
ON o.customer_id = c.customer_id
GROUP BY 1,2
```

### 17. Monthly Sales Trend
**Question:** Compare each month’s total sales with the previous month.
```sql
SELECT 
   EXTRACT (YEAR FROM order_date) AS year,
   EXTRACT (MONTH FROM order_date) AS month,
   SUM(total_amount) as total_sale,
   LAG(SUM(total_amount),1) OVER(ORDER BY EXTRACT (YEAR FROM order_date),EXTRACT (MONTH FROM order_date) ) 
   AS prev_month_sale
FROM orders
GROUP BY 1,2
```

### 18. Rider Efficiency
**Question:** Evaluate riders’ average delivery time and identify fastest/slowest.
```sql
WITH delivery_table
AS 
   (
	SELECT 
	    d.rider_id as riders_id,
	    EXTRACT ( EPOCH FROM(d.delivery_time - o.order_time + 
		  CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
		  INTERVAL ' 0 day' END ))/60  AS time_deliver
	FROM orders as o
	JOIN deliveries as d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'Delivered'
    ),

Riders_time 
AS (
	SELECT 
	    riders_id,
	  	AVG(time_deliver) AS avg_time
	FROM delivery_table
	GROUP BY 1
    )

SELECT 
    MIN(avg_time),
	  MAX(avg_time)
FROM Riders_time 
```

### 19. Order Item Popularity
**Question:** Track item popularity across **seasons** (Spring, Summer, Winter).
```sql
SELECT 
    order_item,
  	seasons,
	  COUNT(order_id) as total_orders
FROM  
  (
	SELECT
	     *,
	     EXTRACT (MONTH FROM order_date) AS month,
	     CASE 
		   WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
       WHEN EXTRACT(MONTH FROM order_date) > 6 AND
        EXTRACT(MONTH FROM order_date) < 9 THEN 'Summer'
				ELSE 'Winter'
		    END as seasons
	FROM orders
   ) AS t1
GROUP BY 1,2
ORDER BY 1,3 DESC
```

### 20. City Revenue Ranking
**Question:** Rank each city by total revenue for **2023**.
```sql
SELECT 
     r.city,
     SUM(total_amount) AS total_revenue,
	   RANK() OVER(ORDER BY SUM(total_amount) DESC) as city_rank
FROM orders as o
JOIN restaurants as r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1
```

## 🚀 Key Learnings  
- Designing relational databases with constraints.  
- Writing optimized SQL queries with **joins, aggregations, window functions, and CTEs**.  
- Handling NULL values and ensuring data integrity.  
- Deriving **business insights** from structured data.  
- Applying SQL to solve **real-world food delivery problems**.  



