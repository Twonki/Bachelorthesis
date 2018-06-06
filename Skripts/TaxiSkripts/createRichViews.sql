
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
      ,g.[Visibility]
      ,g.[DryBulbTemp]
      ,g.[WetBulbTemp]
      ,g.[DewPointTemp]
      ,g.[RelativeHumidity]
      ,g.[WindSpeed]
      ,g.[WindDirection]
      ,g.[StationPressure]
      ,g.[PressureTendency]
      ,g.[PressureChange]
      ,g.[SeaLevelPressure]
      ,g.[AltimeterSetting]
      ,g.[Sunrise]
      ,g.[Sunset]
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
      ,y.[Visibility]
      ,y.[DryBulbTemp]
      ,y.[WetBulbTemp]
      ,y.[DewPointTemp]
      ,y.[RelativeHumidity]
      ,y.[WindSpeed]
      ,y.[WindDirection]
      ,y.[StationPressure]
      ,y.[PressureTendency]
      ,y.[PressureChange]
      ,y.[SeaLevelPressure]
      ,y.[AltimeterSetting]
      ,y.[Sunrise]
      ,y.[Sunset]
FROM 
	mlYellowData as y 
	JOIN taxiLocations as pu on y.PULocationID= pu.LocationID 
	JOIN taxiLocations as do on y.DOLocationID= do.LocationID
	JOIN PaymentTypeDictionary as payD on y.payment_type=payD.ID
	JOIN RateCodeDictionary as rateD on y.RateCodeID=rateD.ID
	JOIN VendorDictionary as vendorD on y.VendorID=vendorD.ID
