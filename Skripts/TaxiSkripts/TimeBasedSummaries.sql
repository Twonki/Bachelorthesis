USE Taxi2Bachelor

--Shows Monthly summary of yellows
SELECT Count(*) as trips, SUM(total_amount) as revenue, sum(tip_amount) as tips,VendorID as vendor,DATEPart(MONTH,pickup_datetime) as month_
  FROM [dbo].[yellowData] 
  WHERE Datepart(year,pickup_datetime)=2017
  GROUP BY VendorID,DATEPART(Month,pickup_datetime)
  ORDER BY VendorID, DATEPART(Month,pickup_datetime)
GO

--Shows Daylie summary of yellows
SELECT Count(*) as trips, SUM(total_amount) as revenue, sum(tip_amount) as tips,VendorID as vendor,DATEPart(DAY,pickup_datetime) as day_, DATEPART(Month,pickup_datetime) as month_
  FROM [dbo].[yellowData] 
  WHERE Datepart(year,pickup_datetime)=2017
  GROUP BY VendorID,DATEPART(DAY,pickup_datetime),DATEPART(Month,pickup_datetime)
  ORDER BY VendorID,DATEPART(Month,pickup_datetime), DATEPART(DAY,pickup_datetime)
GO

--Shows Monthly summary of greens
SELECT Count(*) as trips, SUM(total_amount) as revenue, sum(tip_amount) as tips,VendorID as vendor,DATEPart(MONTH,pickup_datetime) as month_
  FROM [dbo].[greenData] 
  WHERE Datepart(year,pickup_datetime)=2017
  GROUP BY VendorID,DATEPART(Month,pickup_datetime)
  ORDER BY VendorID, DATEPART(Month,pickup_datetime)
GO

--Shows Daylie summary of greens
SELECT Count(*) as trips, SUM(total_amount) as revenue, sum(tip_amount) as tips,VendorID as vendor,DATEPart(DAY,pickup_datetime) as day_, DATEPART(Month,pickup_datetime) as month_
  FROM [dbo].[greenData] 
  WHERE Datepart(year,pickup_datetime)=2017
  GROUP BY VendorID,DATEPART(DAY,pickup_datetime),DATEPART(Month,pickup_datetime)
  ORDER BY VendorID,DATEPART(Month,pickup_datetime), DATEPART(DAY,pickup_datetime)
GO

-- Deprecated, different approach for grouping (with datetime in difference, so total datetime is shown not only parts)

--SELECT Count(*) as trips, SUM(total_amount) as revenue, sum(tip_amount) as tips,VendorID as vendor,DATEADD(MONTH,DATEDIFF(MONTH,0, yellows.[pickup_datetime]),0) as month_
--  FROM [dbo].[yellowData] as yellows
--  GROUP BY VendorID, DATEADD(MONTH,DATEDIFF(MONTH,0,yellows.[pickup_datetime]),0)
--  ORDER BY VendorID, DATEADD(MONTH,DATEDIFF(MONTH,0, yellows.[pickup_datetime]),0)
--GO