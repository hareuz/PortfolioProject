-- inspecting data
SELECT * FROM [dbo].[sales_data_sample]

--Checking for unique Values
SELECT DISTINCT status FROM [dbo].sales_data_sample --can plot 
SELECT DISTINCT YEAR_ID FROM [dbo].sales_data_sample -- Good for grouping and plotting
SELECT DISTINCT PRODUCTLINE FROM [dbo].sales_data_sample --Good for grouping and plotting
SELECT DISTINCT COUNTRY FROM [dbo].sales_data_sample -- -- Good for plotting
SELECT DISTINCT DEALSIZE FROM [dbo].sales_data_sample -- Good for grouping and plotting
SELECT DISTINCT TERRITORY FROM [dbo].sales_data_sample-- Good for grouping and plotting

--Starting Analysis; Grouping Sales by Productline
SELECT PRODUCTLINE, SUM(sales) AS Revenue 
FROM [dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--Sales by year
SELECT YEAR_ID, SUM(sales) AS Rev
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

--Very few sales in 2005, we'll check why. Let's look at how long they operated
SELECT DISTINCT month_id FROM sales_data_sample
WHERE YEAR_ID = 2003
-- Results show they operated for just 5 months while operated for all 12 months in other years

--Sales by deal sizes
SELECT DEALSIZE, SUM(sales) AS Revenue 
FROM [dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY 2 DESC

--Best months for sales in specific years. How much were the sales and the best product sold. (Novemeber is the best month)
SELECT MONTH_ID, productline, sum(sales) AS 'highest_Sales', COUNT(ordernumber)	Frequency
FROM sales_data_sample
WHERE month_id = 11 AND YEAR_ID = 2003
GROUP BY MONTH_ID, productline
ORDER BY 4 DESC

--RFM Analysis: The best Customer

DROP TABLE IF EXISTS #rfm 
;with rfm as 
--We use the with clause so we can access the output of the upcoming query with other queries that are associated with it.
(
SELECT 
	CUSTOMERNAME,
	ROUND(SUM(sales),2) Monetary_Value,
	ROUND(AVG(sales),2) AVERAGE_SALES,
	COUNT(sales) Frequency,
	MAX(ORDERDATE) Last_Order_date,
	(SELECT MAX(ORDERDATE) FROM sales_data_sample) Max_ORDER_Date,
	DATEDIFF(DD,MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) Recency
FROM sales_data_sample 
GROUP BY CUSTOMERNAME
),
--SELECT * FROM rfm 

rfm_calc as --This will be our alias
(
		SELECT r.*,
			NTILE(4) OVER (order by Recency desc) rfm_recency, --NTILE divides the columns in the paramater given, in quantiles, in our case 4. Divides the same type 
			NTILE(4) OVER (order by Frequency) rfm_frequency,
			NTILE(4) OVER (order by Monetary_Value) rfm_MonetaryValue
		FROM rfm AS r
)--Resulting column show that higher the rfm NTILE number, higher the recency value, for example. 4 is the highest value, 1 the lowest

-- we concatante the new columns
SELECT 
	calc.*, rfm_recency+rfm_frequency+rfm_MonetaryValue AS rfm_cell, -- creates a new columns of addition of the new columns made using NTILE
	CAST(rfm_recency AS varchar)+CAST (rfm_frequency AS VARCHAR)+ CAST(rfm_MonetaryValue AS varchar) AS rfm_cell_string --this creates a string of the columns to add.
INTO #rfm
FROM rfm_calc AS calc

--Created a temp table so we dont have to run the huge query above every time

-- Now we use the temp table to do an analysis on who is the best customer, lost customer or new customer etc. This just depended on the new columns made using NTILE 
SELECT CUSTOMERNAME, rfm_recency, rfm_MonetaryValue, rfm_frequency,rfm_cell_string,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--Products most often sold together


select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from sales_data_sample AS p
	where ORDERNUMBER in 
		(
			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn --base query (Count of all the orders shipped)
				FROM sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3 --this one takes the inner query results and gives a column where three products were shipping together in orders.
		)
		and p.ORDERNUMBER = s.ORDERNUMBER 
		for xml path ('') --This puts all the order number from the ordernumbers from above query and puts them in an xml path
		
		) , 1, 1, '') ProductCodes --the stuff functions takes the first character in the searched result, replaces 1 character w nothing. It turns in the result a string

from sales_data_sample AS s
order by 2 desc
-- This full query provides us with the information of the products that were bought by customers. We can look for products that were bought together repeatedly. Like we do in assosication rules
