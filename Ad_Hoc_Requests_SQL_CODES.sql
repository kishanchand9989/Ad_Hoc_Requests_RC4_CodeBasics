# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
#    business in the APAC region.

WITH CTE as(
      SELECT 
      *
      FROM dim_customer
      WHERE customer ="Atliq Exclusive" and region ="APAC")
      SELECT  DISTINCT market FROM CTE;
      
      SELECT DISTINCT market from dim_customer WHERE customer ="Atliq Exclusive" and region ="APAC"
      
# 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
#    unique_products_2020, unique_products_2021 ,percentage_chg

SELECT COUNT(DISTINCT product) FROM dim_product;

WITH CTE2 AS (
SELECT 
        COUNT(DISTINCT product_code) as unique_products_2020,
        (SELECT COUNT(DISTINCT product_code)  FROM fact_sales_monthly WHERE fiscal_year =2021) as unique_products_2021
		FROM fact_sales_monthly 
        WHERE fiscal_year =2020)
SELECT *,ROUND(((unique_products_2021-unique_products_2020)*100/unique_products_2020),2) as percentage_change FROM CTE2;


# 3. Provide a report with all the unique product counts for each segment and
#     sort them in descending order of product counts. The final output contains
#     2 fields they are segment,product_count
SELECT COUNT(DISTINCT(segment)) FROM dim_product;
SELECT 
     segment,COUNT(segment)  as product_count
     FROM dim_product
     GROUP BY segment
     ORDER BY product_count DESC;
     
     
#   4. Follow-up: Which segment had the most increase in unique products in
#      2021 vs 2020? The final output contains these fields,
#      segment,product_count_2020,product_count_2021,difference


SELECT COUNT(DISTINCT(segment)) FROM dim_product;


WITH CTE4 as (
     SELECT 
     #fsm.*,dp.segment,dp.product,dp.variant
     dp.segment as SEGMENT,COUNT(DISTINCT fsm.product_code) as product_count_2020,fsm.fiscal_year
     FROM fact_sales_monthly as fsm
     JOIN dim_product as dp
     ON fsm.product_code =dp.product_code
     WHERE fiscal_year =2020
     GROUP BY dp.segment
     ORDER BY product_count_2020 DESC),
     
     CTE41 as (
     SELECT 
     #fsm.*,dp.segment,dp.product,dp.variant
     dp.segment AS SEGMENT1,COUNT(DISTINCT fsm.product_code) as product_count_2021,fsm.fiscal_year
     FROM fact_sales_monthly as fsm
     JOIN dim_product as dp
     ON fsm.product_code =dp.product_code
     WHERE fiscal_year =2021
     GROUP BY dp.segment
     ORDER BY product_count_2021 DESC)
     
     SELECT 
          SEGMENT,CTE4.product_count_2020,CTE41.product_count_2021,
          (CTE41.product_count_2021-CTE4.product_count_2020) AS Difference
          FROM CTE4
          JOIN CTE41
		  ON CTE4.SEGMENT =CTE41.SEGMENT1
          ORDER BY Difference DESC;


# 5. Get the products that have the highest and lowest manufacturing costs.
#    The final output should contain these fields,
#    product_code,product,manufacturing_cost

SELECT 
      dp.product_code, product, fmc.manufacturing_cost,fmc.cost_year
      FROM dim_product as dp
      JOIN fact_manufacturing_cost as fmc
      USING(product_code)
      WHERE manufacturing_cost in
      ((select min(manufacturing_cost) from fact_manufacturing_cost)
      UNION
      (select max(manufacturing_cost) from fact_manufacturing_cost));


#   6. Generate a report which contains the top 5 customers who received an
#      average high pre_invoice_discount_pct for the fiscal year 2021 and in the
#      Indian market. The final output contains these fields,
#      customer_code,customer,average_discount_percentage

SELECT   
      dc.customer_code,customer,ROUND(avg(pre_invoice_discount_pct),4) as avg_discount_percentage
      From dim_customer as dc
      JOIN fact_pre_invoice_deductions as fpid
      ON dc.customer_code =fpid.customer_code
      WHERE dc.market ="India" and fpid.fiscal_year =2021
      GROUP BY (dc.customer_code)
      ORDER BY avg_discount_percentage DESC
      LIMIT 5;
      

