USE [ProjectDB];
GO

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderDetails
    (
        OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
        OrderID       INT NOT NULL,
        ProductID     INT NOT NULL,
        Quantity      INT NOT NULL,
        PriceAtOrder  DECIMAL(10,2) NOT NULL
    );
END;
GO

SET NOCOUNT ON;

DECLARE @i INT = 1;
WHILE @i <= 60000
BEGIN
    INSERT INTO dbo.OrderDetails (OrderID, ProductID, Quantity, PriceAtOrder)
    VALUES (1, (@i % 100) + 1, (@i % 10) + 1, 100.00);
    SET @i = @i + 1;
END;
GO