-- Datebase created
CREATE DATABASE swiggy

-- check the data
SELECT *
FROM Swiggy_Data

-- Data Validations & Cleaning
-- Null Check
SELECT
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_dish,
    SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
    SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) null_rating_count
FROM swiggy_Data;

--Blank or Empty Strings
SELECT *
FROM Swiggy_Data
WHERE
State = '' or City = '' OR Restaurant_Name = '' OR Location = '' OR Dish_Name= '' 

--Duplicates Detection
SELECT
State , City , Order_Date , Restaurant_Name , Location , Category, Dish_Name, Price_INR ,
Rating,Rating_Count , COUNT(*) AS CNT
FROM Swiggy_Data
GROUP BY
State , City , Order_Date , Restaurant_Name , Location , Category, Dish_Name, Price_INR ,
Rating,Rating_Count 
HAVING COUNT(*) > 1

--Delete Duplication
WITH CTE AS (
SELECT * , ROW_NUMBER() OVER(
     PARTITION BY State , City , Order_Date , Restaurant_Name , Location , Category, Dish_Name, Price_INR ,
Rating,Rating_Count 
ORDER BY (SELECT NULL)
) AS rn
FROM Swiggy_Data
)
DELETE FROM CTE WHERE rn>1

-- CREATING SCHEMA
-- DIMENSION TABLE
-- DATE TABLE

CREATE TABLE dim_date(
    date_id INT IDENTITY(1,1) PRIMARY KEY,
    FULL_DATE DATE ,
    YEAR INT ,
    MONHT INT,
    Month_name VARCHAR(20),
    Quarter INT,
    Day INT,
    Week INT)

-- Locatioon table

CREATE TABLE dim_location(
    loction_id INT IDENTITY(1,1) PRIMARY KEY,
    State VARCHAR(100),
    City VARCHAR(100),
    Location VARCHAR(200)
    );

-- Restaurant Table
CREATE TABLE dim_restaurant(
    restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
    );

-- Category Table
CREATE TABLE dim_category(
   category_id INT IDENTITY(1,1) PRIMARY KEY,
   category VARCHAR(200)
   );

-- Dish table
CREATE TABLE dim_dish(
    dish_id INT IDENTITY(1,1) PRIMARY KEY,
    Dish_Name VARCHAR(200)
    );

SELECT * FROM Swiggy_Data

-- FACT TABLE

CREATE TABLE fact_swiggy_orders
(
    order_id INT IDENTITY(1,1) PRIMARY KEY,

    date_id INT,
    Price_INR DECIMAL(10,2),
    Rating DECIMAL(4,2),
    Rating_Count INT,

    loction_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    FOREIGN KEY (date_id)
        REFERENCES dim_date(date_id),

    FOREIGN KEY (loction_id)
        REFERENCES dim_location(loction_id),

    FOREIGN KEY (restaurant_id)
        REFERENCES dim_restaurant(restaurant_id),

    FOREIGN KEY (category_id)
        REFERENCES dim_category(category_id),

    FOREIGN KEY (dish_id)
        REFERENCES dim_dish(dish_id)
);

ALTER TABLE fact_swiggy_orders
ADD Rating DECIMAL(4,2);

SELECT * 
FROM fact_swiggy_orders

-- INSERT DATA IN TABLE
-- dim_date
INSERT INTO dim_date( FULL_DATE , YEAR , MONHT , Month_name,Quarter,Day,Week)
SELECT DISTINCT
    Order_Date,
    YEAR(Order_Date),
    MONTH(Order_Date),
    DATENAME(MONTH,Order_Date),
    DATEPART(Quarter ,Order_Date),
    DAY(Order_Date),
    DATEPART(WEEK , Order_Date)
FROM Swiggy_Data
WHERE Order_Date IS NOT NULL;

SELECT * FROM dim_date

-- dim_location
INSERT INTO dim_location(State,City,Location)
SELECT DISTINCT
    State,
    City,
    Location
FROM Swiggy_Data

SELECT * FROM dim_location

--dim_restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
   Restaurant_Name
FROM Swiggy_Data;

SELECT * FROM dim_restaurant

--dim_category
INSERT INTO dim_category(category)
SELECT DISTINCT    
    Category
FROM Swiggy_Data;

SELECT * FROM dim_category

--dim_dish
INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT
   Dish_Name
FROM Swiggy_Data;

SELECT * FROM dim_dish

--FACT_TABLE
INSERT INTO fact_swiggy_orders
(
   date_id,
   Price_INR,
   Rating,
   Rating_Count,
   loction_id,
   restaurant_id,
   category_id,
   dish_id
)
SELECT
   dd.date_id,
   s.Price_INR,
   s.Rating,
   s.Rating_Count,
   dl.loction_id,
   dr.restaurant_id,
   dc.category_id,
   dsh.dish_id
FROM Swiggy_Data s

JOIN dim_date dd
   ON dd.FULL_DATE = s.Order_Date

JOIN dim_location dl
   ON dl.State = s.State
   AND dl.City = s.City
   AND dl.Location = s.Location

