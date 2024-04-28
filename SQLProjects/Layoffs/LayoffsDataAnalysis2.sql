-- CREATE DATABASE IF NOT EXISTS Layoffs;
USE Layoffs;
SELECT COUNT(*) FROM Layoffs;
SELECT * FROM Layoffs;

#1 Data Exploration (good practice: make a copy and don't operate on the raw dataset. At the same time, only keep relevant columns.)
CREATE TABLE techlayoffs
LIKE layoffs;

INSERT INTO techlayoffs
SELECT * FROM layoffs; 

SELECT * FROM techlayoffs;
SHOW COLUMNS FROM techlayoffs;

-- date format
ALTER TABLE techlayoffs
MODIFY COLUMN `date` DATE;

-- explore the potential issues for each column
SELECT DISTINCT company FROM techlayoffs ORDER BY company; -- unwanted space
SELECT DISTINCT location FROM techlayoffs ORDER BY location; -- blank values
SELECT DISTINCT industry FROM techlayoffs ORDER BY industry; -- blank values
SELECT DISTINCT total_laid_off FROM techlayoffs ORDER BY total_laid_off;
SELECT DISTINCT percentage_laid_off FROM techlayoffs ORDER BY percentage_laid_off;
SELECT DISTINCT `date` FROM techlayoffs ORDER BY `date` DESC;
SELECT DISTINCT stage FROM techlayoffs ORDER BY stage; -- blank values
SELECT DISTINCT country FROM techlayoffs ORDER BY country;
SELECT DISTINCT funds_raised FROM techlayoffs ORDER BY funds_raised;





#2. Data Cleaning
##to trim unwanted space for col 'company'
SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs
SET company = TRIM(company);
SET SQL_SAFE_UPDATES = 1;

##Missing values: 
-- first, change blank values to NULL values
SELECT COUNT(*) FROM techlayoffs WHERE location = '';
SELECT COUNT(*) FROM techlayoffs WHERE industry = '';
SELECT COUNT(*) FROM techlayoffs WHERE stage = '';

SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs
SET location = NULL,
	industry = NULL,
	stage = NULL
WHERE location = '' OR industry = '' OR stage = '';
SET SQL_SAFE_UPDATES = 1;

-- second, how to deal with NULL values?
SELECT COUNT(*) FROM techlayoffs WHERE location IS NULL;
SELECT company, location FROM techlayoffs
WHERE location IS NULL;

SELECT COUNT(*) FROM techlayoffs WHERE industry IS NULL;
SELECT company, industry FROM techlayoffs
WHERE industry IS NULL;

SELECT COUNT(*) FROM techlayoffs WHERE stage IS NULL;
SELECT company, stage FROM techlayoffs
WHERE stage IS NULL;

-- check
SELECT * FROM techlayoffs
WHERE location IS NULL AND industry IS NULL AND stage IS NULL;

-- So, just delete these rows. 
SELECT COUNT(*) FROM techlayoffs;
SET SQL_SAFE_UPDATES = 0;
DELETE FROM techlayoffs
WHERE location IS NULL AND industry IS NULL AND stage IS NULL;

DELETE FROM techlayoffs
WHERE company = 'Product Hunt';
SET SQL_SAFE_UPDATES = 1;


##to remove duplicates
-- it will be easy to remove the duplicates if there's a unique ID column. 
SELECT * FROM techlayoffs;
#############################################
-- There's no such unique ID column, try to add such ID column to the table and populate each row with incrementing number
ALTER TABLE techlayoffs
ADD COLUMN ID INT FIRST;

SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs 
JOIN (SELECT @my_increment := 0) AS init
SET ID = (@my_increment := @my_increment + 1);
SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(ID), COUNT(DISTINCT ID) FROM techlayoffs; -- duplicates don't have same ID numbers, which we cannot use to identify the duplicates
#############################################
#############################################
-- INSTEAD,
-- Method 1: utilizing Hash idea
CREATE TABLE IF NOT EXISTS techlayoffs_hash
SELECT * FROM techlayoffs;

