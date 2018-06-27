USE [Taxi2Bachelor]
GO

/****** Object:  View [dbo].[mlGreenData]    Script Date: 05.06.2018 13:51:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- View for Machine-Learning-Green-Data
-- Clean Green Data joined with Weather Data
-- Each TaxiTrip gets additional weatherInfo for the day of the trip
-- this will be needed for ml
-- Locations are kept as ID's 
CREATE OR ALTER VIEW [dbo].[mlGreenData]
AS 
SELECT 
	-- Taxi Data Columns i want
		[VendorID]
		,[pickup_datetime]
		,[dropOff_datetime]
      --,[store_and_fwd_flag]
      ,[PULocationID]
	  ,[DOLocationID]
	  ,[trip_distance]
      ,[passenger_count]
	  ,[RatecodeID]
	  ,[payment_type]
	  ,[trip_type]
      ,ROUND([fare_amount],2) as fare_amount
	  ,[extra]
	  ,[mta_tax]
	  ,ROUND([tip_amount],2) as tip_amount
	  ,ROUND([tolls_amount],2) as tolls_amount
	  ,[ehail_fee]
	  ,[improvement_surcharge]
	  ,ROUND([total_amount],2) as total_amount
	  --WeatherData-Columns
      ,Visibility
      ,DryBulbTemp
      ,WetBulbTemp
      ,DewPointTemp
      ,RelativeHumidity
      ,WindSpeed
      ,WindDirection
      ,StationPressure
      ,PressureTendency
      ,PressureChange
      ,SeaLevelPressure
      ,AltimeterSetting
      ,Sunrise
      ,Sunset
FROM 
	cleanGreenData AS g, cleanWeatherData AS w 
WHERE 
		Convert(DATE,g.pickup_datetime) = w.Date
	AND 
		DATEPART(hour, g.pickup_datetime) = w.Hour
	AND
		DATEPART(year,g.pickup_datetime)=2017
	AND 
		total_amount>=0
	AND 
		total_amount<=100
	AND
		tip_amount>=0
	AND 
		tip_amount<25
	AND 
		DATEDIFF(MINUTE,g.pickup_datetime,g.dropOff_datetime)<=120
	AND 
		DATEDIFF(MINUTE,g.pickup_datetime,g.dropOff_datetime)>0
	-- B Carefull here
	AND 
		tip_amount<=(total_amount*0.3)
GO


