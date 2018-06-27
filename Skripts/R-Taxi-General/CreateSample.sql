-----------------------------------------
-- Safe some Sample data for training and test

-- Getting Random Data took very long, so i want to have a fixed snipped for fast access

-- 1 million sampledata, 10k testdata
-----------------------------------------
Use Taxi2Bachelor
GO
DROP TABLE IF EXISTS yellowSample;
DROP TABLE IF EXISTS yellowTest;

-------------------------------
--Amount Sample and Test Data 
-------------------------------
CREATE TABLE yellowSample (
	ID UNIQUEIDENTIFIER primary key,
	total_amount float  not null,
	RatecodeID smallint not null,
	trip_distance float not null,
	tip_amount float not null,
	--addition to small sample
	duration_in_minutes float not null,
	PULocationID smallint not null,
	DOLocationID smallint not null,
	fare_amount real,
	extra real,
	DryBulbTemp real,
	WetBulbTemp real,
	RelativeHumidity smallint,
	Windspeed smallint,
	passenger_count smallint,
	mta_tax real,
	-- don't know these maybe cause trouble
	pickup_datetime datetime,
	dropOff_datetime datetime
)
GO
Insert into yellowSample
	Select top (1000000)
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
	from mlYellowData 
	ORDER BY NEWID()
GO

CREATE TABLE yellowTest(
	id uniqueidentifier not null default NEWID() primary key,
	total_amount float not null,
	RatecodeID smallint not null,
	trip_distance float not null,
	tip_amount float not null,
	duration_in_minutes float not null,
	PULocationID smallint not null,
	DOLocationID smallint not null,
	fare_amount real,
	extra real,
	DryBulbTemp real,
	WetBulbTemp real,
	RelativeHumidity smallint,
	Windspeed smallint,
	passenger_count smallint,
	mta_tax real,
	pickup_datetime datetime,
	dropOff_datetime datetime)
GO
Insert into yellowTest
	Select top (10000) 
		NEWID(), 
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
	from mlYellowData 
	ORDER BY NEWID()
GO