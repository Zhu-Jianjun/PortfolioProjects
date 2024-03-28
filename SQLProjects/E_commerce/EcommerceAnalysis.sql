-- rename the columns
SELECT * FROM listorders;
SHOW COLUMNS FROM listorders;
ALTER TABLE listorders
CHANGE COLUMN `Order ID` OrderID VARCHAR(25),
CHANGE COLUMN `Order Date` OrderDate VARCHAR(25);

SELECT * FROM orderdetails;
SHOW COLUMNS FROM orderdetails;
ALTER TABLE orderdetails
CHANGE COLUMN `Order ID` OrderID VARCHAR(25),
CHANGE COLUMN `Sub-Category` SubCategory VARCHAR(25);

SELECT * FROM salestarget;
SHOW COLUMNS FROM salestarget;
ALTER TABLE salestarget
CHANGE COLUMN `Month of Order Date` OrderMonth VARCHAR(25);


-- Queries
#1. 
CREATE VIEW list_order_details AS
SELECT 
	o.OrderID, o.Amount, o.Profit, o.Quantity, o.Category, o.SubCategory, 
    l.OrderDate, l.CustomerName, l.State, l.City
FROM orderdetails AS o
INNER JOIN listorders AS l
ON o.OrderID = l.OrderID;

-- segment the customers into group based on RFM model
CREATE VIEW customer_grouping AS
SELECT
*,
CASE
WHEN (R>=4 AND R<=5) AND (((F+M)/2)>=4 AND ((F+M)/2)<=5) THEN 'Champions'
WHEN (R>=2 AND R<=3) AND (((F+M)/2)>=3 AND ((F+M)/2)<=5) THEN 'Loyal Customers'
WHEN (R>=3 AND R<=5) AND (((F+M)/2)>=1 AND ((F+M)/2)<=3) THEN 'Potential Loyalist'
WHEN (R>=4 AND R<=5) AND (((F+M)/2)>=0 AND ((F+M)/2)<=1) THEN 'New Customers'
WHEN (R>=3 AND R<=4) AND (((F+M)/2)>=0 AND ((F+M)/2)<=1) THEN 'Promising'
WHEN (R>=2 AND R<=3) AND (((F+M)/2)>=2 AND ((F+M)/2)<=3) THEN 'Customers Needing Attention'
WHEN (R>=2 AND R<=3) AND (((F+M)/2)>=0 AND ((F+M)/2)<=2) THEN 'About to Sleep'
WHEN (R>=1 AND R<=2) AND (((F+M)/2)>=2 AND ((F+M)/2)<=5) THEN 'At Risk'
WHEN (R>=0 AND R<=1) AND (((F+M)/2)>=4 AND ((F+M)/2)<=5) THEN "Can't Lost Them"
WHEN (R>=1 AND R<=2) AND (((F+M)/2)>=1 AND ((F+M)/2)<=2) THEN 'Hibernating'
WHEN (R>=0 AND R<=2) AND (((F+M)/2)>=0 AND ((F+M)/2)<=2) THEN 'Lost'
END AS customer_segment
FROM (
SELECT
MAX(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS latest_order_date,
CustomerName,
DATEDIFF(STR_TO_DATE('31-03-2019', '%d-%m-%Y'), MAX(STR_TO_DATE(OrderDate, '%d-%m-%Y'))) AS recency,
COUNT(DISTINCT OrderID) AS frequency,
SUM(Amount) AS monetary,
NTILE(5) OVER (ORDER BY DATEDIFF(STR_TO_DATE('31-03-2019', '%d-%m-%Y'), MAX(STR_TO_DATE(OrderDate, '%d-%m-%Y'))) DESC) AS R,
NTILE(5) OVER (ORDER BY COUNT(DISTINCT OrderID) ASC) AS F,
NTILE(5) OVER (ORDER BY SUM(Amount) ASC) AS M
FROM list_order_details
GROUP BY CustomerName)rfm_table
GROUP BY CustomerName;

-- return the number & percentage of each customer segment
SELECT
customer_segment,
COUNT(DISTINCT CustomerName) AS num_of_customers,
ROUND(COUNT(DISTINCT CustomerName) / (SELECT COUNT(*) FROM customer_grouping) *100,2) AS pct_of_customers
FROM customer_grouping
GROUP BY customer_segment
ORDER BY pct_of_customers DESC;


#2. Find the new customers who made purchases in the year 2019. Only shows the top 5 new customers and
#   their respective cities and states. Order the result by the amount they spent.
SELECT * FROM list_order_details;
SELECT
	CustomerName, State, City, SUM(Amount) AS Sales
FROM list_order_details
WHERE CustomerName NOT IN (
	SELECT DISTINCT CustomerName
    FROM list_order_details
    WHERE 
		YEAR(str_to_date(OrderDate, "%d-%m-%Y")) = 2018 OR YEAR(str_to_date(OrderDate, "%m/%d/%Y")) = 18
	)
AND YEAR(str_to_date(OrderDate, "%d-%m-%Y")) = 2019
GROUP BY CustomerName, State, City
ORDER BY Sales desc
LIMIT 5;


#3. Find the top 10 profitable states & cities so that the company can expand its business. Determine the 
#.  number of products sold and the number of customers in these top 10 profitable states & cities.
SELECT
	State, City, COUNT(DISTINCT CustomerName) AS CustomerNumbers,
    SUM(Profit) AS TotalProfit,
    SUM(Quantity) AS TotalQuantity
FROM list_order_details
GROUP BY State, City
ORDER BY TotalProfit DESC
LIMIT 10;


#4. Display the details (in terms of “OrderDate”, “OrderID”, “State”, and “CustomerName”) for the first order 
#.  in each state. Order the result by “OrderID”.
SELECT 
	OrderDate, OrderID, State, CustomerName
FROM (
	SELECT 
		*, 
		ROW_NUMBER() OVER (PARTITION BY State ORDER BY State, OrderID) AS RowNumberPerState
	FROM list_order_details
) AS firstorder
WHERE RowNumberPerState = 1
ORDER BY OrderID;


#5. Determine the number of orders (in the form of a histogram) and sales for different days of the week.
SELECT 
	OrderDay,
    lpad('*', OrdersNumber, '*') AS OrdersNumber,
    Sales
FROM (
	SELECT 
		dayname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS OrderDay,
        COUNT(DISTINCT OrderID) AS OrdersNumber,
        SUM(Quantity) AS Quantity,
        SUM(Amount) AS Sales
	FROM list_order_details
    GROUP BY OrderDay
	) AS SalespERdAY
ORDER BY Sales DESC;


#6. Check the monthly profitability and monthly quantity sold to see if there are patterns in the dataset.
SELECT 
	CONCAT(MONTHNAME(STR_TO_DATE(OrderDate,'%d-%m-%Y')), '-', YEAR(STR_TO_DATE(OrderDate,"%d-%m-%Y"))) AS month_of_year,
	SUM(Profit) AS total_profit, 
    SUM(Quantity) AS total_quantity
FROM list_order_details
GROUP BY month_of_year
ORDER BY 
month_of_year= 'April-2018' DESC,
month_of_year= 'May-2018' DESC,
month_of_year= 'June-2018' DESC,
month_of_year= 'July-2018' DESC,
month_of_year= 'August-2018' DESC,
month_of_year= 'September-2018' DESC,
month_of_year= 'October-2018' DESC,
month_of_year= 'November-2018' DESC,
month_of_year= 'December-2018' DESC,
month_of_year= 'January-2019' DESC,
month_of_year= 'February-2019' DESC,
month_of_year= 'March-2019' DESC;


#7. Determine the number of times that salespeople hit or failed to hit the sales target for each category.
-- find out the sales for each category in each month
CREATE VIEW sales_by_category AS
SELECT 
	CONCAT(SUBSTR(MONTHNAME (STR_TO_DATE(OrderDate, '%d-%m-%y')),1,3),"-",SUBSTR(YEAR(STR_TO_DATE(OrderDate,'%d-%m-%y')),3,2)) AS order_monthyear, 
    Category, 
    SUM(Amount) AS Sales
FROM list_order_details
GROUP BY order_monthyear,Category;

-- check if the sales hit the target set for each category in each month
CREATE VIEW sales_vs_target AS
SELECT 
	*, 
    CASE
		WHEN Sales >= Target THEN 'Hit'
		ELSE 'Fail'
	END AS hit_or_fail
FROM (
	SELECT s.order_monthyear, s.Category, s.Sales, t.Target
	FROM sales_by_category AS s
	INNER JOIN salestarget AS t ON s.order_monthyear = t.OrderMonth AND s.Category = t.Category) st;
    


-- return the number of times that the target is met & the number of times that the target is not met
SELECT h.Category, h.Hit, f.Fail
FROM (
	SELECT Category, COUNT(*) AS Hit
	FROM sales_vs_target
	WHERE hit_or_fail LIKE 'Hit'
	GROUP BY Category) h
INNER JOIN (
	SELECT Category, COUNT(*) AS Fail
	FROM sales_vs_target
	WHERE hit_or_fail LIKE 'Fail'
	GROUP BY Category) f
ON h.Category = f.Category;


#8. Find the total sales, total profit, and total quantity sold for each category and sub-category. 
#  Return the maximum cost and maximum price for each sub-category too.
-- find order quantity, profit, amount for each subcategory
-- electronic games & tables subcategories resulted in loss
CREATE VIEW order_details_by_total AS
SELECT 
	Category, 
    SubCategory,
	SUM(Quantity) AS total_order_quantity,
	SUM(Profit) AS total_profit,
	SUM(Amount) AS total_amount
FROM orderdetails
GROUP BY Category, SubCategory
ORDER BY total_order_quantity DESC;

-- maximum cost per unit & maximum price per unit for each subcategory
CREATE VIEW order_details_by_unit AS
SELECT 
	Category, 
    SubCategory, 
    MAX(cost_per_unit) AS max_cost, 
    MAX(price_per_unit) AS max_price
FROM (
	SELECT *, round((Amount-Profit)/Quantity,2) AS cost_per_unit, round(Amount/Quantity,2) AS price_per_unit
	FROM orderdetails
    )c
GROUP BY Category, SubCategory
ORDER BY max_cost DESC;

-- combine order_details_by_unit table and order_details_by_total table
SELECT t.Category, t.SubCategory, t.total_order_quantity, t.total_profit, t.total_amount, u.max_cost, u.max_price
FROM order_details_by_total AS t
INNER JOIN order_details_by_unit AS u
ON t.SubCategory=u.SubCategory;




