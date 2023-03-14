-- DATA ANALYSIS
USE olympics;
SELECT * FROM laptop_duplicate;
ALTER TABLE laptop_duplicate DROP COLUMN gpu_;

-- Head
SELECT * FROM laptop_duplicate
ORDER BY `index` LIMIT 5;

-- TAIL
SELECT * FROM laptop_duplicate
ORDER BY `index` DESC LIMIT 5;

-- SAMPLE
SELECT * FROM laptop_duplicate
ORDER BY RAND() LIMIT 5;


-- Analyze Numerical Column

-- 1. Price

SELECT 
COUNT(Price) OVER(),
MIN(Price) OVER(),
MAX(Price) OVER(),
STD(Price) OVER(),
PERCENTILE_DISC(0.25) WITHIN GROUP(ORDER BY Price) OVER() AS 'Q1',
PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY Price) OVER() AS 'median',
PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY Price) OVER() AS 'Q3'
FROM laptop_duplicate
LIMIT 1 ;

 -- NULL VALUES 
 
 SELECT COUNT(*) FROM laptop_duplicate
 WHERE Price = NULL;
 
 -- OUTLIERS DETECTION 
 
SELECT * FROM ( SELECT *,
				PERCENTILE_DISC(0.25) WITHIN GROUP(ORDER BY Price) OVER() AS 'Q1',
				PERCENTILE_DISC(0.75) WITHIN GROUP(ORDER BY Price) OVER() AS 'Q3'
				FROM laptop_duplicate) AS t
WHERE Price < t.Q1 - (t.Q3 - t.Q1) * 1.5 OR Price > t.Q3 + (t.Q3 - t.Q1)*1.5;


-- HISTOGRAM IN SQL :)
SELECT catgory, COUNT(catgory) AS total , REPEAT('*' , COUNT(catgory)/10) AS perc
FROM (SELECT Price,
		CASE 
		   WHEN Price BETWEEN 0 AND 30000 THEN '0-30k'
		   WHEN Price BETWEEN 20001 AND 60000 THEN '30k-60k'
		   WHEN Price BETWEEN 60001 AND 100000 THEN '60k-100k'
		   ELSE '>100K'
		END AS catgory
FROM laptop_duplicate) AS t
GROUP BY catgory
ORDER BY total DESC;)


-- CATAGORICAL COLUMN 
SELECT Company, COUNT(Company)/SUM(COUNT(Company)) OVER() *100 AS total
FROM laptop_duplicate
GROUP BY Company
ORDER BY COUNT(Company) DESC;
 
-- BIVARIATR ANALYSIS 
-- NUMERICAL NUMERICAL 

-- CATAGORICAL CATAGORICAL

-- CONTENGENCY TABLE (CROSS TAB)

SELECT Company,
SUM(CASE WHEN Touchscreen = 1 THEN 1 ELSE 0 END) AS screentouch,
SUM(CASE WHEN Touchscreen = 0 THEN 1 ELSE 0 END) AS withoutscreentouch
FROM laptop_duplicate
GROUP BY Company;

SELECT Company,
SUM(CASE WHEN cpu_brand = 'Intel' THEN 1 ELSE 0 END) AS Intel,
SUM(CASE WHEN cpu_brand = 'AMD' THEN 1 ELSE 0 END) AS AMD,
SUM(CASE WHEN cpu_brand = 'Samsung' THEN 1 ELSE 0 END) AS Samsung
FROM laptop_duplicate
GROUP BY Company;

-- Handeling missing values 
-- making some random values in Price column null
UPDATE laptop_duplicate
SET Price = NULL
WHERE `index` IN  (10,11,12,13,14,15);

-- Filling null values based on average Price of corresponding Company
UPDATE laptop_duplicate l1 
SET Price = (SELECT AVG(Price) FROM laptop l2
             WHERE l1.Company = l2.Company)
WHERE Price = NULL;

-- Filling null values based on average Price of corresponding Company and TypeName

UPDATE laptop_duplicate l1 
SET Price = (SELECT AVG(Price) FROM laptop l2
             WHERE l1.Company = l2.Company AND l1.TypeName = l2.TypeName)
WHERE Price = NULL;

SELECT * FROM laptop_duplicate 
WHERE Price = NULL;

-- Replacing Outliers with proper value 
-- where inches = 0 which is not possible 
-- so we will replace them with most frequent inches value of that particular laptop type

UPDATE laptop_duplicate l1
SET Inches = (SELECT Inches FROM (SELECT TypeName, Inches, COUNT(*) AS counts,
				ROW_NUMBER() OVER(PARTITION BY TypeName ORDER BY COUNT(*) DESC) AS row_num
				FROM laptop_duplicate
				GROUP BY TypeName, Inches) AS t
				WHERE t.TypeName = l1.TypeName  AND t.row_num = 1)
WHERE Inches = 0.0;


-- Feature Engineering;
SELECT * FROM laptop_duplicate;
ALTER TABLE laptop_duplicate ADD COLUMN ppi INTEGER AFTER Inches;
UPDATE laptop_duplicate 
SET ppi = (SQRT(pixle_width*pixle_width + pixle_height*pixle_height) / Inches);

SELECT * FROM laptop_duplicate;

-- one hot encoding 
SELECT DISTINCT gpu_brand FROM laptop_duplicate;

SELECT gpu_brand,
CASE WHEN gpu_brand = 'Intel' THEN 1 ELSE 0 END AS Intel,
CASE WHEN gpu_brand = 'AMD' THEN 1 ELSE 0 END AS AMD,
CASE WHEN gpu_brand = 'Nvidia' THEN 1 ELSE 0 END AS Nvidia,
CASE WHEN gpu_brand = 'ARM' THEN 1 ELSE 0 END AS ARM
FROM laptop_duplicate