-----------------------------------------
-- Safe some Sample data for training and test
-- Getting Random Data took very long, so i want to have a fixed Snapshot for fast access/Comparing models

-- First Data for predicting total amount with linear regression
-- Second Data for predicting whether a tip is given with logit
-- Third Data for predicting tip with lin-reg
-----------------------------------------
Use Taxi2Bachelor
GO
DROP TABLE IF EXISTS greenBigAmountSample;
DROP TABLE IF EXISTS greenBigAmountTest;
DROP TABLE IF EXISTS greenBigTipSample;
DROP TABLE IF EXISTS greenBigTipTest;
DROP TABLE IF EXISTS greenBigTipAmountSample;
DROP TABLE IF EXISTS greenBigTipAmountTest;

-------------------------------
--Amount Sample and Test Data 
-------------------------------
CREATE TABLE greenBigAmountSample (
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
Insert into greenBigAmountSample
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

CREATE TABLE greenBigAmountTest(
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
Insert into greenBigAmountTest
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

CREATE TABLE greenBigTipSample (
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
Insert into greenBigTipSample
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

CREATE TABLE greenBigTipTest (
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
Insert into greenBigTipTest
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

CREATE TABLE greenBigTipAmountSample (
	tip_amount float not null,
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
Insert into greenBigTipAmountSample
	Select top (1000000) 
		tip_amount,
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

CREATE TABLE greenBigTipAmountTest(
	id uniqueidentifier not null default NEWID() primary key,
	real_tip_amount float not null,
	total_amount float not null,
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
Insert into greenBigTipAmountTest
	Select top (1000) NEWID(),
		tip_amount,
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