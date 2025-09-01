-- SQL statement to join dim_customers with dim_geography to enrich customer data 
-- with geographic information
SELECT 
    c.CustomerID, 
    c.CustomerName, 
    c.Email, 
    c.Gender, 
    c.Age,  
    g.Country,  
    g.City  
FROM 
    dbo.customers as c
LEFT JOIN
    dbo.geography g 
ON 
    c.GeographyID = g.GeographyID;



-- SQL Query to categorize products based on their price
SELECT 
    ProductID, 
    ProductName,  
    Price, 
	

    CASE 
        WHEN Price < 50 THEN 'Low'  
        WHEN Price BETWEEN 50 AND 200 THEN 'Medium'  
        ELSE 'High'  
    END AS PriceCategory  

FROM 
    dbo.products; 


-- Query to clean whitespace issues in the ReviewText column
SELECT 
    ReviewID,  
    CustomerID,
    ProductID, 
    ReviewDate,
    Rating, 
    -- Cleans up the ReviewText by replacing double spaces with single spaces to ensure the text is more readable and standardized
    REPLACE(ReviewText, '  ', ' ') AS ReviewText
FROM 
    dbo.customer_reviews; 

    
-- Query to clean and normalize the engagement_data table
SELECT 
    EngagementID, 
    ContentID, 
	CampaignID,  
    ProductID,  
    UPPER(REPLACE(ContentType, 'Socialmedia', 'Social Media')) AS ContentType,  
    LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views,  -- Extracts the Views part from the ViewsClicksCombined column by taking the substring before the '-' character
    RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,  -- Extracts the Clicks part from the ViewsClicksCombined column by taking the substring after the '-' character
    Likes, 
    FORMAT(CONVERT(DATE, EngagementDate), 'dd.MM.yyyy') AS EngagementDate 
FROM 
    dbo.engagement_data  
WHERE 
    ContentType != 'Newsletter';  


-- Common Table Expression (CTE) to identify and tag duplicate records
WITH DuplicateRecords AS (
    SELECT 
        JourneyID, 
        CustomerID, 
        ProductID,
        VisitDate, 
        Stage, 
        Action, 
        Duration,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action  
            ORDER BY JourneyID  
        ) AS row_num  
    FROM 
        dbo.customer_journey  
)


-- Select all records from the CTE where row_num > 1, which indicates duplicate entries  
SELECT *
FROM DuplicateRecords
WHERE row_num > 1
ORDER BY JourneyID

-- Outer query selects the final cleaned and standardized data 
SELECT 
    JourneyID,  
    CustomerID, 
    ProductID,  
    VisitDate,  
    Stage,  
    Action,
    COALESCE(Duration, avg_duration) AS Duration  -- Replaces missing durations with the average duration for the corresponding date
FROM 
    (
        -- Subquery to process and clean the data
        SELECT 
            JourneyID,  
            CustomerID,  
            ProductID, 
            VisitDate,  
            UPPER(Stage) AS Stage,  
            Action,  
            Duration, 
            AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,  
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action  
                ORDER BY JourneyID  
            ) AS row_num 
        FROM 
            dbo.customer_journey  
    ) AS subquery  
WHERE 
    row_num = 1;  
