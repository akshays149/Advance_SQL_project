
--creating a database for project by name 'datawarehouse'
create database Data_warehouse

--creating tables/schemas
CREATE TABLE gold_customers(
	customer_key int,
	customer_id int,
	customer_number varchar(50),
	first_name varchar(50),
	last_name varchar(50),
	country varchar(50),
	marital_status varchar(50),
	gender varchar(50),
	birthdate date,
	create_date date
);

CREATE TABLE gold_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);

CREATE TABLE gold_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity int,
	price int 
);

--Importing data from wizard feature into the tables
select * from gold_customers
select * from gold_products
select * from gold_sales

-------------CHANGE-OVER-TIME ANALYSIS---------------------------
--analyze how a measure evolves over time 
--helps track trends and identify seasonality in your data 

--1. Analyze Sales Over Time 

--BY days
select order_date, sum(sales_amount) as sales_overtime, sum(quantity) as quantity from gold_sales
where order_date is not null
group by order_date																					
order by order_date; 

--BY MONTHS
select MONTH(order_date) AS ORDER_BY_MONTHS, sum(sales_amount) as sales_overtime, sum(quantity) as quantity from gold_sales
where order_date is not null
group by MONTH(order_date)																					
order by MONTH(order_date); 

--BY YEARS
select year(order_date) AS ORDER_BY_year, sum(sales_amount) as sales_overtime, sum(quantity) as quantity from gold_sales
where order_date is not null
group by year(order_date)																					
order by year(order_date); 


---------------CUMULATIVE ANALYSIS---------------------------
--aggregate the data progressivly over time 
--helps to understand whether our business is growing or decling 

--1. Calculates Total Sales Per Month and Running Total Of Sales Over Time.    {months of year sales}
with cte as(			
			select DATEFROMPARTS(year(order_date),MONTH(order_date),1) as month_wise, sum(sales_amount) as month_sales 
			from gold_sales
			where order_date is not null
			group by DATEFROMPARTS(year(order_date),MONTH(order_date),1)
			) 

select month_wise, month_sales, 
sum(month_sales) over ( order by month_wise) as running_total 
from cte;


-------------PERFORMANCE ANALYSIS---------------------------
--comparing the current value to target value  

--1. Analyze The Yearly Performance Of Products By Comparing Thier Sales To Both The Average Sales 
-----Perfomance Of The Product And The Previous Year's Sales                 {year-over-year}
with cte as (select year(order_date) as years, gold_sales.product_key,  gold_products.product_name, 
sum(sales_amount) as current_sales
from gold_sales

left join gold_products
on gold_sales.product_key = gold_products.product_key

where order_date is not null
group by year(order_date),gold_sales.product_key,gold_products.product_name
)

select years,product_key,product_name,current_sales,
avg(current_sales) over (partition by product_name) as avg_sales,
lag(current_sales) over (partition by product_name order by years) as previous_yr_sales
from cte


-----------------------PART-TO-WHOLE ANALYSIS---------------------------
--analyze how an individual part is performing compared to the overall,
--allowing us to understand which category has the biggest impact on the business 

--1. Which Categories Contribute The Most To Overall Sales        {BY Percentage}
with cte as (
			select category, sum(gold_sales.sales_amount) as sales from gold_sales
			left join gold_products
			on gold_sales.product_key = gold_products.product_key
			group by category
			)

select category, sales, 
concat(round(cast(sales as float)/(select sum(sales_amount)from gold_sales)*100,2),'%') as category_perct
from cte


---------------DATA SEGMENTATION---------------------------
--group the data based on specific range 
--helps to understand the correlation between two measures 

--1. Segment Products Into Cost Ranges and 
-----How Many Products Fall Into Each Segment
select segments, count(product_name) as fall
from (
select product_key, product_name, cost,
		CASE 
			when cost < 100                then 'Below 100'
			when cost between 100 and 500  then '100-500'
			when cost between 500 and 1000 then '500-1000'
			else 'Above 1000'
		END as segments
from gold_products
     ) as t1
group by segments


--2. Group customers into three segments based on their spending behavior:
--  - VIP: Customers with at least 12 months of history and spending more than €5,000.
--  - Regular: Customers with at least 12 months of history but spending €5,000 or less.
--  - New: Customers with a lifespan less than 12 months.
-- And find the total number of customers by each group 
with cte as (	
			select c.customer_key, sum(s.sales_amount) as sales,  
			max(s.order_date)as last_order, 
			min(s.order_date)as first_order,
			DATEDIFF(month,min(s.order_date) ,max(s.order_date)) as span
			from gold_customers c
			left join gold_sales s
			on c.customer_key = s.customer_key
			group by c.customer_key
			)

select  count(customer_key),
	CASE 
		when span >=12 and sales >5000              then 'VIP'
		when span >=12 and sales between 0 and 5000 then 'REGULAR'
		else 'new'
	END as rating 
from cte
group by CASE 
		when span >=12 and sales >5000              then 'VIP'
		when span >=12 and sales between 0 and 5000 then 'REGULAR'
		else 'new'
	END 








===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================


CREATE VIEW gold_report_customers AS

WITH base_query AS(
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age
FROM gold_sales f
LEFT JOIN gold_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)

, customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	 WHEN age < 20 THEN 'Under 20'
	 WHEN age between 20 and 29 THEN '20-29'
	 WHEN age between 30 and 39 THEN '30-39'
	 WHEN age between 40 and 49 THEN '40-49'
	 ELSE '50 and above'
END AS age_group,
CASE 
    WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
    WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
    ELSE 'New'
END AS customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products
lifespan,
-- Compuate average order value (AVO)
CASE WHEN total_sales = 0 THEN 0
	 ELSE total_sales / total_orders
END AS avg_order_value,
-- Compuate average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
     ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM customer_aggregation






















