SELECT * FROM techlayoffs_hash;

ALTER TABLE techlayoffs_hash 
ADD COLUMN RowHash VARCHAR(32) AS (
	MD5(CONCAT_WS('|', company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised)) 
    -- This part defines the expression used to compute the value of the RowHash column for each row in the table.
    -- MD5 is a Hash function; The CONCAT_WS stands for "Concatenate With Separator".
    );

SELECT COUNT(RowHash), COUNT(DISTINCT RowHash) FROM techlayoffs_hash;

-- remove the duplicates: could create a new table, or create a temp_table such that can be deleted later
CREATE TEMPORARY TABLE techlayoffs_hash_deduplication
SELECT DISTINCT RowHash, company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
FROM techlayoffs_hash;

SELECT * FROM techlayoffs_hash_deduplication;
SELECT COUNT(*) FROM techlayoffs_hash_deduplication;

TRUNCATE TABLE techlayoffs_hash;
SELECT * FROM techlayoffs_hash;

INSERT INTO techlayoffs_hash (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised)
SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
FROM techlayoffs_hash_deduplication;

ALTER TABLE techlayoffs_hash
DROP COLUMN ID;

DROP TEMPORARY TABLE techlayoffs_hash_deduplication;
-- check
SELECT COUNT(*) FROM techlayoffs_hash;
##############################################
##############################################
-- Alternatively,
-- Method 2: utilizing ROW_NUMBER()
CREATE TABLE IF NOT EXISTS techlayoffs_deduplication
SELECT * FROM techlayoffs;

SELECT * FROM techlayoffs_deduplication;
SELECT COUNT(*) FROM techlayoffs_deduplication;

SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised) AS row_num
FROM techlayoffs_deduplication;


CREATE TABLE IF NOT EXISTS techlayoffs_rownumber_deduplication
SELECT * FROM techlayoffs_deduplication;

TRUNCATE TABLE techlayoffs_rownumber_deduplication;
SELECT * FROM techlayoffs_rownumber_deduplication;

ALTER TABLE techlayoffs_rownumber_deduplication
ADD COLUMN row_num INT;

INSERT INTO techlayoffs_rownumber_deduplication
SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised) AS row_num
FROM techlayoffs_deduplication;

SET SQL_SAFE_UPDATES = 0;
DELETE FROM techlayoffs_rownumber_deduplication
WHERE row_num > 1;
SET SQL_SAFE_UPDATES = 1;

-- check
SELECT COUNT(*) FROM techlayoffs_rownumber_deduplication;
#################################################################
#################################################################




#Data Analysis
SELECT * FROM techlayoffs_hash;

##try to add a new column that records the number of total employees
ALTER TABLE techlayoffs_hash
ADD COLUMN total_employees INT AFTER percentage_laid_off;

SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs_hash
SET total_employees = FLOOR(total_laid_off / percentage_laid_off)
WHERE percentage_laid_off != 0;
SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(*) FROM techlayoffs_hash
WHERE total_employees IS NULL;

SELECT COUNT(*) FROM techlayoffs_hash
WHERE percentage_laid_off = 0;
-- too many 0s in the col of percentage_laid_off, s.t too many NULL values in the col of total_employees
-- so, drop this column
ALTER TABLE techlayoffs_hash
DROP COLUMN total_employees;

##check what can be retrived from the cols of "total_laid_off" and "percentage_laid_off"
SELECT MAX(total_laid_off), MAX(percentage_laid_off) FROM techlayoffs_hash;

SELECT COUNT(DISTINCT company) FROM techlayoffs_hash;
SELECT COUNT(*) FROM techlayoffs_hash
WHERE percentage_laid_off = 1;
-- so, the percentage of companies fail
SELECT 
	(SELECT COUNT(*) FROM techlayoffs_hash
	WHERE percentage_laid_off = 1) AS company_fail,
    COUNT(DISTINCT company) AS total_company_num,
    (SELECT COUNT(*) FROM techlayoffs_hash
	WHERE percentage_laid_off = 1) * 100
    / 
    COUNT(DISTINCT company) AS percentage_company_fail
