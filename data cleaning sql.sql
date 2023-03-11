-- DATA CLEANING
USE olympics;
 
 -- Create an copy of dataset first 
 
 CREATE TABLE laptop_duplicate LIKE laptop;
 
 INSERT INTO laptop_duplicate
 SELECT * FROM laptop;
 
 SELECT * FROM laptop_duplicate;
 
 -- Check number of rows 
 SELECT COUNT(*) FROM laptop_duplicate;
 
 -- Check memmory consume
 SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
 WHERE TABLE_NAME = 'laptop_duplicate';
 -- Here memmory is in bytes by dividing it by 1024 you will get memmory consumption in kilo bytes
 
 -- Drop non important columns
 SELECT * FROM laptop_duplicate;
 -- ALTER TABLE laptop_duplicate DROP COLUMN column_name
 
 -- Drop null values 
DELETE FROM laptop
WHERE `index` IN (SELECT `index` FROM laptop_duplicate 
                   WHERE Company IS NULL AND TypeName IS NULL AND Inches IS NULL AND ScreenResolution IS NULL AND Cpu IS NULL AND Ram IS NULL AND Memory IS NULL AND Gpu IS NULL AND OpSys IS NULL AND Weight IS NULL AND Price IS NULL);
 
 SELECT COUNT(*) FROM laptop;
 
 
 -- Duplicates
 -- How to see duplicae values 
 SELECT FirstName, COUNT(*) FROM duplicates
 GROUP BY FirstName
 HAVING COUNT(*) > 1;
 
 -- How to remove duplicate values 
CREATE TABLE duplicate_copy LIKE duplicates;

INSERT INTO duplicate_copy
SELECT * FROM duplicates;

DELETE FROM duplicate_copy
WHERE index_no NOT IN (SELECT MIN(index_no) FROM duplicates
                      GROUP BY FirstName);  -- this subquery will return the first occurence of every duplicated value
                      
SELECT * FROM duplicate_copy;

-- Data Cleaning

-- use distinct function to check catagorical columns and also the missing values in dataset

SELECT * FROM laptop_duplicate;
-- Company column
SELECT DISTINCT Company FROM laptop_duplicate; 
-- TypeName
SELECT DISTINCT TypeName FROM laptop_duplicate;
-- Inches
-- Convert data type 
ALTER TABLE laptop_duplicate MODIFY COLUMN Inches DECIMAL(10,0); -- i got erreo here because some row is not containing numerical value

SELECT * FROM laptop_duplicate WHERE Inches NOT REGEXP '^[0-9]+(\.[0-9]+)?$'; -- checking that row causing a problem

UPDATE laptop_duplicate -- Replacing that row containing non numeric inches value with 0
SET Inches = 0
WHERE Inches = '?';

ALTER TABLE laptop_duplicate MODIFY COLUMN Inches DECIMAL(10,0);
SELECT * FROM laptop_duplicate;

-- Ram 
UPDATE laptop_duplicate AS l1
SET Ram = (SELECT REPLACE(Ram, 'GB', '') FROM laptop AS l2 WHERE l1.index = l2.index);

-- Converting into appropriate data type
ALTER TABLE laptop_duplicate MODIFY COLUMN Ram INTEGER;

SELECT * FROM laptop_duplicate;

-- weight 

-- Remove kg and replace original column with updated column
UPDATE laptop_duplicate l1
SET Weight = (SELECT REPLACE(Weight, 'kg', '') FROM laptop l2 WHERE l1.index = l2.index);

-- update rows containing  ? with 0
UPDATE laptop_duplicate
SET Weight = 0
WHERE Weight  = '?';

-- Converting into appropriate data type
ALTER TABLE laptop_duplicate MODIFY COLUMN Weight DECIMAL(10,1);

-- Price

-- Round up the price column and replace with original column 
UPDATE laptop_duplicate l1
SET Price = (SELECT ROUND(Price) FROM laptop l2 WHERE l1.index = l2.index);

-- Conver price column into integer data type
ALTER TABLE laptop_duplicate MODIFY COLUMN Price INTEGER;

-- Operating system
-- macOS, NO OS,  Windows, Linux, Chrome Android(Other)

-- Using CASE statement(i.e if else statement) to replace macOS, NO OS,  Windows, Linux, Chrome Android(Other) to reduce catagories
UPDATE laptop_duplicate
SET OpSys = CASE 
			WHEN OpSys LIKE '%mac%' THEN 'mac'
			WHEN OpSys = 'NO OS' THEN 'N/A'
			WHEN OpSys LIKE 'Window%' THEN 'window'
			WHEN OpSys LIKE '%Linux%' THEN 'linux'
			ELSE 'other'
			END;
 
-- GPU 
-- CREATE TWO DIFFERENT COLUMNS GPU BRAND AND GPU NAME
SELECT * FROM laptop_duplicate;

-- ADD two columns
ALTER TABLE laptop_duplicate ADD COLUMN Gpu_brand VARCHAR(255) AFTER Gpu;
ALTER TABLE laptop_duplicate ADD COLUMN gpu_ VARCHAR(255) AFTER Gpu;