#    7. Get the complete report of the Gross sales amount for the customer “Atliq
#       Exclusive” for each month. This analysis helps to get an idea of low and
#       high-performing months and take strategic decisions.The final report contains these columns:
#       Month,Year,Gross sales Amount

SELECT 
	  fsm.date,MONTHNAME(fsm.date) as month,YEAR(fsm.date) as year,fsm.fiscal_year,dc.customer,
      #(SUM(fsm.sold_quantity)) as montly_sold_qty,(SUM(fgp.gross_price)) as montly_gross,
      (SUM(fsm.sold_quantity*fgp.gross_price)) as monthly_gross_sales_amt
      FROM fact_sales_monthly as fsm
      JOIN dim_customer as dc ON fsm.customer_code =dc.customer_code
      JOIN fact_gross_price as fgp ON fsm.product_code =fgp.product_code
      WHERE dc.customer ="Atliq Exclusive"
      GROUP BY month,year;
      
      
#     8. In which quarter of 2020, got the maximum total_sold_quantity? The final
#        output contains these fields sorted by the total_sold_quantity,
#        Quarter,total_sold_quantity

SELECT 
      
      CASE
          WHEN month in (9,10,11) THEN 'Q1'
          WHEN month in (12,1,2) THEN 'Q2'
          WHEN month in (3,4,5) THEN 'Q3'
          WHEN month in (6,7,8) THEN 'Q4'
          ELSE 'Q'
      END AS Quarter_month,
      SUM(sold_quantity) AS Quarter_wise_sold_qty
	FROM (SELECT date, MONTH(date) as month,sold_quantity,fiscal_year FROM fact_Sales_monthly) AS quater_table
    WHERE fiscal_year=2020
    GROUP BY Quarter_month
    ORDER BY  Quarter_wise_sold_qty DESC;
    

#   9. Which channel helped to bring more gross sales in the fiscal year 2021
#      and the percentage of contribution? The final output contains these fields,
#      channel,gross_sales_mln,percentage

WITH CTE9 as( SELECT 
      #fsm.product_code,
      dc.channel,CONCAT(ROUND(SUM(fgp.gross_price*fsm.sold_quantity)/1000000,2)," M") as Gross_Sales_mlns
      FROM fact_sales_monthly as fsm
      JOIN dim_customer as dc ON fsm.customer_code =dc.customer_code
      JOIN fact_gross_price as fgp ON fsm.product_code =fgp.product_code 
      WHERE fsm.fiscal_year =2021
      GROUP BY channel) 
      SELECT *,CONCAT(ROUND(gross_sales_mlns*100/SUM(gross_sales_mlns) over(),2)," %") as Gross_Sales_pct
      FROM CTE9
      ORDER BY Gross_Sales_pct DESC;
      
      
#    10. Get the Top 3 products in each division that have a high 
#        total_sold_quantity in the fiscal_year 2021? The final output contains these
#        fields,division,product_code

WITH CTE10 as(SELECT 
      fsm.product_code,division,SUM(sold_quantity) as Total_Sold_Qty
       FROM dim_product as dp
       JOIN fact_sales_monthly as fsm
       ON dp.product_code =fsm.product_code
       WHERE fsm.fiscal_year =2021
       GROUP BY product_code
       ORDER BY division,Total_Sold_Qty DESC
       ),
CTE10_1 AS (
          SELECT
               CTE10.product_code,
               dense_rank() over(partition by division ORDER BY Total_Sold_Qty DESC) as ranking
               FROM CTE10
               )
       #SELECT *,dense_rank() over(partition by division order by Total_Sold_Qty desc) as ranking FROM CTE6 WHERE ranking<=3
       SELECT CTE10.product_code,CTE10.division,CTE10.Total_Sold_Qty,CTE10_1.ranking 
       FROM CTE10 
       JOIN CTE10_1 
       ON CTE10.product_Code =CTE10_1.product_code
       WHERE ranking<=3