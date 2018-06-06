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
CREATE OR ALTER VIEW [dbo].[mlYellowData]
AS 
SELECT 
	-- Taxi Data Columns i want
		[VendorID],
		[pickup_datetime],[dropOff_datetime]
      --,[store_and_fwd_flag]
      ,[PULocationID],[DOLocationID],[trip_distance]
      ,[passenger_count],[RatecodeID],[payment_type]
      ,[fare_amount],[extra],[mta_tax],[tip_amount],[tolls_amount],[improvement_surcharge],[total_amount]
	  --WeatherData-Columns
	   --,[date_]
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
	cleanYellowData AS y, cleanWeatherData AS w 
WHERE Convert(DATE,y.pickup_datetime) = w.Date
		AND DATEPART(hour, y.pickup_datetime) = w.Hour
GO


