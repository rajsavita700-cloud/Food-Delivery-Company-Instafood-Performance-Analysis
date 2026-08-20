-- SQL PROJECT: Food Delivery Analytics
-- Instafood: A fictional food delivery company

-- creating new database
CREATE DATABASE IF NOT EXISTS instafood;
USE instafood;

-- dropping existing tables if they exist
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS restaurants, customers, riders, Orders, deliveries;
SET FOREIGN_KEY_CHECKS = 1;

-- creating new tables
CREATE TABLE restaurants(
	restaurant_id SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    opening_hours VARCHAR(50));
    
CREATE TABLE customers(
	customer_id SERIAL PRIMARY KEY,
	customer_name VARCHAR(100) NOT NULL,
	reg_date DATE);
 
CREATE TABLE riders(
	rider_id SERIAL PRIMARY KEY,
	rider_name VARCHAR(100) NOT NULL,
	sign_up DATE); 

CREATE TABLE Orders(
	order_id SERIAL PRIMARY KEY,
    customer_id BIGINT UNSIGNED,
    restaurant_id BIGINT UNSIGNED,
	order_item VARCHAR(255),
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    order_status VARCHAR(20) DEFAULT 'Pending',
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id));
    
CREATE TABLE deliveries(
	delivery_id SERIAL PRIMARY KEY,
    order_id BIGINT UNSIGNED,
    delivery_status VARCHAR(20) DEFAULT 'Pending',
    delivery_time TIME,
    rider_id BIGINT UNSIGNED,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id));
    
-- importing data into customers table
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv"
INTO TABLE customers
fields terminated by ","
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;


-- importing data into restraunts table
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/restaurants.csv"
INTO TABLE restaurants
fields terminated by ","
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

-- importing data into Orders table
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv"
INTO TABLE Orders
fields terminated by ","
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

-- importing data into riders table
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/riders.csv"
INTO TABLE riders
fields terminated by ","
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

-- importing data into deliveries table
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/deliveries.csv"
INTO TABLE deliveries
fields terminated by ","
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

select * from customers;
select * from restaurants;
select * from Orders;
select * from riders;
select * from deliveries;

-- data imported successfully


    
