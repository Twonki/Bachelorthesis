-----------------------------------------
-- Safe some Sample data for training and test
-- First Data for predicting total amount with linear regression
-- Second Data for predicting whether a tip is given with logit

-- Getting Random Data took very long, so i want to have a fixed snipped for fast access
-----------------------------------------
Use Taxi2Bachelor
GO
DROP TABLE IF EXISTS greenAmountSample;
DROP TABLE IF EXISTS greenAmountTest;
DROP TABLE IF EXISTS greenTipSample;
DROP TABLE IF EXISTS greenTipTest;

-------------------------------
--Amount Sample and Test Data 
-------------------------------
CREATE TABLE greenAmountSample (
	total_amount float  not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null)
GO
Insert into greenAmountSample
	Select top (1000000) total_amount, RatecodeID, trip_type, trip_distance 
	from mlGreenData 
	ORDER BY NEWID()
GO

CREATE TABLE greenAmountTest(
	id uniqueidentifier not null default NEWID() primary key,
	real_total_amount float not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null)
GO
Insert into greenAmountTest
	Select top (1000) NEWID(), total_amount, RatecodeID, trip_type, trip_distance 
	from mlGreenData 
	ORDER BY NEWID()
GO

-------------------------------
--Tip Sample and Test Data 
-------------------------------

CREATE TABLE greenTipSample (
	duration_in_minutes float not null,
	total_amount float  not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null,
	tipped bit not null)
GO
Insert into greenTipSample
	Select top (1000000) 
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes, 
		total_amount,
		RatecodeID, trip_type, trip_distance,
		tip_amount as tipped
	from mlGreenData 
ORDER BY NEWID()
GO

CREATE TABLE greenTipTest (
	id uniqueidentifier not null default NEWID() primary key,
	real_tipped bit not null,
	duration_in_minutes float not null,
	total_amount float  not null,
	RatecodeID smallint not null,
	trip_type smallint,
	trip_distance float not null)
GO
Insert into greenTipTest
	Select top (1000)
		NEWID() as id,
		Convert(bit, tip_amount) as real_tipped,
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes, 
		total_amount,
		RatecodeID, trip_type, trip_distance
	from mlGreenData 
ORDER BY NEWID()
GO