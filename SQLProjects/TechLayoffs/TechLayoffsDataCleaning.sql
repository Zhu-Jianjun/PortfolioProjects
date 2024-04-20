-- CREATE DATABASE IF NOT EXISTS TechLayoffs;
USE TechLayoffs;
SELECT COUNT(*) FROM TechLayoffs;
SELECT * FROM TechLayoffs;


#1 Data exploration (good practice: make a copy and don't operate on the raw dataset. At the same time, only keep relevant columns.)
CREATE TABLE techlayoffs_exploration
LIKE techlayoffs;

INSERT INTO techlayoffs_exploration
SELECT * FROM techlayoffs; 

SELECT * FROM techlayoffs_exploration; 
SELECT DISTINCT company FROM techlayoffs_exploration ORDER BY company; -- unwanted space
SELECT DISTINCT location, company FROM techlayoffs_exploration WHERE location IS NULL OR location = '';
SELECT DISTINCT industry, company FROM techlayoffs_exploration ORDER BY industry; -- blank and NULL values
SELECT DISTINCT total_laid_off, company FROM techlayoffs_exploration WHERE total_laid_off IS NULL OR total_laid_off = ''; -- NULL values
SELECT DISTINCT percentage_laid_off, company FROM techlayoffs_deduplication_hash WHERE percentage_laid_off IS NULL OR percentage_laid_off = ''; -- NULL values
SELECT DISTINCT `date` FROM techlayoffs_deduplication_hash; -- not date format (known when importing the data, it is text)
SELECT DISTINCT stage, company FROM techlayoffs_deduplication_hash ORDER BY stage; -- NULL value, Unknown?
SELECT DISTINCT country, company FROM techlayoffs_deduplication_hash ORDER BY country; -- United States vs. United States.
SELECT DISTINCT funds_raised_millions, company FROM techlayoffs_deduplication_hash;




#2 Duplicates?
-- it will be easy to remove the duplicates if there's a unique ID column. 
#############################################
-- if there's no such unique ID column, try to add such ID column to the table and populate each row with incrementing number
ALTER TABLE techlayoffs_exploration
ADD COLUMN ID INT FIRST;
#DROP COLUMN ID;

SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs_exploration 
JOIN (SELECT @my_increment := 0) AS init
SET ID = (@my_increment := @my_increment + 1);
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM techlayoffs_exploration; 
SELECT COUNT(ID), COUNT(DISTINCT ID) FROM techlayoffs_exploration; 
-- duplicates still have same ID numbers, which we cannot use to identify the duplicates
#############################################
#############################################
-- instead, utilizing Hash idea
CREATE TABLE IF NOT EXISTS techlayoffs_deduplication_hash
SELECT * FROM techlayoffs;

SELECT * FROM techlayoffs_deduplication_hash;

ALTER TABLE techlayoffs_deduplication_hash 
ADD COLUMN RowHash VARCHAR(32) AS (
	MD5(CONCAT_WS('|', company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions)) 
    -- This part defines the expression used to compute the value of the RowHash column for each row in the table.
    -- MD5 is a Hash function; The CONCAT_WS stands for "Concatenate With Separator".
    );

SELECT COUNT(RowHash), COUNT(DISTINCT RowHash) FROM techlayoffs_deduplication_hash;

-- remove the duplicates: could create a new table, or create a temp_table such that can be deleted later
CREATE TEMPORARY TABLE techlayoffs_deduplication_hash1
SELECT DISTINCT RowHash, company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
FROM techlayoffs_deduplication_hash;

SELECT * FROM techlayoffs_deduplication_hash1;
SELECT COUNT(*) FROM techlayoffs_deduplication_hash1;

TRUNCATE TABLE techlayoffs_deduplication_hash;
SELECT * FROM techlayoffs_deduplication_hash;

INSERT INTO techlayoffs_deduplication_hash (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions)
SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
FROM techlayoffs_deduplication_hash1;

DROP TEMPORARY TABLE techlayoffs_deduplication_hash1;
-- check
SELECT COUNT(*) FROM techlayoffs_deduplication_hash;
##############################################
##############################################
-- Alternatively,
CREATE TABLE IF NOT EXISTS techlayoffs_deduplication
SELECT * FROM techlayoffs;

SELECT * FROM techlayoffs_deduplication;
SELECT COUNT(*) FROM techlayoffs_deduplication;

SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM techlayoffs_deduplication;


CREATE TABLE IF NOT EXISTS techlayoffs_deduplication1
SELECT * FROM techlayoffs_deduplication;

