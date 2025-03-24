-- Create SCHEMA project2 if it doesn't exist
DROP database if exists project2;
CREATE SCHEMA project2;

-- Select the project2 database
USE project2;

-- Create table for stocks
CREATE TABLE Stocks (
		StockSymbol VARCHAR(10) PRIMARY KEY,
		CompanyName VARCHAR(30),
		IndustrySector VARCHAR(30),
		IndustryType VARCHAR(30)
	);

-- Create table for daily price data

CREATE TABLE PriceData (
    DataID INT AUTO_INCREMENT PRIMARY KEY,
    StockSymbol VARCHAR(10),
    TradeDate DATE,
    OpeningPrice DECIMAL(14, 7),
    HighestPrice DECIMAL(14, 7),
    LowestPrice DECIMAL(14, 7),
    ClosingPrice DECIMAL(14, 7),
    TradeVolume INT,
	FOREIGN KEY (StockSymbol) REFERENCES Stocks(StockSymbol)
);

# a.	List all securities (one per line) in the database.
SELECT DISTINCT * FROM Stocks;

# b.	What was the closing price for all securities on July 10, 2023?
SELECT stocks.StockSymbol,
    (SELECT TradeDate FROM PriceData WHERE StockSymbol = Stocks.StockSymbol AND TradeDate = '2023-07-10') AS Date ,
    (SELECT ClosingPrice FROM PriceData WHERE StockSymbol = Stocks.StockSymbol AND TradeDate = '2023-07-10') AS Close
FROM Stocks;

# c.	How many whole shares of each security could I purchase with $1000? What about fractional shares?
SELECT 
    Stocks.StockSymbol,
    Stocks.CompanyName,
    FLOOR(1000 / PriceData.ClosingPrice) AS WholeShares,
    (1000 % PriceData.ClosingPrice) / PriceData.ClosingPrice AS FractionalShares
FROM Stocks
JOIN PriceData ON Stocks.StockSymbol = PriceData.StockSymbol
WHERE TradeDate = '2024-01-22';


# d.	What days do not show stock trades (e.g. weekends or holidays)?
WITH RECURSIVE DateRange AS (
    SELECT '2024-01-15' AS date
    UNION ALL
    SELECT DATE_ADD(date, INTERVAL 1 DAY)
    FROM DateRange
    WHERE date < '2024-02-15'
)
SELECT DateRange.date
FROM DateRange
LEFT JOIN PriceData ON DateRange.date = PriceData.TradeDate
WHERE PriceData.TradeDate IS NULL
ORDER BY DateRange.date;


# e.	Which securities traded higher today than yesterday?

SELECT 
    Stocks.StockSymbol,
    Stocks.CompanyName
FROM Stocks
JOIN PriceData AS TodayPrice ON Stocks.StockSymbol = TodayPrice.StockSymbol
JOIN PriceData AS YesterdayPrice ON Stocks.StockSymbol = YesterdayPrice.StockSymbol
WHERE DATE(TodayPrice.TradeDate) = '2024-02-14' 
AND DATE(YesterdayPrice.TradeDate) = DATE_SUB('2024-02-14', INTERVAL 1 DAY)
AND TodayPrice.ClosingPrice > YesterdayPrice.ClosingPrice; 

# f.	Rank the securities according to their relative performance over the last 7 or 30 days.
SELECT 
    Stocks.StockSymbol,
    Stocks.CompanyName,
    (TodayPrice.ClosingPrice - Price7DaysAgo.ClosingPrice) / Price7DaysAgo.ClosingPrice AS RelativePerformance
FROM Stocks
JOIN PriceData AS TodayPrice ON Stocks.StockSymbol = TodayPrice.StockSymbol
JOIN PriceData AS Price7DaysAgo ON Stocks.StockSymbol = Price7DaysAgo.StockSymbol
WHERE TodayPrice.TradeDate = '2024-02-13' 
AND Price7DaysAgo.TradeDate = DATE_SUB('2024-02-13', INTERVAL 7 DAY)
ORDER BY RelativePerformance DESC;


# g.	Which securities have had the highest price appreciation over the previous 21 trading days, calculated at the start of every month since 2010? How does this compare to the price appreciation for the S&P 500 index?”

WITH RankedPriceData AS (
    SELECT * , 
    ROW_NUMBER() OVER (PARTITION BY StockSymbol ORDER BY TradeDate DESC) AS rn
    FROM PriceData
    WHERE TradeDate >= '2010-01-01'
)
SELECT 
    p1.StockSymbol,
    p1.TradeDate AS StartOfMonth,
    p1.ClosingPrice AS StartPrice,
    p21.ClosingPrice AS EndPrice,
    (p21.ClosingPrice - p1.ClosingPrice) / p1.ClosingPrice AS PriceAppreciation,
    (p21.ClosingPrice - p1.ClosingPrice) / p1.ClosingPrice * 100 AS PriceAppreciationPercentage
FROM RankedPriceData p1
JOIN RankedPriceData p21 ON p1.StockSymbol = p21.StockSymbol AND p21.rn = 21
WHERE p1.rn = 1
ORDER BY StartOfMonth;





