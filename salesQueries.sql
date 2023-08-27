-- Examine Data
SELECT * FROM dbo.sales;


-- Checking unique values
SELECT DISTINCT Status			FROM dbo.sales; 
SELECT DISTINCT Year			FROM dbo.sales;
SELECT DISTINCT ProductLine		FROM dbo.sales; 
SELECT DISTINCT Country			FROM dbo.sales;
SELECT DISTINCT DealSize		FROM dbo.sales; 
SELECT DISTINCT Territory		FROM dbo.sales; 

-- EDA

-- What product line sells the most
SELECT ProductLine, ROUND(SUM(Sales), 0) AS Revenue
	FROM dbo.sales
	GROUP BY ProductLine
	ORDER BY Revenue DESC;

-- Revenue per year
SELECT Year, ROUND(SUM(sales), 0) AS Revenue
	FROM dbo.sales
	GROUP BY Year
	ORDER BY Revenue DESC;

-- Sales growth over years
SELECT
     Year
    ,ROUND(TotalSales, 2) AS "Total Sales"
    ,ROUND(((TotalSales - LAG(TotalSales) OVER (ORDER BY Year)) / LAG(TotalSales) OVER (ORDER BY Year)) * 100, 2) AS "Growth per year"
    ,ROUND(((TotalSales - LAG(TotalSales, 2) OVER (ORDER BY Year)) / LAG(TotalSales, 2) OVER (ORDER BY Year)) * 100, 2) AS "2 year growth"
FROM (
    SELECT Year, SUM(Sales) AS TotalSales
		FROM dbo.sales
		GROUP BY Year
) YearlySales
ORDER BY Year;

-- Total revenue per size of deal
SELECT  DealSize, ROUND(SUM(sales), 0) AS Revenue
	FROM SALES.dbo.sales
	GROUP BY  DealSize
	ORDER BY Revenue DESC;


-- What was the best month for sales in a specific year? How much was earned that month? 
SELECT  Month 
	,ROUND(SUM(sales), 0) AS Revenue
	,COUNT(OrderNumber) AS "Total Orders"
FROM SALES.dbo.sales
	WHERE Year = 2021 -- Adjust
	GROUP BY  Month
	ORDER BY Revenue DESC;


-- Quarterly Sales 
SELECT Year, QTR, ROUND(SUM(Sales), 2) AS QuarterlySales
	FROM dbo.sales
	GROUP BY Year, QTR
	ORDER BY Year, QTR;
-- OR
----SELECT QTR, SUM(Sales) AS QuarterlySales
----	FROM dbo.sales
----	WHERE Year = 2021
----	GROUP BY QTR
----	ORDER BY QTR;

-- Sales of each product per month
SELECT  Month, ProductLine 
	,ROUND(SUM(Sales), 0) AS Revenue 
	,ROUND(AVG(Sales), 2) AS "Average Sale" 
	,COUNT(OrderNumber) AS "Total Purchases"
FROM SALES.dbo.sales
	WHERE Year = 2021 and Month = 'May' -- Adjust
	GROUP BY  Month, ProductLine
	ORDER BY Revenue DESC;


-- Statistical analysis of monthly spending variability
WITH MonthlySpending AS (
    SELECT	CustomerName, Month, SUM(Sales) AS MonthlySales
    FROM dbo.sales
    GROUP BY CustomerName, Month
)
SELECT
    CustomerName,
    ROUND(AVG(MonthlySales),0) AS AvgMonthlySales,
    ROUND(STDEV(MonthlySales),2) AS StdDevMonthlySales,
    ROUND(AVG(MonthlySales) / STDEV(MonthlySales),2) AS CoefficientOfVariation
FROM MonthlySpending
	GROUP BY CustomerName
	HAVING AVG(MonthlySales) / STDEV(MonthlySales) > 0.5
	ORDER BY CoefficientOfVariation DESC; -- High variability -- Adjust 


-- Top selling products per product line ????
WITH RankedProducts AS (
    SELECT
        ProductLine,
        ProductCode,
        RANK() OVER (PARTITION BY ProductLine ORDER BY SUM(Sales) DESC) AS Rank
    FROM dbo.sales
		GROUP BY ProductLine, ProductCode
)
SELECT ProductLine, ProductCode, Rank
	FROM RankedProducts
	WHERE Rank <= 5
	ORDER BY Rank;


-- What city has the highest number of sales in a specific country
SELECT City, ROUND(SUM (sales), 2) AS Revenue
	FROM SALES.dbo.sales
	WHERE Country = 'USA' -- Adjust
	GROUP BY City
	ORDER BY Revenue DESC;


-- What is the best product in United States?
SELECT Country, Year, ProductLine, ROUND(SUM (sales), 2) AS Revenue
	FROM SALES.dbo.sales
	WHERE Country = 'USA' -- Adjust
	GROUP BY  Country, Year, ProductLine
	ORDER BY Revenue DESC;

-- What products are most often sold together? 
SELECT DISTINCT OrderNumber, STUFF(
	(SELECT ',   ' + ProductCode 
	FROM dbo.sales AS Product
	WHERE OrderNumber IN 
		(
		SELECT OrderNumber 
			FROM (
				SELECT OrderNumber, COUNT(*) AS GroupCount
				FROM SALES.dbo.sales
				WHERE STATUS = 'Shipped'
				GROUP BY OrderNumber
				)p
					WHERE GroupCount = 3
			)
			AND Product.OrderNumber = s.OrderNumber
				for xml path (''))	, 1, 1, '') AS ProductCodes -- End of STUFF() (replace)
	FROM dbo.sales s
		ORDER BY ProductCodes DESC;


-- Who is best customer (can be answered with RFM)
DROP TABLE IF EXISTS #rfm
;with rfm as 
(


	SELECT 
		CustomerName, 
		SUM(sales) AS "Monetary Total",
		AVG(sales) AS "Average Monetary Value",
		COUNT(OrderDate) AS Frequency,
		MAX(OrderDate) AS "First Order Date",
		(SELECT MAX(OrderDate) FROM dbo.sales) AS "Recent Order Date",
		DATEDIFF(DD, MAX(OrderDate), (SELECT MAX(ORDERDATE) FROM dbo.sales)) AS "Recency"
	FROM SALES.dbo.sales
	GROUP BY CustomerName
	ORDER BY [Monetary Total] DESC



