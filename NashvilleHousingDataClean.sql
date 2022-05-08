-- Data Cleaning w/ SQL

SELECT * FROM PortfolioProject..NashvilleHousing


-- 1. Standardize Date Format
SELECT SaleDate, CONVERT(Date, SaleDate) FROM PortfolioProject..NashvilleHousing

-- alter column to change data type
ALTER TABLE  PortfolioProject..NashvilleHousing
ALTER COLUMN [SaleDate] Date

SELECT SaleDate FROM PortfolioProject..NashvilleHousing

-- 2. Populate Property Address Data
-- Unique ID is unique.  Parcel ID contain dupes where their property addresses should match up.
SELECT * FROM PortfolioProject..NashvilleHousing
order by ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
INNER JOIN PortfolioProject..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- This updates table with data from another table in SQL Server
-- update using subquery:
	--UPDATE table1
	--SET column1 = (SELECT expression1
	--FROM table2
	--WHERE conditions)
-- alternative syntax to this would be through a join.

-- update table a with the matched data of the reference table b.
-- note that table a in self join would be the entire table itself, and table b is the reference table or the table you intend to match with table a on
-- this means that using a left join in a self join would contain all data and not just the referenced date
-- the columns are updated with the values in the reference column

UPDATE a  -- remember to use alias when updating joins
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
INNER JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-- 3. Breaking out Address into individual columns (Address, City, State)
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) PropertySplitAddress
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) City
FROM PortfolioProject..NashvilleHousing


-- Because we can't separate two values from one column without creating two other columns,
-- We have to create two new columns and add them to our existing table
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255),
PropertySplitCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


SELECT * FROM PortfolioProject..NashvilleHousing



-- Alternative method
-- Parsename splits by periods ('.'), so we have to replace commas with periods.
SELECT PARSENAME(REPLACE(OwnerAddress,',', '.'), 3), 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
-- Parsename also splits things backwards.
FROM PortfolioProject..NashvilleHousing

-- A bit about replace, you can replace multiple things within the same column or string by nesting the replace function
-- i.e. REPLACE(REPLACE(TBL1,'A','B'),'C','D')

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


SELECT * FROM PortfolioProject..NashvilleHousing


-- 4. Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant  -- Else keep it as SoldAsVacant if it's not Y or N
END
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
	END


-- 5. Remove Duplicates
WITH row_numCTE AS (  -- CTEs are mostly used to help reduce redundancy in writing subqueries
SELECT *, ROW_NUMBER() OVER -- use row number to identify duplicate rows
(PARTITION BY ParcelID,     -- we partition/group things that would define a unique(non dupe) piece of information
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY UniqueID)  row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT * FROM row_numCTE
WHERE row_num >1

-- these shows all duplicate rows.

-- to delete all the duplicates:
WITH row_numCTE AS (  -- CTEs are mostly used to help reduce redundancy in writing subqueries
SELECT *, ROW_NUMBER() OVER -- use row number to identify duplicate rows
(PARTITION BY ParcelID,     -- we partition/group things that would define a unique(non dupe) piece of information
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY UniqueID)  row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE FROM row_numCTE
WHERE row_num >1

-- Check if there's any duplicates:
WITH row_numCTE AS (  -- CTEs are mostly used to help reduce redundancy in writing subqueries
SELECT *, ROW_NUMBER() OVER -- use row number to identify duplicate rows
(PARTITION BY ParcelID,     -- we partition/group things that would define a unique(non dupe) piece of information
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY UniqueID)  row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT * FROM row_numCTE
WHERE row_num >1

-- 6. Delete unused columns
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

SELECT * FROM PortfolioProject..NashvilleHousing