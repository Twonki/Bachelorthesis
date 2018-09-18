USE Taxi2Bachelor;

DROP TABLE IF EXISTS NoSinglePassengerSample;
GO
CREATE TABLE [dbo].NoSinglePassengerSample(
	[ID] [uniqueidentifier] NOT NULL PRIMARY KEY,
	[total_amount] [float] NOT NULL,
	[RatecodeID] [smallint] NOT NULL,
	[trip_distance] [float] NOT NULL,
	[tip_amount] [float] NOT NULL,
	[duration_in_minutes] [float] NOT NULL,
	[PULocationID] [smallint] NOT NULL,
	[DOLocationID] [smallint] NOT NULL,
	[fare_amount] [real] NULL,
	[extra] [real] NULL,
	[DryBulbTemp] [real] NULL,
	[WetBulbTemp] [real] NULL,
	[RelativeHumidity] [smallint] NULL,
	[Windspeed] [smallint] NULL,
	[passenger_count] [smallint] NULL,
	[mta_tax] [real] NULL,
	[pickup_datetime] [datetime] NULL,
	[dropOff_datetime] [datetime] NULL)
GO

INSERT INTO NoSinglePassengerSample
	SELECT TOP(101000)
		NEWID() as id,
		total_amount, 
		RatecodeID,
		trip_distance,
		tip_amount,
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes, 
		PULocationID,
		DOLocationID,
		fare_amount,
		extra,
		DryBulbTemp,
		WetBulbTemp,
		RelativeHumidity,
		Windspeed,
		passenger_count,
		mta_tax,
		pickup_datetime,
		dropOff_datetime 
	FROM mlYellowData 
	WHERE passenger_count>1
	ORDER BY NEWID()
GO
GO
DROP TABLE IF EXISTS NoSinglePassengerTest;
GO
CREATE TABLE [dbo].NoSinglePassengerTest(
	[ID] [uniqueidentifier] NOT NULL PRIMARY KEY,
	[total_amount] [float] NOT NULL,
	[RatecodeID] [smallint] NOT NULL,
	[trip_distance] [float] NOT NULL,
	[tip_amount] [float] NOT NULL,
	[duration_in_minutes] [float] NOT NULL,
	[PULocationID] [smallint] NOT NULL,
	[DOLocationID] [smallint] NOT NULL,
	[fare_amount] [real] NULL,
	[extra] [real] NULL,
	[DryBulbTemp] [real] NULL,
	[WetBulbTemp] [real] NULL,
	[RelativeHumidity] [smallint] NULL,
	[Windspeed] [smallint] NULL,
	[passenger_count] [smallint] NULL,
	[mta_tax] [real] NULL,
	[pickup_datetime] [datetime] NULL,
	[dropOff_datetime] [datetime] NULL
)
GO
USE Taxi2Bachelor;
GO
INSERT INTO NoSinglePassengerTest
	SELECT TOP (1000) * FROM NoSinglePassengerSample;
GO
DELETE FROM NoSinglePassengerSample WHERE ID IN (SELECT ID FROM NoSinglePassengerTest);
GO