TRUNCATE TABLE techlayoffs_deduplication1;
SELECT * FROM techlayoffs_deduplication1;

ALTER TABLE techlayoffs_deduplication1
ADD COLUMN row_num INT;

INSERT INTO techlayoffs_deduplication1
SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM techlayoffs_deduplication;

#SET SQL_SAFE_UPDATES = 0;
DELETE FROM techlayoffs_deduplication1
WHERE row_num > 1;
#SET SQL_SAFE_UPDATES = 1;

-- check
SELECT COUNT(*) FROM techlayoffs_deduplication1;
#################################################################



#3 Standadize data 
-- date format
SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs_deduplication_hash
SET `date` = str_to_date(`date`, '%m/%d/%Y');
SET SQL_SAFE_UPDATES = 1;

SHOW COLUMNS FROM techlayoffs_deduplication_hash; -- `date` is still text 

ALTER TABLE techlayoffs_deduplication_hash
MODIFY COLUMN `date` DATE;

SELECT * FROM techlayoffs_deduplication_hash;

-- United States vs. United States.
#SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs_deduplication_hash
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
#SET SQL_SAFE_UPDATES = 1;

SELECT DISTINCT country FROM techlayoffs_deduplication_hash ORDER BY country;




#4 Missing values and NULL values
-- industry
SELECT * FROM techlayoffs_deduplication_hash 
WHERE industry IS NULL OR industry = '';

#SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs_deduplication_hash
SET industry = NULL 
WHERE industry = '';
#SET SQL_SAFE_UPDATES = 1;

/*
figure out how to deal w/ such cases
e.g., return other rows for each column s.t might be helpful to update the NULL values
*/
SELECT company, industry FROM techlayoffs_deduplication_hash
WHERE company = 'Airbnb'; -- could replace NULL value w/ Travel

SELECT company, industry FROM techlayoffs_deduplication_hash
WHERE company = 'Bally''s Interactive';  -- not other rows that can refer to. so, maybe delete this row is ok.

SELECT company, industry FROM techlayoffs_deduplication_hash
WHERE company = 'Juul'; -- could replace NULL value w/ Consuer

SELECT company, industry FROM techlayoffs_deduplication_hash
WHERE company = 'Carvana'; -- could replace NULL value w/ Transportation

/*to update*/
SELECT 
	temp1.industry AS industry1,
    temp2.industry AS industry2
FROM techlayoffs_deduplication_hash AS temp1
INNER JOIN techlayoffs_deduplication_hash AS temp2
ON temp1.company = temp2.company
WHERE temp1.industry IS NULL AND temp2.industry IS NOT NULL 
ORDER BY temp1.company;


#SET SQL_SAFE_UPDATES = 0;
UPDATE techlayoffs_deduplication_hash AS temp1
INNER JOIN techlayoffs_deduplication_hash AS temp2
ON temp1.company = temp2.company
SET temp1.industry = temp2.industry
WHERE temp1.industry IS NULL AND temp2.industry IS NOT NULL; 
#SET SQL_SAFE_UPDATES = 1;



-- total_laid_off
SELECT * FROM techlayoffs_deduplication_hash
#SELECT Count(*) FROM techlayoffs_deduplication_hash
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL; -- could delete rows, or maybe these two cols are not necessary.

SELECT COUNT(*) FROM techlayoffs_deduplication_hash
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE FROM techlayoffs_deduplication_hash
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- check
SELECT COUNT(*) FROM techlayoffs_deduplication_hash; -- 2356-361=1995


-- stage
SELECT * FROM techlayoffs_deduplication_hash 
WHERE stage IS NULL;

SELECT company, stage FROM techlayoffs_deduplication_hash
WHERE company = 'Verily'; -- only one row, could just delete this row

SELECT company, stage FROM techlayoffs_deduplication_hash
WHERE company = 'Relevel'; -- only one row, could just delete this row

SELECT company, stage FROM techlayoffs_deduplication_hash
WHERE company = 'Advata'; -- only one row, could just delete this row

SELECT company, stage FROM techlayoffs_deduplication_hash
WHERE company = 'Spreetail'; -- only one row, could just delete this row

SELECT company, stage FROM techlayoffs_deduplication_hash
WHERE company = 'Gatherly'; -- only one row, could just delete this row

SELECT company, stage FROM techlayoffs_deduplication_hash
WHERE company = 'Zapp'; -- only one row, could just delete this row















