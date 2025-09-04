-- zomato data analysis using SQL 

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS riders;
DROP TABLE IF EXISTS deliveries;

CREATE TABLE customers (
        customer_id	INT PRIMARY KEY,
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
        customer_id INT ,
        restaurant_id INT ,
        order_item	VARCHAR(55),
        order_date	DATE,
        order_time TIME,
        order_status VARCHAR(25),
        total_amount FLOAT 
		);

-- adding FK constraints
ALTER TABLE orders 
ADD CONSTRAINT fk_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

-- adding FK constraints
ALTER TABLE orders 
ADD CONSTRAINT fk_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(restaurant_id);

CREATE TABLE riders(
        rider_id INT PRIMARY KEY,
		rider_name VARCHAR(55),
		sign_up DATE
		);

CREATE TABLE deliveries (	
       delivery_id INT PRIMARY KEY,
	   order_id	INT,
	   delivery_status VARCHAR(35),
	   delivery_time TIME,
	   rider_id INT ,
	   CONSTRAINT fK_orders FOREIGN KEY (order_id) REFERENCES orders(order_id) ,
	   CONSTRAINT fK_riders FOREIGN KEY (rider_id) REFERENCES riders(rider_id) 
	   );

-- END of schemas