FROM techlayoffs_hash;
    
##explore each column in terms of total_laid_off
SELECT company, SUM(total_laid_off)
FROM techlayoffs_hash
GROUP BY company
ORDER BY SUM(total_laid_off ) DESC
LIMIT 5;

SELECT industry, SUM(total_laid_off)
FROM techlayoffs_hash
GROUP BY industry
ORDER BY SUM(total_laid_off ) DESC
LIMIT 5;

SELECT country, SUM(total_laid_off)
FROM techlayoffs_hash
GROUP BY country
ORDER BY SUM(total_laid_off ) DESC
LIMIT 5;

SELECT YEAR(`date`), SUM(total_laid_off)
FROM techlayoffs_hash
GROUP BY YEAR(`date`)
ORDER BY 1 DESC
LIMIT 5;

SELECT substring(`date`, 1, 7) AS MONTH, SUM(total_laid_off) AS total_laidoff
FROM techlayoffs_hash
GROUP BY substring(`date`, 1, 7)
ORDER BY 1;

WITH RollingUp AS (
	SELECT substring(`date`, 1, 7) AS `Month`, SUM(total_laid_off) AS total_laidoff
	FROM techlayoffs_hash
	GROUP BY substring(`date`, 1, 7)
	ORDER BY 1
	)
SELECT 
	`Month`,
    total_laidoff,
    SUM(total_laidoff) OVER(ORDER BY `Month`) AS Rolling_total
FROM RollingUp;


SELECT company, YEAR(`date`) AS `YEAR`, SUM(total_laid_off)
FROM techlayoffs_hash
GROUP BY company, YEAR(`date`)
ORDER BY SUM(total_laid_off ) DESC;

-- wanna see the trends of laidoffs by each company 
-- first
WITH Company_Year(Company, `Year`, Total_laid_offs) AS (
	SELECT company, YEAR(`date`) AS `YEAR`, SUM(total_laid_off)
	FROM techlayoffs_hash
	GROUP BY company, YEAR(`date`)
	)
SELECT * FROM Company_Year;

-- then, what's the ranking?
WITH Company_Year(Company, `Year`, Total_laid_offs) AS (
	SELECT company, YEAR(`date`) AS `YEAR`, SUM(total_laid_off)
	FROM techlayoffs_hash
	GROUP BY company, YEAR(`date`)
	)
SELECT 
	*,
    DENSE_RANK() OVER(PARTITION BY `Year` ORDER BY Total_laid_offs DESC) AS Ranking
FROM Company_Year;

-- next, check what are the top 5 per year
WITH Company_Year(Company, `Year`, Total_laid_offs) AS (
	SELECT company, YEAR(`date`) AS `YEAR`, SUM(total_laid_off)
	FROM techlayoffs_hash
	GROUP BY company, YEAR(`date`)
	),
    Company_Year_Ranking AS (
	SELECT 
		*,
		DENSE_RANK() OVER(PARTITION BY `Year` ORDER BY Total_laid_offs DESC) AS Ranking
	FROM Company_Year
	)
SELECT * FROM Company_Year_Ranking
WHERE Ranking <= 5;
    




#Data Visulization in Tableau
SELECT COUNT(*) FROM techlayoffs_hash;
SELECT * FROM techlayoffs_hash;

-- save data for Tableau
/*
1. could extract/save data by using "Export" option. however, need to SHOW ALL DATA IN THE RETURN TABLE(e.g., Limit to 50000 rows), otherwise, only limited rows can be exported.
2. could try 
	SELECT * FROM techlayoffs_hash
	INTO OUTFILE '/Users/jianjun/Desktop/JupyterWorkspace/TableauProjects/Layoffs/layoffs_1.csv'
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n';
    
    however, this method can not be done due to FILE privilege.
3. utilize python: connect mysql -> read data using pandas -> write data
*/







