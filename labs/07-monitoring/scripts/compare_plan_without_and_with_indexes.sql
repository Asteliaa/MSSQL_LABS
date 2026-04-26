USE [ProjectDB];
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = N'IX_OrderDetails_Quantity' AND object_id = OBJECT_ID('dbo.OrderDetails')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_OrderDetails_Quantity 
    ON dbo.OrderDetails(Quantity);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = N'IX_OrderDetails_ColumnStore' AND object_id = OBJECT_ID('dbo.OrderDetails')
)
BEGIN
    CREATE COLUMNSTORE INDEX IX_OrderDetails_ColumnStore 
    ON dbo.OrderDetails (ProductID, Quantity, PriceAtOrder);
END;
GO

SET SHOWPLAN_TEXT ON;
GO

SELECT ProductID, SUM(Quantity) AS TotalQty 
FROM dbo.OrderDetails 
GROUP BY ProductID;
GO

SET SHOWPLAN_TEXT OFF;
GO

SET STATISTICS TIME ON;
GO

SELECT ProductID, SUM(Quantity) AS TotalQty 
FROM dbo.OrderDetails 
GROUP BY ProductID;
GO

SET STATISTICS TIME OFF;
GO