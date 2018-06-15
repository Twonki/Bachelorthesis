-----------------------------------------------------------
-- My First Attempts for R with Taxi Data 
-- Goal: Simple Linear Regression for total amount
-- Does include test and summary
-----------------------------------------------------------
USE Taxi2Bachelor
GO

--------------------------------
-- Creating Model (Data needs to be given)
--------------------------------

DROP PROCEDURE IF EXISTS generate_big_linear_model; 
GO
CREATE PROCEDURE generate_big_linear_model
AS
BEGIN
	create table #m (model varbinary(max));
	insert into #m
    EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
		form <- total_amount ~ RatecodeID+trip_type+trip_distance+duration_in_minutes+WetBulbTemp+DryBulbTemp+RelativeHumidity+passenger_count+Windspeed+extra+mta_tax+PULocationID+DOLocationID+fare_amount;
		lrModel <- rxLinMod(formula = form, data = TaxiData);
        trained_model <- data.frame(payload = as.raw(serialize(lrModel, connection=NULL)));'
    , @input_data_1 = N'Select total_amount,RatecodeID,trip_type,trip_distance,duration_in_minutes,WetBulbTemp,DryBulbTemp,RelativeHumidity,passenger_count,Windspeed,extra,mta_tax,PULocationID,DOLocationID,fare_amount from greenBigAmountSample;' 
    , @input_data_1_name = N'TaxiData' 
    , @output_data_1_name = N'trained_model';

	insert into Models (timest,model,model_name)
	select CURRENT_TIMESTAMP as timest, model, 'LinRegAmountBig' as name from #m;  
	drop table #m
END;
GO
EXEC generate_big_linear_model;
--------------------------------
-- Use Model
--------------------------------

DROP PROCEDURE IF EXISTS use_big_amount_model;
GO
CREATE PROCEDURE use_big_amount_model
AS
BEGIN
	DECLARE @amountmodel varbinary(max) = (SELECT Top(1) model FROM Models WHERE model_name='LinRegAmountBig' ORDER BY timest desc);
	EXEC sp_execute_external_script
		@language = N'R'
		, @script = N'
				current_model <- unserialize(as.raw(amountmodel)); #unfolds the model from binary
				new <- data.frame(greenBigAmountTest); # Curls my new Data
				predicted.amount <- round(rxPredict(current_model, new),2);
				OutputDataSet <- cbind(new, predicted.amount); #Combine resources and amount for smarter output
				'
		, @input_data_1 = N'Select id,real_total_amount,RatecodeID,trip_type,trip_distance,duration_in_minutes,WetBulbTemp,DryBulbTemp,RelativeHumidity,passenger_count,Windspeed,extra,mta_tax,PULocationID,DOLocationID,fare_amount from greenBigAmountTest;'
		, @input_data_1_name = N'greenBigAmountTest'
		, @params = N'@amountmodel varbinary(max)'
		, @amountmodel = @amountmodel 
	WITH RESULT SETS ((
	[ID] uniqueidentifier, 
	[real_amount] float, 
	[RatecodeID] smallint,
	[trip_type] smallint,
	[trip_distance] float,
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
	[predicted_amount] float)) 
END;
GO

EXEC use_big_amount_model;

DROP TABLE IF EXISTS #tmpAmountTestData
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

INSERT INTO #tmpAmountTestData
EXEC use_big_amount_model;
GO

---------------------------
-- Show me the Test Results
---------------------------

SELECT TOP(50) ID,(real_amount-predicted_amount) as miss_in_Dollar, (1-(real_amount/predicted_amount)) as accuracy, real_amount, predicted_amount FROM #tmpAmountTestData;
SELECT avg(abs((1-(real_amount/predicted_amount)))) as avg_accuracy From #tmpAmountTestData;
SELECT sum(abs(real_amount-predicted_amount)) as total_miss_in_Dollar, sum(real_amount) as total_real_amount, sum(predicted_amount) as total_predicted_amount FROM #tmpAmountTestData;
