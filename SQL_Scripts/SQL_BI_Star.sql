CREATE DATABASE Mumsnet_BI
GO

USE Mumsnet_BI;
GO

DROP TABLE IF EXISTS dbo.BridgeGroup;
GO
DROP TABLE IF EXISTS dbo.DimProductGroup;
GO
DROP TABLE IF EXISTS dbo.OrdersFact;
GO
DROP TABLE IF EXISTS dbo.DimProduct;
GO



CREATE TABLE dbo.OrdersFact 
(
    OrderNumber     NVARCHAR(32)  NOT NULL,
    OrderItemNumber NVARCHAR(32)  NOT NULL,

    OrderCreateDate DATETIME      NOT NULL,
    OrderStatusCode INT           NOT NULL,
    CustomerID      BIGINT        NOT NULL,

    VariantCode     NVARCHAR(255) NULL,

    Quantity        INT           NOT NULL,
    UnitPrice       MONEY         NOT NULL,
    LineItemTotal   MONEY         NULL,

    SavedTotal      MONEY         NULL,
    TotalItems      INT           NULL,

    CONSTRAINT UQ_OrdersFact_OrderLine UNIQUE (OrderNumber, OrderItemNumber)
);
GO

ALTER TABLE dbo.OrdersFact
ADD CONSTRAINT pk_OrderItemNumber PRIMARY KEY CLUSTERED (OrderItemNumber)
GO

INSERT INTO dbo.OrdersFact
(
    OrderNumber, OrderItemNumber,
    Quantity, UnitPrice, VariantCode, LineItemTotal,
    OrderStatusCode, CustomerID, SavedTotal, OrderCreateDate, TotalItems
)
SELECT
    oi.OrderNumber,
    oi.OrderItemNumber,
    oi.Quantity,
    oi.UnitPrice,
    oi.VariantCode,
    oi.LineItemTotal,
    og.OrderStatusCode,
    og.CustomerID,
    og.SavedTotal,
    og.OrderCreateDate,
    og.TotalItems
FROM Mumsnet_Normalized.dbo.OrderItem AS oi
INNER JOIN Mumsnet_Normalized.dbo.OrderGroup AS og
    ON og.OrderNumber = oi.OrderNumber;
GO

DROP TABLE IF EXISTS dbo.DimGeography;
GO

CREATE TABLE dbo.DimGeography
( 
	CustomerID bigint NOT NULL,
	CityID INT NOT NULL,
	City nvarchar(255),
	County nvarchar(255),	
	Region nvarchar(255),
	Country nvarchar(255)
);
GO

ALTER TABLE dbo.DimGeography
ADD CONSTRAINT pk_CustomerID PRIMARY KEY CLUSTERED (CustomerID)
GO

INSERT INTO dbo.DimGeography
(
	CustomerID, CityID, City, County,
	Region, Country
)
SELECT
	cust.CustomerID,
	geo.CityID,
	geo.City,
	geo.County,
	geo.Region,
	geo.Country
FROM Mumsnet_Normalized.dbo.Customer AS cust
INNER JOIN Mumsnet_Normalized.dbo.City AS geo
	ON geo.CityID = cust.CityID
GO

ALTER TABLE dbo.OrdersFact
ADD CONSTRAINT fk_OrdersFact_DimGeography FOREIGN KEY (CustomerID)
REFERENCES dbo.DimGeography (CustomerID)
GO

DROP TABLE IF EXISTS dbo.DimDate;
GO

CREATE TABLE dbo.DimDate
( 
	DateKey int NOT NULL,
	OrderCreateDate datetime NOT NULL,
	DayNumber int,
	MonthNumber int,
	MonthDescription nvarchar(20),
	QuarterNumber int,
	YearNumber int,
);
GO

ALTER TABLE dbo.DimDate
ADD CONSTRAINT pk_DateKey PRIMARY KEY CLUSTERED (DateKey)
GO

ALTER TABLE dbo.OrdersFact
ADD OrderDateKey INT NULL;
GO

UPDATE dbo.OrdersFact
SET OrderDateKey = CONVERT(
                      INT,
                      CONVERT(CHAR(8), OrderCreateDate, 112)
                  );
GO

ALTER TABLE dbo.OrdersFact
ALTER COLUMN OrderDateKey INT NOT NULL;
GO

INSERT INTO dbo.DimDate 
(
DateKey, OrderCreateDate, DayNumber,
MonthNumber, QuarterNumber, YearNumber
)
SELECT DISTINCT
    ofc.OrderDateKey AS DateKey,
    CAST(ofc.OrderCreateDate AS DATE) AS OrderCreateDate,
    DATEPART(DAY,     ofc.OrderCreateDate) AS DayNumber,
    DATEPART(MONTH,   ofc.OrderCreateDate) AS MonthNumber,
    DATEPART(QUARTER, ofc.OrderCreateDate) AS QuarterNumber,
    DATEPART(YEAR,    ofc.OrderCreateDate) AS YearNumber
