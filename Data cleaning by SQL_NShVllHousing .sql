/*
Cleaning Data in SQL Queries
*/

---Check the dataset
Select *
From PortfolioProject.dbo.NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------

--1- Standardize Date Formatting 

Select saleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)


--Alternativeway to update data table

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date;

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

 --------------------------------------------------------------------------------------------------------------------------
--2- Populate Property Address data which need to splitted

Select PropertyAddress From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is null
order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------

/* -- Splitting Prop Address into Individual Columns (Address, City, State) *query extracts data from the PropertyAddress column and splits it into
two parts: Address and PropertySplitAddress. 
*The SUBSTRING function is used to extract a portion of the string based on character positions, and the CHARINDEX function finds
the position of a comma (,), which is used as a delimiter to split the address. The first part (Address) contains everything before 
the comma, and the second part (PropertySplitAddress) contains everything after the comma.*/


Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


Select *
From PortfolioProject.dbo.NashvilleHousing

/* UPDATE statements populate the newly created columns PropertySplitAddress and PropertySplitCity with the appropriate values. The SUBSTRING and CHARINDEX functions
are used again to split the original PropertyAddress into the address part and the city part, and these values are stored in the respective columns.
The end result of this code is to split the PropertyAddress column into two separate columns, PropertySplitAddress and PropertySplitCity,
with the address part and city part, respectively.*/
--------------------------------------
--------------------------------------
--------------------------------------------------Use PARSENAME
/*query is used to split the OwnerAddress into three parts: address, city, and state. 
 using the REPLACE function to replace commas (,) in OwnerAddress with periods (.). Then, 
 the PARSENAME function is used to parse the modified string. The third argument of PARSENAME 
 specifies the part to extract: 3 for the third part (state)
 */

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



Select *
From PortfolioProject.dbo.NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------
Select distinct(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by SoldAsVacant

-- Uniformity on the column answer: Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant) CountedSoldAsVacant
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

---------------------------
---------------------------

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From PortfolioProject.dbo.NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates


/*  CTE creates a temporary result set named RowsNumCTE. Inside the CTE, it performs the following:

*Select : It selects all columns from the NashvilleHousing table.

ROW_NUMBER() OVER (...): This is a window function that assigns a unique row number to each row based on the specified criteria within 
the PARTITION BY and ORDER BY clauses. In this case, rows are partitioned by the combination of columns (ParcelID, PropertyAddress, SalePrice, 
SaleDate, and LegalReference), and they are ordered by the UniqueID column. The assigned row numbers are stored in a new column named row_no.*/

WITH RowsNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_no  /*new column*/

From PortfolioProject.dbo.NashvilleHousing
--order by ParcelID /* doesnt work here in views*/)
)
Select *
From RowsNumCTE
Where row_no > 1
Order by PropertyAddress

Select *
From PortfolioProject.dbo.NashvilleHousing

-------------------delete duplicates from new table
/* we cannot directly delete rows from a CTE. Instead, we should use the CTE to identify the rows to be deleted and then perform the deletion on the actual table. 

*/WITH RowsNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) AS row_no
    FROM PortfolioProject.dbo.NashvilleHousing
)

-- Delete rows from the actual table based on CTE results
DELETE FROM PortfolioProject.dbo.NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM RowsNumCTE
    WHERE row_no > 1
);

-- select the remaining rows after deletion
-Select *
From PortfolioProject.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns that was splitted into multiple columns

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate

Select * From PortfolioProject.dbo.NashvilleHousing


-----------------------------------------------------------------------------------------------

--Split OwnerName into First name and Last name 


-- Add FirstName and LastName columns to the table
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD FirstName NVARCHAR(255),
    LastName NVARCHAR(255);

-- Update the FirstName and LastName columns using SUBSTRING and CHARINDEX
UPDATE PortfolioProject.dbo.NashvilleHousing
SET FirstName = CASE
    WHEN CHARINDEX(' ', ownerName) > 0 THEN
        SUBSTRING(ownerName, 1, CHARINDEX(' ', ownerName) - 1)
    ELSE
        ownerName
    END,
    LastName = CASE
    WHEN CHARINDEX(' ', ownerName) > 0 THEN
        SUBSTRING(ownerName, CHARINDEX(' ', ownerName) + 1, LEN(ownerName) - CHARINDEX(' ', ownerName))
    ELSE
        NULL
    END;
	---------------
	Select * From PortfolioProject.dbo.NashvilleHousing

	-- switch first nam and last name

	UPDATE NashvilleHousing
SET FirstName = LastName,
    LastName = FirstName;


-----------------------------------------------------------------------------------------------
--remove comma in the first name colimn
/*It uses the CHARINDEX function to check if a comma (,) exists in the FirstName column. If a comma is found, it proceeds with the update.
It uses the REPLACE function to replace all occurrences of commas in the FirstName column with an empty string ''.*/

UPDATE PortfolioProject.dbo.NashvilleHousing
SET FirstName = REPLACE(FirstName, ',', '')
WHERE CHARINDEX(',', FirstName) > 0;

Select * From PortfolioProject.dbo.NashvilleHousing

