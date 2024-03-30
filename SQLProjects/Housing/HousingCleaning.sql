USE NashvilleHousing;

SELECT * FROM nashvillehousing;
SELECT COUNT(*), MAX(SaleDate), MIN(SaleDate) FROM nashvillehousing;


-- #1: standardize date format
SELECT SaleDate FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD SaleDateConverted DATE;

SET SQL_SAFE_UPDATES=0;
UPDATE nashvillehousing
SET SaleDateConverted = CONVERT(SaleDate, DATE);

SELECT SaleDate, SaleDateConverted FROM nashvillehousing;


-- #2: populate the property address data
SELECT PropertyAddress FROM nashvillehousing
WHERE PropertyAddress IS NULL;

SELECT ParcelID, PropertyAddress FROM  nashvillehousing
ORDER BY ParcelID; 
-- same ParcelID will have same PropertyAddress. 
-- So this part is to populate ParcelID with corresponding PropertyAddress.

SET SQL_SAFE_UPDATES=0;
UPDATE nashvillehousing
SET PropertyAddress = NULL
WHERE PropertyAddress = '';

SELECT 
	a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing a
INNER JOIN nashvillehousing b
ON a.ParcelID = b.ParcelID AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashvillehousing a
INNER JOIN nashvillehousing b
ON a.ParcelID = b.ParcelID AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;
-- Note: the order of the clauses



-- #3: breaking Address (PropertyAddress, OwnerAddress) into individual columns (Address, City, State)
SELECT * FROM nashvillehousing;
-- first, to split PropertySplitCity
SELECT 
	substring(PropertyAddress, 1, locate(',', PropertyAddress) - 1) AS PropertySplitAddress,
    substring(PropertyAddress, locate(',', PropertyAddress) + 1, length(PropertyAddress)) AS PropertySplitCity
FROM nashvillehousing;

-- Next, need to add new columns for these split columns
ALTER TABLE nashvillehousing
ADD PropertySplitAddress VARCHAR(255);

ALTER TABLE nashvillehousing
ADD PropertySplitCity VARCHAR(255);

UPDATE nashvillehousing
SET PropertySplitAddress = substring(PropertyAddress, 1, locate(',', PropertyAddress) - 1);

UPDATE nashvillehousing
SET PropertySplitCity = substring(PropertyAddress, locate(',', PropertyAddress) + 1, length(PropertyAddress));


-- Similarly, to split OwnerAddress
SELECT * FROM nashvillehousing;
SELECT 
	SUBSTRING_INDEX(OwnerAddress, ',', -1) AS OwnerSplitState, # -1 means "counting starts from right"
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) AS OwnerSplitCity,
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerSplitAddress
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD OwnerSplitState VARCHAR(255),
ADD OwnerSplitCity VARCHAR(255),
ADD OwnerSplitAddress VARCHAR(255);

UPDATE nashvillehousing
SET 
	OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1),
	OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1),
	OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);
    


-- #4: change Y and N to Yes and No in column SoldASVacant
SELECT DISTINCT SoldASVacant FROM nashvillehousing; 

SELECT 
	SoldASVacant,
    CASE
		WHEN SoldASVacant = 'Y' THEN 'Yes'
        WHEN SoldASVacant = 'N' THEN 'No'
	ELSE SoldASVacant
    END AS SoldASVacantConsistent
FROM nashvillehousing;

SELECT * FROM nashvillehousing;
ALTER TABLE nashvillehousing
ADD SoldASVacantConsistent VARCHAR(255);

UPDATE nashvillehousing
SET SoldASVacantConsistent = 
	CASE
		WHEN SoldASVacant = 'Y' THEN 'Yes'
        WHEN SoldASVacant = 'N' THEN 'No'
	ELSE SoldASVacant
    END;

SELECT DISTINCT SoldASVacantConsistent FROM nashvillehousing;



-- #5: remove duplicates: find the duplicates first and then delete

/*
Def.: The ROW_NUMBER() is a window function or analytic function that assigns a sequential number 
to each row in the result set. The first number begins with one.
Syntax: ROW_NUMBER() OVER (<partition_definition> <order_definition>)
partition_definition syntax: PARTITION BY <expression>,[{,<expression>}...]
order_definition syntax: ORDER BY <expression> [ASC|DESC],[{,<expression>}...]
*/

SET SQL_SAFE_UPDATES=0;
WITH RowNumCTE AS (
SELECT 
	*,
    ROW_NUMBER() OVER (
		PARTITION BY 
			ParcelID,
			PropertyAddress,
            SalePrice,
            SaleDate,
            LegalReference
		ORDER BY 
			UniqueId
    ) AS row_num
FROM nashvillehousing
WHERE row_num > 1; 
)
-- Clauses from SELECT TO WHERE (line 132 to 145) return error: Unknown column 'row_num' in 'where clause'.
/* 
This error occurs because the row_num column is calculated after the FROM and WHERE clauses are processed. 
The WHERE clause doesn't have access to the alias row_num at that point.
In MySQL, you cannot use an alias defined in the SELECT list directly in the WHERE clause. 
To filter the results based on the calculated row_num value, you need to use a subquery or a derived table.
*/
SELECT *
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (
			PARTITION BY 
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
			ORDER BY 
				UniqueId
		) AS row_num
	FROM nashvillehousing
) AS RowNum
WHERE row_num > 1
ORDER BY PropertyAddress;


SELECT COUNT(*) FROM nashvillehousing;
DELETE FROM nashvillehousing
WHERE UniqueID IN (SELECT UniqueID FROM RowNum WHERE row_num > 1); -- not necessary to use UniqueID, can use any column from nashvillehousing 
/* 
Error Code: 1146. Table 'nashvillehousing.rownum' doesn't exist
Since not using CTE method, we could instead create a VIEW as follows
*/
CREATE VIEW RowNum AS 
SELECT *
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (
			PARTITION BY 
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
			ORDER BY 
				UniqueId
		) AS row_num
	FROM nashvillehousing
) AS temp;

SELECT * FROM RowNum
WHERE row_num > 1
ORDER BY PropertyAddress;


SELECT COUNT(*) FROM nashvillehousing;
DELETE FROM nashvillehousing
WHERE UniqueID IN (SELECT UniqueID FROM RowNum WHERE row_num > 1); 



