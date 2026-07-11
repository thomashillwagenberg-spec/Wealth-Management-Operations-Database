
/*
  08_create_functions.sql
  Purpose: Demonstrate justified reusable SQL Server functions.
  Database context: WealthManagementOperations.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER FUNCTION reporting.fn_AccountValue
(
    @AccountID int,
    @AsOfDate date
)
RETURNS TABLE
AS
RETURN
(
    WITH LatestPriceDate AS
    (
        SELECT
            ch.SecurityID,
            MAX(sp.PriceDate) AS PriceDate
        FROM trading.CurrentHolding AS ch
        INNER JOIN market.SecurityPrice AS sp
            ON sp.SecurityID = ch.SecurityID
           AND sp.PriceDate <= @AsOfDate
        WHERE ch.AccountID = @AccountID
        GROUP BY ch.SecurityID
    )
    SELECT
        ch.AccountID,
        @AsOfDate AS RequestedAsOfDate,
        CAST(SUM(ch.Quantity * sp.ClosePrice) AS decimal(19,2)) AS PortfolioValue
    FROM trading.CurrentHolding AS ch
    INNER JOIN LatestPriceDate AS lpd ON lpd.SecurityID = ch.SecurityID
    INNER JOIN market.SecurityPrice AS sp
        ON sp.SecurityID = lpd.SecurityID
       AND sp.PriceDate = lpd.PriceDate
    WHERE ch.AccountID = @AccountID
    GROUP BY ch.AccountID
);
GO

CREATE OR ALTER FUNCTION reporting.fn_MaskEmail
(
    @Email varchar(254)
)
RETURNS varchar(254)
AS
BEGIN
    IF @Email IS NULL RETURN NULL;

    DECLARE @AtPosition int = CHARINDEX('@', @Email);

    IF @AtPosition <= 1 RETURN '***';

    RETURN CONCAT(LEFT(@Email, 1), '***', SUBSTRING(@Email, @AtPosition, 254));
END;
GO

CREATE OR ALTER FUNCTION compliance.fn_IsReviewOverdue
(
    @DueDate date,
    @ReviewStatus varchar(20),
    @AsOfDate date
)
RETURNS bit
AS
BEGIN
    RETURN
    (
        CASE
            WHEN @ReviewStatus NOT IN ('COMPLETED','WAIVED')
             AND @DueDate < @AsOfDate
            THEN 1
            ELSE 0
        END
    );
END;
GO

PRINT N'Created the account-value table-valued function and two scalar helper functions.';
GO
