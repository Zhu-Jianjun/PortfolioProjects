USE SalesCustomer;
-- Data Exploration:
SELECT * FROM customer;
SELECT * FROM sales;

#1. w/ sales data, one row per invoid_no or multiple?
SELECT invoice_no, COUNT(*) AS count
FROM sales
GROUP BY invoice_no
HAVING count > 1;
# none -> no duplicates


-- Data Cleaning
#2. join two tables
CREATE VIEW salescustomer AS
SELECT
	c.customer_id, c.gender, c.age, c.payment_method,  
    s.category, s.quantity, s.price, s.quantity * s.price AS total_price, s.invoice_date, s.shopping_mall
FROM customer AS c
INNER JOIN sales AS s
ON c.customer_id = s.customer_id;

#found invoice_date is not in DATE format
ALTER TABLE salescustomer
ADD COLUMN invoice_date_converted DATE 
AFTER invoice_date;
#Error Code: 1347. 'salescustomer.salescustomer' is not BASE TABLE 
#cannot directly alter the VIEW using the ALTER TABLE statement, have to recreate the view with the additional column.

CREATE OR REPLACE VIEW salescustomer AS
SELECT
	c.customer_id, c.gender, c.age, c.payment_method,  
    s.category, s.quantity, s.price, s.quantity * s.price AS total_price, s.invoice_date, s.shopping_mall,
    STR_TO_DATE(s.invoice_date, '%d-%m-%Y') AS invoice_date_converted
FROM customer AS c
INNER JOIN sales AS s
ON c.customer_id = s.customer_id;

SELECT * FROM salescustomer
WHERE total_price IS NULL;


-- Data Queries
#1. What is the total revenue generated in the year 2022?
SELECT invoice_date_converted FROM salescustomer;
SELECT MAX(invoice_date_converted), MIN(invoice_date_converted) FROM salescustomer;

SELECT * FROM salescustomer;
SELECT ROUND(SUM(total_price), 2) AS total_revenue
FROM salescustomer
WHERE YEAR(invoice_date_converted) = 2022;

#2. What is the most popular product category in terms of sales?
SELECT category, SUM(quantity) AS total_quantity 
FROM salescustomer
GROUP BY category
ORDER BY total_quantity DESC;

#3. What are the three top shopping malls in terms of sales revenue?
SELECT shopping_mall, ROUND(SUM(total_price), 1) AS total_revenue
FROM salescustomer
GROUP BY shopping_mall
ORDER BY total_revenue DESC
LIMIT 3;

#4. What is the gender distribution across different product categories?
SELECT category, gender, COUNT(*) AS count
FROM salescustomer
GROUP BY category, gender
ORDER BY category;

#5. What is the age distribution of customers who prefer each payment method?
SELECT * FROM salescustomer;
SELECT DISTINCT payment_method FROM salescustomer;
SELECT MAX(age), MIN(age) FROM salescustomer;

SELECT 
	CASE
		WHEN age BETWEEN 0 AND 16 THEN '0-16'
        WHEN age BETWEEN 17 AND 65 THEN '17-65'
        WHEN age > 66 THEN '66-'
		ELSE 'others'
    END AS age_distribution,
    payment_method,
    COUNT(*) AS count
FROM salescustomer
GROUP BY age_distribution, payment_method
ORDER BY age_distribution;