JOIN dim_restaurant dr
   ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc
   ON dc.category = s.Category

JOIN dim_dish dsh
   ON dsh.Dish_Name = s.Dish_Name ;

SELECT * FROM fact_swiggy_orders


SELECT * FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l on f.loction_id = l.loction_id
JOIN dim_restaurant r on f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id = di.dish_id


-- KPI's
-- Total Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders

--Total Revenue (INR Million)
SELECT 
FORMAT(SUM(CONVERT(FLOAT,price_INR))/1000000 , 'N2') + ' INR Million'
AS Total_Revenue
FROM fact_swiggy_orders

--Average Dish price
SELECT
FORMAT(AVG(CONVERT(FLOAT, price_INR)) , 'N2')+' INR'
AS total_Revenue
FROM fact_swiggy_orders

--Average Rating
SELECT
AVG(Rating) AS Avg_rating
FROM fact_swiggy_orders


--Deep Dive Business Analysis

--Monthly Order Trends
SELECT
d.YEAR,
d.MONHT,
d.Month_name,
FORMAT(SUM(CONVERT(FLOAT,price_INR))/1000000 , 'N2') + ' INR Million'
AS Total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.YEAR,
d.MONHT,
d.Month_name
ORDER BY SUM(price_INR)

--Quarterly Trend
SELECT
d.YEAR,
d.Quarter,
COUNT(*) AS TotalOrders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.YEAR,
d.Quarter
ORDER BY COUNT(*) DESC

--Yearly Trend
SELECT
d.YEAR,
COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.YEAR
ORDER BY COUNT(*) DESC

--Orders by Day of Week(Mon-Sun)
SELECT
   DATENAME(WEEKDAY , d.FULL_DATE) AS day_name,
   COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY , d.FULL_DATE) , DATEPART(WEEKDAY , d.FULL_DATE)
ORDER BY DATEPART(WEEKDAY , d.FULL_DATE);

--Top 10 Cities BY order Volume
SELECT
l.City,
COUNT(*) AS total_Orders
FROM fact_swiggy_orders f
JOIN dim_location l
ON l.loction_id = f.loction_id
GROUP BY l.City
ORDER BY COUNT(*) DESC

--Total _Revenue
SELECT
l.City,
SUM(f.Price_INR) AS tota_Revenue
FROM fact_swiggy_orders f
JOIN dim_location l
ON l.loction_id = f.loction_id
GROUP BY l.City
ORDER BY COUNT(*) DESC

-- Revenue constibution by state
SELECT
l.State,
SUM(f.Price_INR) AS tota_Revenue
FROM fact_swiggy_orders f
JOIN dim_location l
ON l.loction_id = f.loction_id
GROUP BY l.State
ORDER BY COUNT(*) DESC

--Top 10 Restaurants by orders
SELECT TOP 10
r.Restaurant_Name,
SUM(f.price_INR) AS Total_revenue
FROM fact_swiggy_orders f
JOIN dim_restaurant r
ON r.restaurant_id = f.restaurant_id
GROUP BY r.Restaurant_Name
ORDER BY SUM(f.price_INR) DESC;

--Top Categories by order Volume
SELECT TOP 20
    c.category,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY total_orders desc;

-- Most Ordered Dishes
SELECT TOP 30
   d.Dish_Name,
   COUNT(*) AS order_count
FROM fact_swiggy_orders f
JOIN dim_dish d ON f.dish_id = d.dish_id
GROUP BY d.Dish_Name
ORDER BY order_count DESC;

-- Cuisine Performance (Orders + Avg Rating)
SELECT
   c.category,
   COUNT(*) AS total_orders,
   AVG(CONVERT(FLOAT , f.rating)) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY total_orders DESC;

--Total Order By Price Range
SELECT
  CASE
     WHEN CONVERT(FLOAT , price_INR) < 100 THEN 'Under 100'
     WHEN CONVERT(FLOAT , price_INR) BETWEEN 100 AND 100 THEN '100-199'
     WHEN CONVERT(FLOAT , price_INR) BETWEEN 200 AND 299 THEN '200-299'
     WHEN CONVERT(FLOAT,  price_INR) BETWEEN 300 AND 499 THEN '300-499'
     ELSE '500+'
  END AS price_range,
  COUNT(*) AS total_orders

FROM fact_swiggy_orders
GROUP BY 
   CASE
     WHEN CONVERT(FLOAT , price_INR) < 100 THEN 'Under 100'
     WHEN CONVERT(FLOAT , price_INR) BETWEEN 100 AND 100 THEN '100-199'
     WHEN CONVERT(FLOAT , price_INR) BETWEEN 200 AND 299 THEN '200-299'
     WHEN CONVERT(FLOAT,  price_INR) BETWEEN 300 AND 499 THEN '300-499'
     ELSE '500+'
   END
ORDER BY total_orders ;

--Rating Count Distribution(1-5)
SELECT
   rating,
   COUNT(*) AS rating_count
FROM fact_swiggy_orders
GROUP BY rating
ORDER BY rating_count DESC;