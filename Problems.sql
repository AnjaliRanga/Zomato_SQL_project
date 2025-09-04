SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

-- Import datasets

-- Handling Null values
SELECT COUNT(*) FROM restaurants
where 
   restaurant_name IS NULL 
   or 
   city IS NULL 
   or 
   opening_hours IS NULL;


-- if there is any null value than how to insert values

-- INSERT INTO orders (order_id, customer_id , restaurant_id)
-- values 
-- (1002,10,54),
-- (1005,15,57),
-- (1007,20,60)


-- Analysis and Repoert 


-- Q1. Write a Query to find the top 5 most frequenty orderd dishes by customer called "Priya Saxena" 
       -- in the last 1 year.

SELECT 
   customer_name,
   dishes,
   total_orders
FROM
  (SELECT 
       c.customer_id ,
       c.customer_name,
	   o.order_item as dishes,
       COUNT(*) as total_orders 
       -- DENSE_RANK OVER(ORDER BY COUNT(*) DESC) as rank
  FROM orders as o 
  JOIN 
    customers as c
  ON   
    c.customer_id = o.customer_id
  WHERE
     o.order_date >= CURRENT_DATE - INTERVAL '1 year'
  AND  
     c.customer_name = 'Shreya Yadav'
  GROUP BY 1,2,3
  ORDER BY 1,4 DESC ) as t1
-- WHERE rank <= 5


-- Popular Time Slots
-- Q2. Identify the time slots during wich the most orders are placed. based on 2hr interval. 

 -- APPROACH 1
 
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

-- SELECT 00:59:59AM --- 0
-- SELECT 01:59:59AM --- 1 

-- APPROACH 2

SELECT 
	FLOOR(EXTRACT (HOUR FROM order_time)/2)*2 as start_time,
	FLOOR(EXTRACT (HOUR FROM order_time)/2)*2 + 2 as end_time,
	COUNT(*) AS total_orders
FROM orders
GROUP BY 1,2
ORDER BY 3 DESC


 ---Order Value Analysis
-- Question 3. Find the average order value per customer who has placed more than 4 orders.
 -- Return customer name , AOV (average order value)

SELECT 
   -- o.customer_id ,
   c.customer_name,
   AVG(o.total_amount) AS aov
   -- COUNT(order_id) AS total_orders
FROM orders as o 
     JOIN customers as c
	 ON c.customer_id = o.customer_id
GROUP BY 1
HAVING COUNT(order_id) > 4


---High Value Customers
-- Question 4.List the customers who have spent more than 1000 in total on food orders.
 -- Return customer name , and customer_id
 
SELECT 
   c.customer_name,
   SUM(o.total_amount) AS total_spent
FROM orders as o 
     JOIN customers as c
	 ON c.customer_id = o.customer_id
GROUP BY 1
HAVING SUM(o.total_amount) > 1000


--- Orders Without Delivery
-- Question 5. Write a query to find orders that were placed but not delivered. 
-- Return each resturant name , city and number of not deliverd orders 
 
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

 -- OR 
 
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


-- Restaurant Revenue Ranking
-- Question 6. Rank restaurants by their total revenue from the last  year ,including names.
-- total revenue and rank within their city.

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


-- Most Popular Dish By City
-- Question 7. Identify the most popular dish in each city based on the number of orders.

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


-- Customer Churn
-- Question 8. Find customers who have not placed an order in 2024 but did in 2025.

-- find customers who has orders in 2025
-- find customers who has not done orders in 2024.
-- Compare 1 and 2

SELECT DISTINCT customer_id FROM orders
WHERE
       EXTRACT (YEAR FROM order_date)  = 2025
       AND
	   customer_id NOT IN
	              ( SELECT DISTINCT customer_id FROM orders
                   WHERE EXTRACT (YEAR FROM order_date)  = 2024 )



-- Cancellation rate comparision
-- Question 9. Calculate and compare the order cancellation rate for each restaurant 
--             between the current year and the previous year.

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


-- Rider Average Delivery Time
-- Question 10. Determine each rider's average delivery time.

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


-- Monthly Restaurant Growth Ratio
-- Question 11. Calculate each restaurant's growth ratio based on the total number of delivered orders
                -- since its joining.

-- last month sale ,lms =20
-- current month sale ,cms = 30
-- cms - lms/lms
-- 30 - 20/20 *100

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


-- Customer Segmentation
-- Question 12. Customer Segmentation: Segment customers into 'Gold' or 'Silver' Groups based on their total spending
--              compared to average order value (AOV). If a customer's total spending exceeds AOV,
--              Label them as 'Gold' otherwise label them as 'silver'. Write an SQL query to determine each segment's
--              total number of orders and total revenue.

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


-- Rider's Monthly Earnings
-- Question 13. Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
              
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


-- Rider's Rating Analysis
-- Question 14. Find the number of 5-star,4-star,3-star rating each rider has.
-- Rider receive this rating based on the delivery time.
-- If orders are delivered in less than 15 min of order received time the rider get 5-star rating.
-- If they deliver in 15-20 min they get 4-star rating.
-- If they deliver after 20 min they get 3-star rating.

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


-- Order Frequency by day
-- Question 15. Analyze order frequency by day of the week and 
--              identify the peak day for each restaurant.

SELECT *
FROM
(
  SELECT 
     r.restaurant_name,
	 -- o.order_date,
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
 

-- Customer Lifetime Value (CLV)
-- Question 16. Calculate total revenue generated by each cutomer over all their orders.

SELECT 
     o.customer_id,
	 c.customer_name,
	 SUM(o.total_amount) AS CLV
FROM orders as o
JOIN customers as c
ON o.customer_id = c.customer_id
GROUP BY 1,2


-- Monthly Sales Trend
-- Question 17. Identify sales trend by comparing each month's total sales to the previous month.

SELECT 
   EXTRACT (YEAR FROM order_date) AS year,
   EXTRACT (MONTH FROM order_date) AS month,
   SUM(total_amount) as total_sale,
   LAG(SUM(total_amount),1) OVER(ORDER BY EXTRACT (YEAR FROM order_date),EXTRACT (MONTH FROM order_date) ) 
   AS prev_month_sale
FROM orders
GROUP BY 1,2


-- Rider Efficiency
-- Question 18. Evaluate rider efficiency by determining average delivery time and
--              identifing those with the lowest and highest averages.

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


-- Order Item Popularity
-- Question 19. Track the popularity of specific order items over time and identify seasonal demand spikes.

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


-- Question 20. Rank each city based on the total revenue for the year 2023. 

SELECT 
     r.city,
     SUM(total_amount) AS total_revenue,
	 RANK() OVER(ORDER BY SUM(total_amount) DESC) as city_rank
FROM orders as o
JOIN restaurants as r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1

