FROM dbo.OrdersFact AS ofc;
GO

UPDATE dbo.DimDate
SET MonthDescription = DATENAME(MONTH, OrderCreateDate);
GO

ALTER TABLE dbo.OrdersFact
ADD CONSTRAINT fk_OrdersFact_DimDate FOREIGN KEY (OrderDateKey)
REFERENCES dbo.DimDate (DateKey);
GO

DROP TABLE IF EXISTS dbo.DimStatus;
GO

CREATE TABLE dbo.DimStatus
( 
	OrderStatusCode int NOT NULL,
	OrderStatusDescription nvarchar(20),
);
GO

ALTER TABLE dbo.DimStatus
ADD CONSTRAINT pk_DimStatus PRIMARY KEY CLUSTERED (OrderStatusCode);
GO

INSERT INTO dbo.DimStatus (OrderStatusCode, OrderStatusDescription)
VALUES
(0, 'New'),
(1, 'Abandoned'),
(2, 'Out of stock'),
(3, 'Cancelled'),
(4, 'Fulfilled');
GO

ALTER TABLE dbo.OrdersFact
ADD CONSTRAINT fk_OrdersFact_DimStatus FOREIGN KEY (OrderStatusCode)
REFERENCES dbo.DimStatus (OrderStatusCode);
GO


CREATE TABLE dbo.DimProductGroup
(
    ProductGroupID   INT           NOT NULL,
    ProductGroupName NVARCHAR(128) NOT NULL
);
GO

ALTER TABLE dbo.DimProductGroup
ADD CONSTRAINT pk_ProductGroupID PRIMARY KEY CLUSTERED (ProductGroupID);
GO

INSERT INTO dbo.DimProductGroup (ProductGroupID, ProductGroupName)
SELECT DISTINCT
    pg.ProductGroupID,
    pg.ProductGroupName
FROM Mumsnet_Normalized.dbo.ProductGroup AS pg;
GO


CREATE TABLE dbo.DimProduct
(
	VariantCode NVARCHAR(255) NOT NULL,
    ProductCode NVARCHAR(255) NOT NULL,
    ProdName    NVARCHAR(255) NULL,
    Price       MONEY         NULL
);
GO

ALTER TABLE dbo.DimProduct
ADD CONSTRAINT pk_VariantCode PRIMARY KEY CLUSTERED (VariantCode);
GO

INSERT INTO dbo.DimProduct (VariantCode, ProductCode, ProdName, Price)
SELECT DISTINCT
    v.VariantCode,
    p.ProductCode,
    p.Name,
    p.Price
FROM Mumsnet_Normalized.dbo.Variant AS v
INNER JOIN Mumsnet_Normalized.dbo.Product AS p
    ON p.ProductCode = v.ProductID;
GO

CREATE TABLE dbo.BridgeGroup
(
    VariantCode    NVARCHAR(255) NOT NULL,
    ProductGroupID INT           NOT NULL,
    CONSTRAINT pk_BridgeProductGroupVariant
        PRIMARY KEY CLUSTERED (VariantCode, ProductGroupID)
);
GO

INSERT INTO dbo.BridgeGroup (VariantCode, ProductGroupID)
SELECT DISTINCT
    v.VariantCode,
    pgp.ProductGroupID
FROM Mumsnet_Normalized.dbo.Variant AS v
INNER JOIN Mumsnet_Normalized.dbo.ProductGroup_Product AS pgp
    ON pgp.ProductCode = v.ProductID;

ALTER TABLE dbo.BridgeGroup
ADD CONSTRAINT fk_BridgeVariant_VariantCode
FOREIGN KEY (VariantCode)
REFERENCES dbo.DimProduct (VariantCode);
GO

ALTER TABLE dbo.BridgeGroup
ADD CONSTRAINT fk_BridgeVariant_ProductGroupID
FOREIGN KEY (ProductGroupID)
REFERENCES dbo.DimProductGroup (ProductGroupID);
GO

ALTER TABLE dbo.OrdersFact
ADD CONSTRAINT fk_OrdersFact_VariantCode FOREIGN KEY (VariantCode)
REFERENCES dbo.DimProduct (VariantCode);
GO


--ALTER TABLE dbo.OrdersFact
--DROP COLUMN OrderCreateDate;
--GO

--ALTER TABLE dbo.OrdersFact
--DROP COLUMN UnitPrice;
--GO

--ALTER TABLE dbo.OrdersFact
--DROP COLUMN SavedTotal;
--GO

--ALTER TABLE dbo.OrdersFact
--DROP COLUMN TotalItems;
--GO