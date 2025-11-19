/********************************************************************************************
    PROJECT: Blinkit Sales Analysis
    DESCRIPTION: 
        This script contains all SQL queries used for the Blinkit dashboard, including:
        - Data Cleaning
        - KPI calculations
        - Sales breakdown analysis
        - Pivot transformations
        - Percentage calculations
********************************************************************************************/


/*********************************
 =>> VIEW RAW DATA
*********************************/
SELECT * 
FROM blinkit_data;


/*********************************
 =>> DATA CLEANING – Standardize Item_Fat_Content
*********************************/
/*
    Purpose:
    - Fix inconsistent labels such as: 'LF', 'low fat', 'reg'
    - Ensure only two clean categories remain: 'Low Fat' and 'Regular'
*/
UPDATE blinkit_data
SET Item_Fat_Content = CASE
        WHEN Item_Fat_Content IN ('LF', 'low fat') THEN 'Low Fat'
        WHEN Item_Fat_Content = 'reg' THEN 'Regular'
        ELSE Item_Fat_Content
    END;

/* Verify cleaning results */
SELECT DISTINCT Item_Fat_Content 
FROM blinkit_data;



/*********************************
 =>> KPI CALCULATIONS
*********************************/

/* 1. TOTAL SALES (in millions) */
SELECT 
    CAST(SUM(Total_Sales) / 1000000.0 AS DECIMAL(10,2)) AS Total_Sales_Million
FROM blinkit_data;

/* 2. AVERAGE SALES */
SELECT 
    CAST(AVG(Total_Sales) AS INT) AS Avg_Sales
FROM blinkit_data;

/* 3. NUMBER OF ITEMS */
SELECT 
    COUNT(*) AS No_of_Orders
FROM blinkit_data;

/* 4. AVERAGE RATING */
SELECT 
    CAST(AVG(Rating) AS DECIMAL(10,1)) AS Avg_Rating
FROM blinkit_data;



/*********************************
 =>> SALES BREAKDOWN ANALYSIS
*********************************/

/* A. Total Sales by Fat Content */
SELECT 
    Item_Fat_Content,
    CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
FROM blinkit_data
GROUP BY Item_Fat_Content;


/* B. Total Sales by Item Type */
SELECT 
    Item_Type, 
    CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
FROM blinkit_data
GROUP BY Item_Type
ORDER BY Total_Sales DESC;


/*********************************
 =>> FAT CONTENT BY OUTLET LOCATION (PIVOT)
*********************************/
/*
    This query transforms Item_Fat_Content values into columns
    (Low Fat, Regular) for each Outlet_Location_Type.
*/
SELECT 
    Outlet_Location_Type,
    ISNULL([Low Fat], 0) AS Low_Fat,
    ISNULL([Regular], 0) AS Regular
FROM 
(
    SELECT 
        Outlet_Location_Type,
        Item_Fat_Content,
        CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
    FROM blinkit_data
    GROUP BY Outlet_Location_Type, Item_Fat_Content
) AS SourceTable
PIVOT
(
    SUM(Total_Sales)
    FOR Item_Fat_Content IN ([Low Fat], [Regular])
) AS PivotTable
ORDER BY Outlet_Location_Type;



/*********************************
 =>> TOTAL SALES BY OUTLET ESTABLISHMENT YEAR
*********************************/
SELECT 
    Outlet_Establishment_Year,
    CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
FROM blinkit_data
GROUP BY Outlet_Establishment_Year
ORDER BY Outlet_Establishment_Year;



/*********************************
 =>> PERCENTAGE OF SALES BY OUTLET SIZE
*********************************/
/*
    Calculates each outlet size’s contribution to total sales
    using a window function.
*/
SELECT 
    Outlet_Size,
    CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales,
    CAST( (SUM(Total_Sales) * 100.0 / SUM(SUM(Total_Sales)) OVER()) AS DECIMAL(10,2)) 
        AS Sales_Percentage
FROM blinkit_data
GROUP BY Outlet_Size
ORDER BY Total_Sales DESC;



/*********************************
 =>> SALES BY OUTLET LOCATION
*********************************/
SELECT 
    Outlet_Location_Type,
    CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
FROM blinkit_data
GROUP BY Outlet_Location_Type
ORDER BY Total_Sales DESC;



/*********************************
 =>> FULL METRICS BY OUTLET TYPE
*********************************/
SELECT 
    Outlet_Type,
    CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales,
    CAST(AVG(Total_Sales) AS DECIMAL(10,0)) AS Avg_Sales,
    COUNT(*) AS No_Of_Items,
    CAST(AVG(Rating) AS DECIMAL(10,2)) AS Avg_Rating,
    CAST(AVG(Item_Visibility) AS DECIMAL(10,2)) AS Item_Visibility
FROM blinkit_data
GROUP BY Outlet_Type
ORDER BY Total_Sales DESC;
