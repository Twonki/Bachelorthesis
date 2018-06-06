--Creating the Views for the Projekt
USE Taxi2Bachelor
GO

-- Clean, Anomalie-Free Green Data
-- No negative amounts for tip and total_amount, pu-dates only in 2017
CREATE OR ALTER VIEW cleanGreenData 
AS SELECT * FROM greenData
WHERE
	DATEPART(year,greenData.pickup_datetime)=2017
AND 
	total_amount>=0
AND
	tip_amount>=0
GO
-- Clean, Anomalie-Free Yellow Data
-- No negative amounts for tip and total_amount, pu-dates only in 2017
CREATE OR ALTER VIEW cleanYellowData
AS SELECT * FROM yellowData
WHERE
	DATEPART(year,yellowData.pickup_datetime)=2017
AND 
	total_amount>=0
AND
	tip_amount>=0
GO

-- WeatherData trimmed
-- only one station (the one which had average temperature), no TSUN (no records on both stations), no station name
CREATE OR ALTER VIEW cleanWeatherData
AS 
SELECT 
		CONVERT(Date,[DATE]) as date_
      ,[AWND]
      ,[SNOW]
      ,[SNWD]
      ,[TAVG]
      ,[TMAX]
      ,[TMIN]
      ,[WSF2]
FROM WeatherData
WHERE
	STATION='USW00014734'
GO
-- View for Machine-Learning-Green-Data
-- Clean Green Data joined with Weather Data
-- Each TaxiTrip gets additional weatherInfo for the day of the trip
-- this will be needed for ml
-- Locations are kept as ID's 
CREATE OR ALTER VIEW mlGreenData
AS 
SELECT 
	-- Taxi Data Columns i want
		[VendorID],
		[pickup_datetime],[dropOff_datetime]
      --,[store_and_fwd_flag]
      ,[PULocationID],[DOLocationID],[trip_distance]
      ,[passenger_count],[RatecodeID],[payment_type],[trip_type]
      ,[fare_amount],[extra],[mta_tax],[tip_amount],[tolls_amount],[ehail_fee],[improvement_surcharge],[total_amount]
	  --WeatherData-Columns
	   --,[date_]
      ,[AWND],[SNOW],[SNWD],[TAVG],[TMAX],[TMIN],[WSF2]
FROM (
	cleanGreenData AS g JOIN cleanWeatherData AS w 
	ON (CONVERT(DATE,g.pickup_datetime))=w.date_
)
GO
-- View for Machine-Learning-Yellow-Data
-- Clean Yellow Data joined with Weather Data
-- Each TaxiTrip gets additional weatherInfo for the day of the trip
-- this will be needed for ml
-- Locations are kept as ID's 

CREATE OR ALTER VIEW mlYellowData
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
      ,[AWND],[SNOW],[SNWD],[TAVG],[TMAX],[TMIN],[WSF2]
FROM (
	cleanYellowData AS y JOIN cleanWeatherData AS w 
	ON (CONVERT(DATE,y.pickup_datetime))=w.date_
)
GO

--View for "full" rich green Data
--Locations are resolved
-- Payment Types and RateCodes are resolved
-- Vendor is Resolved
-- TripType is resolved
CREATE OR ALTER VIEW richGreenData
AS
SELECT
-- Taxi Data Columns i want
		vendorD.Name as Vendor,
		g.[pickup_datetime],pu.Borough as pickup_Borough, pu.Zone as pickup_zone,
		g.[dropOff_datetime], do.Borough as dropoff_Borough, do.Zone as dropoff_zone
      --,[store_and_fwd_flag]
      ,g.[trip_distance]
      ,g.[passenger_count]
	  ,rateD.Name as Rate
	  ,payD.Name as Payment,
	  tripD.Name as TripType
      ,g.[fare_amount],g.[extra],g.[mta_tax],g.[tip_amount],g.[tolls_amount],g.[ehail_fee],g.[improvement_surcharge],g.[total_amount]
	  --WeatherData-Columns
	   --,[date_]
      ,g.[AWND],g.[SNOW],g.[SNWD],g.[TAVG],g.[TMAX],g.[TMIN],g.[WSF2]
FROM 
	mlGreenData as g 
	JOIN taxiLocations as pu on g.PULocationID= pu.LocationID 
	JOIN taxiLocations as do on g.DOLocationID= do.LocationID
	JOIN PaymentTypeDictionary as payD on g.payment_type=payD.ID
	JOIN RateCodeDictionary as rateD on g.RateCodeID=rateD.ID
	JOIN TripTypeDictionary as tripD on g.[trip_type]=tripD.ID
	JOIN VendorDictionary as vendorD on g.VendorID=vendorD.ID
GO
--View for "full" rich yellow Data
--Locations are resolved
CREATE OR ALTER VIEW richYellowData
AS
SELECT
-- Taxi Data Columns i want
		vendorD.Name as Vendor,
		y.[pickup_datetime],pu.Borough as pickup_Borough, pu.Zone as pickup_zone,
		y.[dropOff_datetime], do.Borough as dropoff_Borough, do.Zone as dropoff_zone
      --,[store_and_fwd_flag]
      ,y.[trip_distance]
      ,y.[passenger_count]
	  ,rateD.Name as Rate
	  ,payD.Name as Payment
      ,y.[fare_amount],y.[extra],y.[mta_tax],y.[tip_amount],y.[tolls_amount],y.[improvement_surcharge],y.[total_amount]
	  --WeatherData-Columns
	   --,[date_]
      ,y.[AWND],y.[SNOW],y.[SNWD],y.[TAVG],y.[TMAX],y.[TMIN],y.[WSF2]
FROM 
	mlYellowData as y 
	JOIN taxiLocations as pu on y.PULocationID= pu.LocationID 
	JOIN taxiLocations as do on y.DOLocationID= do.LocationID
	JOIN PaymentTypeDictionary as payD on y.payment_type=payD.ID
	JOIN RateCodeDictionary as rateD on y.RateCodeID=rateD.ID
	JOIN VendorDictionary as vendorD on y.VendorID=vendorD.ID
GO