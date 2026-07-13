# Advance_sql_data-analytics_project

<img width="2492" height="1696" alt="Gemini_Generated_Image_jqqs26jqqs26jqqs" src="https://github.com/user-attachments/assets/ee2d0f8f-adb8-4374-9df5-dff1ed48a1b1" />


## Overview
A comprehensive collection of SQL scripts for data exploration, analytics, and reporting. These scripts cover various analyses such as database exploration, measures and metrics, time-based trends, cumulative analytics, segmentation, and more. This repository contains SQL queries designed to help data analysts and BI professionals quickly explore, segment, and analyze data within a relational database. Each script focuses on a specific analytical theme and demonstrates best practices for SQL queries.

## Objectives

The objective of this project is to implement and master advanced analytical workflows within data management systems, focusing on six core pillars of data analytics:

1. Change-Over-Time Analysis: Tracking and modeling historical trends, patterns, and chronological data shifts over time.
2. Cumulative Analysis: Implementing aggregate running calculations, moving boundaries, and cumulative metrics across data      sets.
3. Performance Analysis: Evaluating key metric behaviors, variances, and performance indicator efficiencies against target      benchmarks.
4. Part-to-Whole (Proportional) Analysis: Breaking down structural compositions and relative proportional contributions of      individual components to the whole.
5. Data Segmentation: Clustering and partitioning complex datasets into distinct, meaningful groups based on behavioral or      demographic traits.
6. Reporting: Designing clean, structured query architectures to transform raw transactional data into actionable               operational reports.


## Schema

```sql
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
	product_number varchar(50) ,
	product_name varchar(50) ,
	category_id varchar(50) ,
	category varchar(50) ,
	subcategory varchar(50) ,
	maintenance varchar(50) ,
	cost int,
	product_line varchar(50),
	start_date date 
);

CREATE TABLE gold_sales(
	order_number varchar(50),
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
```
## Business Problems and Solutions

==================================
CHANGE-OVER-TIME ANALYSIS
===============================
 
--1. Analyze Sales Over Time 

```sql
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
```
## Objectives; 
--analyze how a measure evolves over time                  
--helps track trends and identify seasonality in your data


=================================
CUMULATIVE ANALYSIS
=================================
 
--1. Calculates Total Sales Per Month and Running Total Of Sales Over Time.    {months of year sales}

```sql
with cte as(			
			select DATEFROMPARTS(year(order_date),MONTH(order_date),1) as month_wise, sum(sales_amount) as month_sales 
			from gold_sales
			where order_date is not null
			group by DATEFROMPARTS(year(order_date),MONTH(order_date),1)
			) 

select month_wise, month_sales, 
sum(month_sales) over ( order by month_wise) as running_total 
from cte;
```
## Objectives;
--aggregate the data progressivly over time 
--helps to understand whether our business is growing or decling


==============================
PERFORMANCE ANALYSIS
==============================

--1. Analyze The Yearly Performance Of Products By Comparing Thier Sales To Both The Average Sales 
-----Perfomance Of The Product And The Previous Year's Sales                 {year-over-year}

```sql
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
```

**Objective: comparing the current value to target value


===================================
PART-TO-WHOLE ANALYSIS
===================================
 
--1. Which Categories Contribute The Most To Overall Sales        {BY Percentage}

```sql
with cte as (
			select category, sum(gold_sales.sales_amount) as sales from gold_sales
			left join gold_products
			on gold_sales.product_key = gold_products.product_key
			group by category
			)

select category, sales, 
concat(round(cast(sales as float)/(select sum(sales_amount)from gold_sales)*100,2),'%') as category_perct
from cte

```

**Objective:
analyze how an individual part is performing compared to the overall, allowing 
us to understand which category has the biggest impact on the business


===================================
DATA SEGMENTATION
=================================

--1. Segment Products Into Cost Ranges and 
    How Many Products Fall Into Each Segment

```sql
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
```

--2. Group customers into three segments based on their spending behavior:       
--   - VIP: Customers with at least 12 months of history and spending more than €5,000.                     
--        - Regular: Customers with at least 12 months of history but spending €5,000 or less.           
			--            - New: Customers with a lifespan less than 12 months.
		--      And find the total number of customers by each group 

```sql
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
```

**Objectives:
group the data based on specific range 
helps to understand the correlation between two measures 


=============================================    
**REPORTS**

=================================
**Customer Report**
============================
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

-- =============================================================================
-- Create Report: gold_report_customers
-- =============================================================================

```sql
CREATE VIEW gold_report_customers AS

WITH base_query AS(
---------------------------------------------------------------------------
--1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------
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
---------------------------------------------------------------------------
--2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------
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
```


## Key Findings

Across the analytical workflows, the following insights were uncovered:

* **Trend Shifts (Change-Over-Time)**: Long-term data distributions reveal clear cyclical patterns and seasonal shifts, which are critical for accurate forecasting and proactive planning.
* **Growth Dynamics (Cumulative Analysis)**: Running totals and cumulative aggregates effectively pinpoint major inflection points, highlighting exactly when growth velocity accelerated or stabilized.
* **Performance Benchmarks (Performance Analysis)**: Evaluating core key performance indicators (KPIs) exposed distinct operational variances, making it easy to identify which segments consistently hit targets versus those falling behind.
* **Composition Breakdown (Part-to-Whole)**: Proportional analysis isolated the primary drivers of total volume, proving that a concentrated minority of categories holds a dominant share of the overall metrics.
* **Behavioral Cohorts (Data Segmentation)**: Partitioning the dataset surfaced unique user groups with highly contrasting characteristics, confirming that generic strategies are less effective than targeted, group-specific approaches.
* **Reporting Efficiency (Reporting)**: Transforming raw transactional data into structured, optimized tables significantly reduced query latency, ensuring operational reports load quickly for stakeholder decision-making.

---
