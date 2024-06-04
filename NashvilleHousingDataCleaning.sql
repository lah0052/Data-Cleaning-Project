/*
Cleaning Data in SQL Queries
*/
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing$
--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing$

UPDATE NashvilleHousing$
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't UPDATE properly
ALTER TABLE NashvilleHousing$
Add SaleDateConverted Date;

UPDATE NashvilleHousing$
SET SaleDateConverted = CONVERT(Date,SaleDate)
 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing$ AS a
JOIN PortfolioProject.dbo.NashvilleHousing$ AS b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing$ AS a
JOIN PortfolioProject.dbo.NashvilleHousing$ AS b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null
--------------------------------------------------------------------------------------------------------------------------

-- Breaking PropertyAddress into Individual Columns (Address, City)
SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS Address
FROM PortfolioProject.dbo.NashvilleHousing$

--adds PropertySplitAddress,PropertySplitCity columns to the NashvilleHousing$ table
ALTER TABLE NashvilleHousing$
Add PropertySplitAddress Nvarchar(255);

ALTER TABLE NashvilleHousing$
Add PropertySplitCity Nvarchar(255);

----adds values for the PropertySplitAddress,PropertySplitCity columns in the NashvilleHousing$ table
UPDATE NashvilleHousing$
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

UPDATE NashvilleHousing$
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))
--------------------------------------------------------------------------------------------------------------------------

--Breaking OwnerAdress into Individual Columns (Address, City, State)
--with PARSENAME instead of SUBSTRING used to spilt PropertyAddress above
--PARSENAME works backwardsish so its 3,2,1 not 1,2,3
SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject..NashvilleHousing$

--adds OwnerSplitAddress,OwnerSplitCity,OwnerSplitState columns to the NashvillHousing$ table
ALTER TABLE NashvilleHousing$
Add OwnerSplitAddress Nvarchar(255);

ALTER TABLE NashvilleHousing$
Add OwnerSplitCity Nvarchar(255);

ALTER TABLE NashvilleHousing$
Add OwnerSplitState Nvarchar(255);

--adds values for OwnerSplitAddress,OwnerSplitCity,OwnerSplitState columns in the NashvillHousing$ table
UPDATE NashvilleHousing$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE NashvilleHousing$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE NashvilleHousing$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)
--------------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in SoldAsVacant column
----shows number of Y, N, Yes, No
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing$
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing$

UPDATE NashvilleHousing$
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
--------------------------------------------------------------------------------------------------------------------------

--Removing Duplicates using a CTE with ROW_NUMBER to find the duplicate rows and then a delete to remove them
WITH RowNumCTE AS(
Select*,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
				 
FROM PortfolioProject..NashvilleHousing$
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--------------------------------------------------------------------------------------------------------------------------

--Delete unused columns
ALTER TABLE PortfolioProject..NashvilleHousing$
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate

