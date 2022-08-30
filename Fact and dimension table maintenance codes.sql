create database Sales

--Product Dimension
--SCD2

INSERT INTO dim_product1 (
	Productkey
	,Product_Name
	,Product_Size
	,Product_ModelName
	,UnitPrice
	)
SELECT Productkey
	,Product_Name
	,Product_Size
	,Product_ModelName
	,UnitPrice
FROM (
	MERGE dim_product1 AS target
	USING (
		SELECT DISTINCT Productkey
			,ProductName
			,Size
			,ModelName
			,UnitPrice
		FROM dbo.stagSalesDWH
		) AS Source
		ON target.Productkey = source.Productkey
	WHEN MATCHED
		AND (
			target.Product_Name <> source.ProductName
			OR target.Product_size <> source.size
			OR target.Product_ModelName <> source.ModelName
			OR target.UnitPrice <> source.UnitPrice
			)
		THEN
			UPDATE
			SET isActive = 'N'
				,end_date = getdate()
	WHEN NOT MATCHED
		THEN
			INSERT (
				Productkey
				,Product_Name
				,Product_Size
				,Product_ModelName
				,UnitPrice
				)
			VALUES (
				source.Productkey
				,source.ProductName
				,source.Size
				,source.ModelName
				,source.UnitPrice
				)
	OUTPUT $ACTION
		,source.Productkey
		,source.ProductName
		,source.Size
		,source.ModelName
		,source.UnitPrice
	) AS changes(action, Productkey, Product_Name, Product_Size, Product_ModelName, UnitPrice)
WHERE action = 'update'
	--select * from dim_product1







--Customer Dimension
--SCD1

CREATE TABLE dim_Customer 
	(
	CustomerId INT identity(1, 1) PRIMARY KEY
	,CustomerAlternateKey NVARCHAR(50)
	,CustomerFirstName NVARCHAR(50)
	,CustomerLastName NVARCHAR(50)
	,CustomerBirthDate DATE
	,EmailAddress NVARCHAR(50)
	,Created_date DATE
	,Modified_date DATE
	)

-- SCD 1 for dimCustomer
MERGE dim_customer AS target
USING (
	SELECT [CustomerAlternateKey]
		,[CustomerFirstName]
		,[CustomerLastName]
		,[CustomerBirthDate]
		,[EmailAddress]
	FROM dbo.stagSalesDWH
	) AS source
	ON target.CustomerAlternateKey = source.CustomerAlternateKey
WHEN MATCHED
	AND (
		target.[CustomerFirstName] <> source.[CustomerFirstName]
		OR target.[CustomerLastName] <> source.[CustomerLastName]
		OR target.[CustomerBirthDate] <> source.[CustomerBirthDate]
		OR target.[EmailAddress] <> source.[EmailAddress]
		)
	THEN
		UPDATE
		SET target.[CustomerFirstName] = source.[CustomerFirstName]
			,target.[CustomerLastName] = source.[CustomerLastName]
			,target.[CustomerBirthDate] = source.[CustomerBirthDate]
			,target.[EmailAddress] = source.[EmailAddress]
			,target.modified_date = getdate()
WHEN NOT MATCHED BY target
	THEN
		INSERT (
			[CustomerAlternateKey]
			,[CustomerFirstName]
			,[CustomerLastName]
			,[CustomerBirthDate]
			,[EmailAddress]
			,[created_Date]
			)
		VALUES (
			source.[CustomerAlternateKey]
			,source.[CustomerFirstName]
			,source.[CustomerLastName]
			,source.[CustomerBirthDate]
			,source.[EmailAddress]
			,getdate()
			);


--SCD2

CREATE TABLE dim_Customer -- SCD 2
	(
	CustomerId INT identity(1, 1) PRIMARY KEY
	,CustomerAlternateKey NVARCHAR(50)
	,CustomerFirstName NVARCHAR(50)
	,CustomerLastName NVARCHAR(50)
	,CustomerBirthDate DATE
	,EmailAddress NVARCHAR(50)
	,Created_date DATE
	,End_date DATE
	,isActive CHAR DEFAULT 'Y'
	)

INSERT INTO dim_Customer (
	CustomerAlternateKey
	,customerFirstName
	,CustomerLastName
	,CustomerBirthDate
	,EmailAddress
	,Created_date
	)
SELECT CustomerAlternateKey
	,customerFirstName
	,CustomerLastName
	,CustomerBirthDate
	,EmailAddress
	,created_date
FROM (
	MERGE Dim_Customer AS target
	USING (
		SELECT DISTINCT CustomerAlternateKey
			,customerFirstName
			,CustomerLastName
			,CustomerBirthDate
			,EmailAddress
		FROM dbo.stagSalesDWH
		) AS Source
		ON target.CustomerAlternateKey = source.CustomerAlternateKey
	WHEN MATCHED
		AND (
			target.CustomerFirstName <> source.CustomerFirstName
			OR target.CustomerLastName <> source.CustomerLastName
			OR target.CustomerBirthDate <> source.CustomerBirthDate
			OR target.EmailAddress <> source.EmailAddress
			)
		AND isactive = 'Y'
		THEN
			UPDATE
			SET isActive = 'N'
				,end_date = getdate()
	WHEN NOT MATCHED
		THEN
			INSERT (
				CustomerAlternateKey
				,CustomerFirstName
				,CustomerLastName
				,CustomerBirthDate
				,EmailAddress
				,created_date
				)
			VALUES (
				Source.CustomerAlternateKey
				,Source.CustomerFirstName
				,Source.CustomerLastName
				,Source.CustomerBirthDate
				,Source.EmailAddress
				,getdate()
				)
	OUTPUT $ACTION
		,Source.CustomerAlternateKey
		,Source.CustomerFirstName
		,Source.CustomerLastName
		,Source.CustomerBirthDate
		,Source.EmailAddress
		,getdate()
	) -- end of merge
	AS changes(action, CustomerAlternateKey, CustomerFirstName, CustomerLastName, CustomerBirthDate, EmailAddress, created_date)
WHERE action = 'update'
	--select * from dim_Customer




--Currency Dimension
--SCD1

CREATE TABLE dim_currency (
	currency_id INT PRIMARY KEY identity(1, 1)
	,-- surrogate key 
	currencykey VARCHAR(10)
	,currencyName VARCHAR(30)
	)

MERGE dim_currency AS target
USING (
	SELECT DISTINCT currencyKey
		,currencyName
	FROM dbo.stagSalesDWH
	) AS source
	ON target.currencykey = source.currencykey
WHEN MATCHED
	AND Target.currencyName <> source.currencyName
	THEN
		UPDATE
		SET Target.currencyName = source.currencyName
WHEN NOT MATCHED BY target
	THEN
		INSERT (
			currencykey
			,currencyName
			)
		VALUES (
			source.currencykey
			,source.currencyName
			);-- end of merge
			--select * from dim_currency


--Promotion Dimension
--SCD2

---Update in promotion using scd-2 Promotion
INSERT INTO dim_promotion (
	promotiontype
	,promotionname
	,promotioncategory
	,createddate
	,isactive
	)
SELECT promotiontype
	,promotionname
	,promotioncategory
	,createddate
	,isactive
FROM (
	MERGE dim_promotion AS target
	USING (
		SELECT DISTINCT promotionname
			,promotiontype
			,promotioncategory
		FROM dbo.sales
		) AS source
		ON source.promotionname = target.promotionname
	WHEN MATCHED
		AND (
			source.promotiontype <> target.promotiontype
			OR source.promotionname <> target.promotionname
			OR source.promotiontype <> target.promotiontype
			)
		AND isactive = 'Y'
		THEN
			UPDATE
			SET isactive = 'N'
				,modifieddate = getdate()
	WHEN NOT MATCHED BY target
		THEN
			INSERT (
				promotiontype
				,promotionname
				,promotioncategory
				,createddate
				,isactive
				)
			VALUES (
				source.promotiontype
				,source.promotionname
				,source.promotioncategory
				,getdate()
				,'Y'
				)
	OUTPUT $ACTION
		,source.promotiontype
		,source.promotionname
		,source.promotioncategory
		,getdate()
		,'Y'
	) AS changes(action, promotiontype, promotionname, promotioncategory, createddate, isactive)
WHERE action = 'update'

SELECT *
FROM dim_promotion



--Date Dimension
SCD 1


CREATE TABLE dim_date (
	   Date_key INT PRIMARY KEY    
	,[Date] DATE    
	,[DayofWeek] INT    
	,[DayName] VARCHAR(9)    
	,[day_of_month] VARCHAR(2)    
	,[Month] VARCHAR(2)    
	,[MonthName] VARCHAR(9)    
	,[Quarter] CHAR(1)    
	,[quarterName] VARCHAR(9)    
	,[year] CHAR(4)    
	)




DECLARE @startDate DATE = (       SELECT DISTINCT TOP 1 orderDate        FROM dbo.stagSalesDWH        ORDER BY orderdate        )
DECLARE @endDate DATE = (       SELECT DISTINCT TOP 1 orderdate        FROM dbo.stagSalesDWH        ORDER BY orderdate DESC        )
DECLARE @CurrentYear INT    
	,@CurrentMonth INT    
	,@CurrentQuarter INT
DECLARE @CurrentDate AS DATETIME = @StartDate

SET @CurrentMonth = DATEPART(MM, @CurrentDate)
SET @CurrentYear = DATEPART(YY, @CurrentDate)
SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)

WHILE (@CurrentDate < @endDate)
BEGIN
	   IF(@currentMonth != datepart(MM, @CurrentDate))    BEGIN        SET @currentMonth = datepart(MM, @CurrentDate)    END    IF(@CurrentYear != Datepart(yy, @currentDate))    BEGIN        SET @CurrentYear = Datepart(yy, @currentDate)    END    IF(@CurrentQuarter != Datepart(qq, @currentdate))    BEGIN        SET @CurrentQuarter = Datepart(qq, @currentdate)    END    INSERT
	INTO dim_date    SELECT convert(CHAR(8), @CurrentDate, 112) AS DateKey        
		,@currentdate AS DATE        
		,datepart(dw, @currentDate) AS day_of_month        
		,datename(dw, @currentdate) AS [dayname]        
		,datepart(dd, @CurrentDate) AS [DayOfWeek]        
		,datepart(mm, @currentDate) AS [Month]        
		,datename(mm, @currentDate) AS [MonthName]        
		,datepart(qq, @currentDate) AS [Quarter]   
                          ,CASE datepart(qq, @currentDate)
		WHEN 1
			THEN 'First'
		WHEN 2
			THEN 'Second'
		WHEN 3
			THEN 'Third'
		WHEN 4
			THEN 'Fourth'
		END AS QuraterName
	,datepart(year, @CurrentDate) AS [year]

SET  @CurrentDate = DateAdd(DD,1,@CurrentDate) END
    

--Fact table

CREATE SCHEMA fact

CREATE TABLE fact.sales (
	   productId INT FOREIGN KEY REFERENCES dbo.dim_product1(productId)    
	,customerId INT FOREIGN KEY REFERENCES dbo.dim_Customer(customerId)    
	,promotionId INT FOREIGN KEY REFERENCES dbo.dim_promotion(promotionId)    
	,currency_Id INT FOREIGN KEY REFERENCES dbo.dim_currency(currency_ID)    
	,Date_Key INT FOREIGN KEY REFERENCES dbo.dim_date(Date_Key)    
	,SalesOrderNumber NVARCHAR(25)    
	,SalesOrderLineNumber CHAR(5)    
	,RevisionNumber CHAR(4)    
	,OrderQuantity INT    
	,ExtendedAmount FLOAT    
	,DiscountAmount FLOAT    
	,ProductStandardCost FLOAT    
	,TotalProductCost FLOAT    
	,SalesAmount FLOAT    
	,TaxAmt FLOAT    
	,Freight FLOAT    
	,OrderDate DATE    
	,DueDate DATE    
	,ShipDate DATE    
	)

SELECT *
FROM fact.sales;





CREATE PROCEDURE factTableUpdate
AS
INSERT INTO fact.sales (
	   productid    
	,customerid    
	,promotionid    
	,currency_ID    
	,Date_Key    
	,SalesOrderNumber    
	,SalesOrderLineNumber    
	,RevisionNumber    
	,OrderQuantity    
	,ExtendedAmount    
	,DiscountAmount    
	,ProductStandardCost    
	,TotalProductCost    
	,SalesAmount    
	,TaxAmt    
	,Freight    
	,OrderDate    
	,DueDate    
	,ShipDate    
	)
SELECT pd.productid    
	,c.customerid    
	,p.promotionid    
	,cur.currency_ID    
	,DATE.Date_Key    
	,stg.SalesOrderNumber    
	,stg.SalesOrderLineNumber    
	,stg.RevisionNumber    
	,stg.OrderQuantity    
	,stg.ExtendedAmount    
	,stg.DiscountAmount    
	,stg.ProductStandardCost    
	,stg.TotalProductCost    
	,stg.SalesAmount    
	,stg.TaxAmt    
	,stg.Freight    
	,stg.OrderDate    
	,stg.DueDate    
	,stg.ShipDate
FROM dbo.stagSalesDWH stg
LEFT JOIN (
	   SELECT productid        
	,productKey    FROM dbo.dim_product1    
	) pd ON stg.productkey = pd.productkey
LEFT JOIN (
	   SELECT customerid        
	,customerAlternateKey    FROM dbo.dim_Customer    
	) c ON stg.customerAlternateKey = c.customerAlternatekey
LEFT JOIN (
	   SELECT promotionId        
	,promotionName    FROM dbo.dim_promotion    
	) p ON stg.promotionName = p.promotionName
LEFT JOIN (
	   SELECT currency_ID        
	,CurrencyKey    FROM dbo.dim_currency    
	) cur ON stg.currencykey = cur.currencykey
LEFT JOIN (
	   SELECT date_Key        
	,DATE    FROM dbo.dim_date    
	) DATE ON stg.orderdate = DATE.DATE

EXEC factTableUpdate

SELECT *
FROM fact.sales
--Product Dimension
--SCD2

INSERT INTO dim_product1 (
	Productkey
	,Product_Name
	,Product_Size
	,Product_ModelName
	,UnitPrice
	)
SELECT Productkey
	,Product_Name
	,Product_Size
	,Product_ModelName
	,UnitPrice
FROM (
	MERGE dim_product1 AS target
	USING (
		SELECT DISTINCT Productkey
			,ProductName
			,Size
			,ModelName
			,UnitPrice
		FROM dbo.stagSalesDWH
		) AS Source
		ON target.Productkey = source.Productkey
	WHEN MATCHED
		AND (
			target.Product_Name <> source.ProductName
			OR target.Product_size <> source.size
			OR target.Product_ModelName <> source.ModelName
			OR target.UnitPrice <> source.UnitPrice
			)
		THEN
			UPDATE
			SET isActive = 'N'
				,end_date = getdate()
	WHEN NOT MATCHED
		THEN
			INSERT (
				Productkey
				,Product_Name
				,Product_Size
				,Product_ModelName
				,UnitPrice
				)
			VALUES (
				source.Productkey
				,source.ProductName
				,source.Size
				,source.ModelName
				,source.UnitPrice
				)
	OUTPUT $ACTION
		,source.Productkey
		,source.ProductName
		,source.Size
		,source.ModelName
		,source.UnitPrice
	) AS changes(action, Productkey, Product_Name, Product_Size, Product_ModelName, UnitPrice)
WHERE action = 'update'
	--select * from dim_product1







--Customer Dimension
--SCD1

CREATE TABLE dim_Customer 
	(
	CustomerId INT identity(1, 1) PRIMARY KEY
	,CustomerAlternateKey NVARCHAR(50)
	,CustomerFirstName NVARCHAR(50)
	,CustomerLastName NVARCHAR(50)
	,CustomerBirthDate DATE
	,EmailAddress NVARCHAR(50)
	,Created_date DATE
	,Modified_date DATE
	)

-- SCD 1 for dimCustomer
MERGE dim_customer AS target
USING (
	SELECT [CustomerAlternateKey]
		,[CustomerFirstName]
		,[CustomerLastName]
		,[CustomerBirthDate]
		,[EmailAddress]
	FROM dbo.stagSalesDWH
	) AS source
	ON target.CustomerAlternateKey = source.CustomerAlternateKey
WHEN MATCHED
	AND (
		target.[CustomerFirstName] <> source.[CustomerFirstName]
		OR target.[CustomerLastName] <> source.[CustomerLastName]
		OR target.[CustomerBirthDate] <> source.[CustomerBirthDate]
		OR target.[EmailAddress] <> source.[EmailAddress]
		)
	THEN
		UPDATE
		SET target.[CustomerFirstName] = source.[CustomerFirstName]
			,target.[CustomerLastName] = source.[CustomerLastName]
			,target.[CustomerBirthDate] = source.[CustomerBirthDate]
			,target.[EmailAddress] = source.[EmailAddress]
			,target.modified_date = getdate()
WHEN NOT MATCHED BY target
	THEN
		INSERT (
			[CustomerAlternateKey]
			,[CustomerFirstName]
			,[CustomerLastName]
			,[CustomerBirthDate]
			,[EmailAddress]
			,[created_Date]
			)
		VALUES (
			source.[CustomerAlternateKey]
			,source.[CustomerFirstName]
			,source.[CustomerLastName]
			,source.[CustomerBirthDate]
			,source.[EmailAddress]
			,getdate()
			);


--SCD2

CREATE TABLE dim_Customer -- SCD 2
	(
	CustomerId INT identity(1, 1) PRIMARY KEY
	,CustomerAlternateKey NVARCHAR(50)
	,CustomerFirstName NVARCHAR(50)
	,CustomerLastName NVARCHAR(50)
	,CustomerBirthDate DATE
	,EmailAddress NVARCHAR(50)
	,Created_date DATE
	,End_date DATE
	,isActive CHAR DEFAULT 'Y'
	)

INSERT INTO dim_Customer (
	CustomerAlternateKey
	,customerFirstName
	,CustomerLastName
	,CustomerBirthDate
	,EmailAddress
	,Created_date
	)
SELECT CustomerAlternateKey
	,customerFirstName
	,CustomerLastName
	,CustomerBirthDate
	,EmailAddress
	,created_date
FROM (
	MERGE Dim_Customer AS target
	USING (
		SELECT DISTINCT CustomerAlternateKey
			,customerFirstName
			,CustomerLastName
			,CustomerBirthDate
			,EmailAddress
		FROM dbo.stagSalesDWH
		) AS Source
		ON target.CustomerAlternateKey = source.CustomerAlternateKey
	WHEN MATCHED
		AND (
			target.CustomerFirstName <> source.CustomerFirstName
			OR target.CustomerLastName <> source.CustomerLastName
			OR target.CustomerBirthDate <> source.CustomerBirthDate
			OR target.EmailAddress <> source.EmailAddress
			)
		AND isactive = 'Y'
		THEN
			UPDATE
			SET isActive = 'N'
				,end_date = getdate()
	WHEN NOT MATCHED
		THEN
			INSERT (
				CustomerAlternateKey
				,CustomerFirstName
				,CustomerLastName
				,CustomerBirthDate
				,EmailAddress
				,created_date
				)
			VALUES (
				Source.CustomerAlternateKey
				,Source.CustomerFirstName
				,Source.CustomerLastName
				,Source.CustomerBirthDate
				,Source.EmailAddress
				,getdate()
				)
	OUTPUT $ACTION
		,Source.CustomerAlternateKey
		,Source.CustomerFirstName
		,Source.CustomerLastName
		,Source.CustomerBirthDate
		,Source.EmailAddress
		,getdate()
	) -- end of merge
	AS changes(action, CustomerAlternateKey, CustomerFirstName, CustomerLastName, CustomerBirthDate, EmailAddress, created_date)
WHERE action = 'update'
	--select * from dim_Customer




--Currency Dimension
--SCD1

CREATE TABLE dim_currency (
	currency_id INT PRIMARY KEY identity(1, 1)
	,-- surrogate key 
	currencykey VARCHAR(10)
	,currencyName VARCHAR(30)
	)

MERGE dim_currency AS target
USING (
	SELECT DISTINCT currencyKey
		,currencyName
	FROM dbo.stagSalesDWH
	) AS source
	ON target.currencykey = source.currencykey
WHEN MATCHED
	AND Target.currencyName <> source.currencyName
	THEN
		UPDATE
		SET Target.currencyName = source.currencyName
WHEN NOT MATCHED BY target
	THEN
		INSERT (
			currencykey
			,currencyName
			)
		VALUES (
			source.currencykey
			,source.currencyName
			);-- end of merge
			--select * from dim_currency


--Promotion Dimension
--SCD2

---Update in promotion using scd-2 Promotion
INSERT INTO dim_promotion (
	promotiontype
	,promotionname
	,promotioncategory
	,createddate
	,isactive
	)
SELECT promotiontype
	,promotionname
	,promotioncategory
	,createddate
	,isactive
FROM (
	MERGE dim_promotion AS target
	USING (
		SELECT DISTINCT promotionname
			,promotiontype
			,promotioncategory
		FROM dbo.sales
		) AS source
		ON source.promotionname = target.promotionname
	WHEN MATCHED
		AND (
			source.promotiontype <> target.promotiontype
			OR source.promotionname <> target.promotionname
			OR source.promotiontype <> target.promotiontype
			)
		AND isactive = 'Y'
		THEN
			UPDATE
			SET isactive = 'N'
				,modifieddate = getdate()
	WHEN NOT MATCHED BY target
		THEN
			INSERT (
				promotiontype
				,promotionname
				,promotioncategory
				,createddate
				,isactive
				)
			VALUES (
				source.promotiontype
				,source.promotionname
				,source.promotioncategory
				,getdate()
				,'Y'
				)
	OUTPUT $ACTION
		,source.promotiontype
		,source.promotionname
		,source.promotioncategory
		,getdate()
		,'Y'
	) AS changes(action, promotiontype, promotionname, promotioncategory, createddate, isactive)
WHERE action = 'update'

SELECT *
FROM dim_promotion



--Date Dimension
--SCD 1


CREATE TABLE dim_date (
	   Date_key INT PRIMARY KEY    
	,[Date] DATE    
	,[DayofWeek] INT    
	,[DayName] VARCHAR(9)    
	,[day_of_month] VARCHAR(2)    
	,[Month] VARCHAR(2)    
	,[MonthName] VARCHAR(9)    
	,[Quarter] CHAR(1)    
	,[quarterName] VARCHAR(9)    
	,[year] CHAR(4)    
	)




DECLARE @startDate DATE = (       SELECT DISTINCT TOP 1 orderDate        FROM dbo.stagSalesDWH        ORDER BY orderdate        )
DECLARE @endDate DATE = (       SELECT DISTINCT TOP 1 orderdate        FROM dbo.stagSalesDWH        ORDER BY orderdate DESC        )
DECLARE @CurrentYear INT    
	,@CurrentMonth INT    
	,@CurrentQuarter INT
DECLARE @CurrentDate AS DATETIME = @StartDate

SET @CurrentMonth = DATEPART(MM, @CurrentDate)
SET @CurrentYear = DATEPART(YY, @CurrentDate)
SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)

WHILE (@CurrentDate < @endDate)
BEGIN
	   IF(@currentMonth != datepart(MM, @CurrentDate))    BEGIN        SET @currentMonth = datepart(MM, @CurrentDate)    END    IF(@CurrentYear != Datepart(yy, @currentDate))    BEGIN        SET @CurrentYear = Datepart(yy, @currentDate)    END    IF(@CurrentQuarter != Datepart(qq, @currentdate))    BEGIN        SET @CurrentQuarter = Datepart(qq, @currentdate)    END    INSERT
	INTO dim_date    SELECT convert(CHAR(8), @CurrentDate, 112) AS DateKey        
		,@currentdate AS DATE        
		,datepart(dw, @currentDate) AS day_of_month        
		,datename(dw, @currentdate) AS [dayname]        
		,datepart(dd, @CurrentDate) AS [DayOfWeek]        
		,datepart(mm, @currentDate) AS [Month]        
		,datename(mm, @currentDate) AS [MonthName]        
		,datepart(qq, @currentDate) AS [Quarter]   
                          ,CASE datepart(qq, @currentDate)
		WHEN 1
			THEN 'First'
		WHEN 2
			THEN 'Second'
		WHEN 3
			THEN 'Third'
		WHEN 4
			THEN 'Fourth'
		END AS QuraterName
	,datepart(year, @CurrentDate) AS [year]

