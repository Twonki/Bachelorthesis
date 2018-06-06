-----------------------------------------
-- Safe some Sample data for training and test
-- First Data for predicting total amount with linear regression
-- Second Data for predicting whether a tip is given with logit

-- Getting Random Data took very long, so i want to have a fixed snipped for fast access
-----------------------------------------
Use Taxi2Bachelor
GO
DROP TABLE IF EXISTS greenFullAmountSample;
DROP TABLE IF EXISTS greenFullAmountTest;
DROP TABLE IF EXISTS greenFullTipSample;
DROP TABLE IF EXISTS greenFullTipTest;

-------------------------------
--Amount Sample and Test Data 
-------------------------------
CREATE TABLE greenFullAmountSample (
	total_amount float  not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null,
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
Insert into greenFullAmountSample
	Select top (1000000) 
		total_amount, 
		RatecodeID, 
		trip_type, 
		trip_distance,
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
	from mlGreenData 
	ORDER BY NEWID()
GO

CREATE TABLE greenFullAmountTest(
	id uniqueidentifier not null default NEWID() primary key,
	real_total_amount float not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null,
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
	-- don't know, these maybe cause trouble
	pickup_datetime datetime,
	dropOff_datetime datetime)
GO
Insert into greenFullAmountTest
	Select top (1000) NEWID(), total_amount, RatecodeID, trip_type, trip_distance,
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
	from mlGreenData 
	ORDER BY NEWID()
GO

-------------------------------
--Tip Sample and Test Data 
-------------------------------

CREATE TABLE greenFullTipSample (
	duration_in_minutes float not null,
	total_amount float  not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null,
	tipped bit not null,

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
	-- don't know 
	pickup_datetime datetime,
	dropOff_datetime datetime)
GO
Insert into greenFullTipSample
	Select top (1000000) 
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes, 
		total_amount,
		RatecodeID, trip_type, trip_distance,
		tip_amount as tipped,
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
	from mlGreenData 
ORDER BY NEWID()
GO

CREATE TABLE greenFullTipTest (
	id uniqueidentifier not null default NEWID() primary key,
	real_tipped bit not null,
	duration_in_minutes float not null,
	total_amount float  not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null,
	
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
	-- don't know 
	pickup_datetime datetime,
	dropOff_datetime datetime)
GO
Insert into greenFullTipTest
	Select top (1000)
		NEWID() as id,
		Convert(bit, tip_amount) as real_tipped,
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes, 
		total_amount,
		RatecodeID, trip_type, trip_distance,
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
	from mlGreenData 
ORDER BY NEWID()
GO


	