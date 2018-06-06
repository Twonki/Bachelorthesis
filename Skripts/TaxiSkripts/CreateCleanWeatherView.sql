USE [Taxi2Bachelor]
GO

/****** Object:  View [dbo].[cleanWeatherData]    Script Date: 05.06.2018 14:07:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[cleanWeatherData]
AS
SELECT        
	Convert(DATE, w.DATE) as Date,
	DATEPART(HOUR,w.DATE) as Hour,
	DATETIMEFROMPARTS(DATEPART(Year,DATE),DatePart(month,DATE),Datepart(day,DATE), DAILYSunrise/100,DAILYSunrise%100,00,00) as Sunrise,
	DATETIMEFROMPARTS(DATEPART(Year,DATE),DatePart(month,DATE),Datepart(day,DATE), DAILYSunset/100,DAILYSunset%100,00,00) as Sunset,
	
	HOURLYAltimeterSetting as AltimeterSetting, 
	HOURLYSeaLevelPressure as SeaLevelPressure, 
	HOURLYPressureChange as PressureChange, 
	HOURLYPressureTendency as PressureTendency, 
	HOURLYStationPressure as StationPressure, 
	HOURLYWindDirection as WindDirection, 
	HOURLYWindSpeed as WindSpeed, 
    HOURLYRelativeHumidity as RelativeHumidity, 
	HOURLYDewPointTempC as DewPointTemp, 
	HOURLYWETBULBTEMPC as WetBulbTemp, 
	HOURLYDRYBULBTEMPC as DryBulbTemp, 
	HOURLYVISIBILITY as Visibility
FROM            dbo.WeatherData as w
GO


