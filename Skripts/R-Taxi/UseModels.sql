------------------------------
-- Just Use my Models 
-- This is like the very last rows of each model-Creation
------------------------------

DROP TABLE IF EXISTS #tmpTipAmountTestData
DROP TABLE IF EXISTS #tmpAmountTestData
DROP TABLE IF EXISTS #tmpTipTestData;

CREATE TABLE #tmpTipAmountTestData(
	ID uniqueidentifier not null primary key,
	[real_tip_amount] float,
	[real_amount] float,
	RatecodeID  smallint,
	trip_type smallint,
	trip_distance float,
	[duration_in_minutes] float,
	[WetBulbTemp] real,
	[DryBulbTemp] real,
	[RelativeHumidity] smallint,
	[passenger_count] smallint,
	[Windspeed] smallint,
	[extra] real,
	[mta_tax] real,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[fare_amount] real, 
	predicted_amount  float	
)
CREATE TABLE #tmpTipTestData(
	ID uniqueidentifier not null primary key,
	real_tipped bit,
	total_amount float,
	duration_in_minutes int,
	RatecodeID  smallint,
	trip_type smallint,
	trip_distance float,
	[WetBulbTemp] real,
	[DryBulbTemp] real,
	[RelativeHumidity] smallint,
	[passenger_count] smallint,
	[Windspeed] smallint,
	[extra] real,
	[mta_tax] real,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[fare_amount] real, 
	estimated_tip  float	
)

CREATE TABLE #tmpAmountTestData(
	ID uniqueidentifier not null primary key,
	real_amount float,
	RatecodeID  smallint,
	trip_type smallint,
	trip_distance float,
	
	[duration_in_minutes] float,
	[WetBulbTemp] real,
	[DryBulbTemp] real,
	[RelativeHumidity] smallint,
	[passenger_count] smallint,
	[Windspeed] smallint,
	[extra] real,
	[mta_tax] real,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[fare_amount] real, 

	predicted_amount  float	
)

INSERT INTO #tmpTipAmountTestData
EXEC use_my_tipAmount_model;
GO

INSERT INTO #tmpTipTestData
EXEC use_my_Big_tip_model;
GO


INSERT INTO #tmpAmountTestData
EXEC use_big_amount_model;
GO

--SELECT TOP(50) ID,(real_amount-predicted_amount) as miss_in_Dollar, (1-(real_amount/predicted_amount)) as accuracy, real_amount, predicted_amount FROM #tmpAmountTestData;
SELECT 1-avg(abs((1-(real_amount/predicted_amount)))) as avg_accuracy_amount From #tmpAmountTestData;
SELECT sum(abs(real_amount-predicted_amount)) as total_miss_in_Dollar, sum(real_amount) as total_real_amount, sum(predicted_amount) as total_predicted_amount FROM #tmpAmountTestData;

--SELECT TOP(50) ID,(real_tip_amount-predicted_amount) as miss_in_Dollar, (1-(real_tip_amount/predicted_amount)) as accuracy, real_tip_amount, predicted_amount FROM #tmpTipAmountTestData;
SELECT 1-avg(abs((1-(real_tip_amount/predicted_amount)))) as avg_accuracy_tip From #tmpTipAmountTestData;
SELECT sum(abs(real_tip_amount-predicted_amount)) as total_miss_in_Dollar, sum(real_tip_amount) as total_real_tip_amount, sum(predicted_amount) as total_predicted_tip_amount FROM #tmpTipAmountTestData;

--SELECT ID, real_tipped, ROUND(estimated_tip,0) as predicted_tip, estimated_tip as estimated_chance FROM #tmpTipTestData;
SELECT sum(abs(real_tipped - ROUND(estimated_tip,0))) as total_misses, count(*) as total_guesses from #tmpTipTestData;