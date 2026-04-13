USE Mumsnet_Normalized;
GO

CREATE or ALTER PROCEDURE prCreateOrderItem
    @OrderNumber NVARCHAR(32),
    @OrderItemNumber NVARCHAR(32),
    @ProductGroup NVARCHAR(128),
    @ProductCode NVARCHAR(255),
    @VariantCode NVARCHAR(255),
    @Quantity INT,
    @UnitPrice MONEY
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ProductGroupID INT;

        SELECT @ProductGroupID = ProductGroupID
        FROM ProductGroup
        WHERE ProductGroupName = @ProductGroup;

		IF @ProductGroupID IS NULL
		BEGIN
			RAISERROR('Invalid ProductGroup name provided.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END;


        INSERT INTO OrderItem (
            OrderItemNumber,
            OrderNumber,
            ProductGroupID,
            ProductCode,
            VariantCode,
            Quantity,
            UnitPrice
        )
        VALUES (
            @OrderItemNumber,
            @OrderNumber,
            @ProductGroupID,
            @ProductCode,
            @VariantCode,
            @Quantity,
            @UnitPrice
        );

        UPDATE og
        SET 
            TotalItems = sub.TotalItems,
            SavedTotal = sub.SavedTotal
        FROM OrderGroup og
        JOIN (
            SELECT 
                OrderNumber,
                SUM(Quantity) AS TotalItems,
                SUM(Quantity * UnitPrice) AS SavedTotal
            FROM OrderItem
            GROUP BY OrderNumber
        ) AS sub
        ON og.OrderNumber = sub.OrderNumber
        WHERE og.OrderNumber = @OrderNumber;

        COMMIT TRANSACTION;
        PRINT 'Order item created and totals updated successfully.';
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

EXEC prCreateOrderItem 
    @OrderNumber = 'OR\29012025\01',
    @OrderItemNumber = 'OR\29012025\01\1',
    @ProductGroup = 'Maternity Sale',
    @ProductCode = '1516',
    @VariantCode = '00097238',
    @Quantity = 3,
    @UnitPrice = 19.99;


select * 
from OrderItem
where ProductCode = '1516';

select * 
from OrderGroup
where OrderNumber = 'OR\29012025\01';


CREATE NONCLUSTERED INDEX idx_OrderItem_OrderNumber ON dbo.OrderItem (OrderNumber);
CREATE NONCLUSTERED INDEX idx_OrderItem_ProductGroupID ON dbo.OrderItem (ProductGroupID);
CREATE NONCLUSTERED INDEX idx_OrderItem_ProductCode ON dbo.OrderItem (ProductCode);
CREATE NONCLUSTERED INDEX idx_OrderItem_VariantCode ON dbo.OrderItem (VariantCode);
CREATE NONCLUSTERED INDEX idx_ProductGroup_ProductGroupName ON dbo.ProductGroup (ProductGroupName);