SELECT * FROM laptop_duplicate;

UPDATE laptop_duplicate l1
SET Gpu_brand = (SELECT SUBSTRING_INDEX(Gpu, ' ', 1) FROM laptop l2 WHERE l1.index = l2.index);

UPDATE laptop_duplicate l1
SET gpu_ = (SELECT REPLACE(Gpu , Gpu_brand, '') FROM laptop l2 WHERE l1.index = l2.index);

ALTER TABLE laptop_duplicate DROP COLUMN Gpu;

-- Cpu

-- ADD column to store information seperately
ALTER TABLE laptop_duplicate ADD COLUMN cpu_ VARCHAR(255) AFTER Cpu;
ALTER TABLE laptop_duplicate ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu;
ALTER TABLE laptop_duplicate ADD COLUMN cpu_speed DECIMAL(10,1) AFTER Cpu;

SELECT * FROM laptop_duplicate;

-- FILING UP cpu_brand
UPDATE laptop_duplicate l1
SET cpu_brand = (select SUBSTRING_INDEX(Cpu, ' ', 1) FROM laptop l2 WHERE l1.index = l2.index);

-- FILLING UP cpu_speed

UPDATE laptop_duplicate AS l1
SET cpu_speed = (SELECT REPLACE(SUBSTRING_INDEX(Cpu, ' ', -1), 'GHz', '') FROM laptop AS l2 WHERE l1.index = l2.index);

-- Filling up cpu_ 

UPDATE laptop_duplicate l1
SET cpu_ = (SELECT SUBSTRING_INDEX(Cpu, ' ', 3) FROM laptop l2 WHERE l1.index = l2.index);

UPDATE laptop_duplicate l
SET cpu_ = (SELECT REPLACE(cpu_, cpu_brand, '') FROM (SELECT * FROM laptop_duplicate) AS t WHERE t.index = l.index);

ALTER TABLE laptop_duplicate DROP COLUMN Cpu;
SELECT * FROM laptop_duplicate;


-- ScreenResolution

SELECT SUBSTRING_INDEX(pixle, 'x', 1) AS pixle_height, SUBSTRING_INDEX(pixle, 'x', -1) AS pixle_width
FROM (SELECT ScreenResolution,
		SUBSTRING_INDEX(ScreenResolution, ' ', -1) AS pixle
		FROM laptop_duplicate) AS t;
        
ALTER TABLE laptop_duplicate ADD COLUMN pixle_height INTEGER AFTER ScreenResolution;
ALTER TABLE laptop_duplicate ADD COLUMN pixle_width INTEGER AFTER ScreenResolution;

UPDATE laptop_duplicate 
SET pixle_height = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution, ' ', -1), 'x', -1),
pixle_width = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution, ' ', -1), 'x', 1);

SELECT ScreenResolution LIKE '%Touch%' FROM laptop_duplicate;

ALTER TABLE laptop_duplicate ADD COLUMN touchscreen INTEGER AFTER pixle_height;

UPDATE laptop_duplicate
SET touchscreen = ScreenResolution LIKE '%Touch%';

ALTER TABLE laptop_duplicate DROP COLUMN ScreenResolution;

-- cpu_
UPDATE laptop_duplicate
SET cpu_ = TRIM(cpu_);

SELECT * FROM laptop_duplicate;

-- Memory

ALTER TABLE laptop_duplicate 
ADD COLUMN memmory_type VARCHAR(255) AFTER Memory,
ADD COLUMN primary_storage INTEGER AFTER memmory_type,
ADD COLUMN secondary_storage INTEGER AFTER primary_storage;



SELECT Memory,
CASE
   WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
   WHEN Memory LIKE '%SSD%' AND Memory LIKE '%Hybrid%' THEN 'Hybrid'
   WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
   WHEN Memory LIKE '%SSD%' THEN 'SSD'
   WHEN Memory LIKE '%HDD%' THEN 'HDD'
   WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
   WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
   ELSE NULL
END AS memory_type
FROM laptop_duplicate;

UPDATE laptop_duplicate
SET memmory_type = CASE
   WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
   WHEN Memory LIKE '%SSD%' AND Memory LIKE '%Hybrid%' THEN 'Hybrid'
   WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
   WHEN Memory LIKE '%SSD%' THEN 'SSD'
   WHEN Memory LIKE '%HDD%' THEN 'HDD'
   WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
   WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
   ELSE NULL
END;

SELECT Memory, REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', 1), '[0-9]+'),
CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', -1), '[0-9]+') ELSE 0 
END
FROM laptop_duplicate;

UPDATE laptop_duplicate
SET primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', 1), '[0-9]+'),
secondary_storage = CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', -1), '[0-9]+') ELSE 0 END;

UPDATE laptop_duplicate
SET primary_storage = CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
secondary_storage = CASE WHEN secondary_storage <=2 THEN secondary_storage*1024 ELSE secondary_storage END;

ALTER TABLE laptop_duplicate DROP COLUMN Memory;
SELECT * FROM laptop_duplicate;