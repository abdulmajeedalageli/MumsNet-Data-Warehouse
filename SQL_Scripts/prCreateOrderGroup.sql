
USE Mumsnet_Normalized;
GO


Create PROCEDURE prCreateOrderGroup
    @OrderNumber NVARCHAR(32),
    @OrderCreateDate DATETIME,
    @CustomerCityID BIGINT   
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO OrderGroup (
            OrderNumber, 
            OrderCreateDate, 
            OrderStatusCode, 
            CustomerID,       
            BillingCurrency, 
            TotalItems, 
            SavedTotal
        )
        VALUES (
            @OrderNumber, 
            @OrderCreateDate, 
            0, 
            @CustomerCityID,  
            'GBP', 
            0, 
            0
        );

        COMMIT TRANSACTION;
        PRINT 'Order group created successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO




EXEC prCreateOrderGroup 
    @OrderNumber = 'OR\29012025\01',
    @OrderCreateDate = '2025-01-29 14:30:00',
    @CustomerCityID = 4705;




select *
from OrderGroup
where OrderNumber = 'OR\29012025\01';