SET  @CurrentDate = DateAdd(DD,1,@CurrentDate) END
    

--Fact table

CREATE SCHEMA fact

CREATE TABLE fact.sales (
	   productId INT FOREIGN KEY REFERENCES dbo.dim_product1(productId)    
	,customerId INT FOREIGN KEY REFERENCES dbo.dim_Customer(customerId)    
	,promotionId INT FOREIGN KEY REFERENCES dbo.dim_promotion(promotionId)    
	,currency_Id INT FOREIGN KEY REFERENCES dbo.dim_currency(currency_ID)    
	,Date_Key INT FOREIGN KEY REFERENCES dbo.dim_date(Date_Key)    
	,SalesOrderNumber NVARCHAR(25)    
	,SalesOrderLineNumber CHAR(5)    
	,RevisionNumber CHAR(4)    
	,OrderQuantity INT    
	,ExtendedAmount FLOAT    
	,DiscountAmount FLOAT    
	,ProductStandardCost FLOAT    
	,TotalProductCost FLOAT    
	,SalesAmount FLOAT    
	,TaxAmt FLOAT    
	,Freight FLOAT    
	,OrderDate DATE    
	,DueDate DATE    
	,ShipDate DATE    
	)

SELECT *
FROM fact.sales;





CREATE PROCEDURE factTableUpdate
AS
INSERT INTO fact.sales (
	   productid    
	,customerid    
	,promotionid    
	,currency_ID    
	,Date_Key    
	,SalesOrderNumber    
	,SalesOrderLineNumber    
	,RevisionNumber    
	,OrderQuantity    
	,ExtendedAmount    
	,DiscountAmount    
	,ProductStandardCost    
	,TotalProductCost    
	,SalesAmount    
	,TaxAmt    
	,Freight    
	,OrderDate    
	,DueDate    
	,ShipDate    
	)
SELECT pd.productid    
	,c.customerid    
	,p.promotionid    
	,cur.currency_ID    
	,DATE.Date_Key    
	,stg.SalesOrderNumber    
	,stg.SalesOrderLineNumber    
	,stg.RevisionNumber    
	,stg.OrderQuantity    
	,stg.ExtendedAmount    
	,stg.DiscountAmount    
	,stg.ProductStandardCost    
	,stg.TotalProductCost    
	,stg.SalesAmount    
	,stg.TaxAmt    
	,stg.Freight    
	,stg.OrderDate    
	,stg.DueDate    
	,stg.ShipDate
FROM dbo.stagSalesDWH stg
LEFT JOIN (
	   SELECT productid        
	,productKey    FROM dbo.dim_product1    
	) pd ON stg.productkey = pd.productkey
LEFT JOIN (
	   SELECT customerid        
	,customerAlternateKey    FROM dbo.dim_Customer    
	) c ON stg.customerAlternateKey = c.customerAlternatekey
LEFT JOIN (
	   SELECT promotionId        
	,promotionName    FROM dbo.dim_promotion    
	) p ON stg.promotionName = p.promotionName
LEFT JOIN (
	   SELECT currency_ID        
	,CurrencyKey    FROM dbo.dim_currency    
	) cur ON stg.currencykey = cur.currencykey
LEFT JOIN (
	   SELECT date_Key        
	,DATE    FROM dbo.dim_date    
	) DATE ON stg.orderdate = DATE.DATE

EXEC factTableUpdate

SELECT *
FROM fact.sales

