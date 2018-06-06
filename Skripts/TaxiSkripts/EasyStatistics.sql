USE [Taxi2Bachelor]
GO

SELECT Count(*) as trips, avg(total_amount) as avg_revenue, avg(tip_amount) as avg_tip, Concat(datepart(day,pickup_datetime),'.',datepart(month,pickup_datetime)) as date_
  FROM [dbo].[yellowData]
  WHERE Datepart(Year, pickup_datetime)=2017
  GROUP BY DATEPART(DAY,pickup_datetime), Datepart(month,pickup_datetime)
GO