-----------------------------------------------------------
-- My First Attempts for R with Taxi Data 
-- Goal: Simple Linear Regression for total amount
-- Does not include testing (different file)
-----------------------------------------------------------
USE Taxi2Bachelor
GO

--------------------------------
-- Creating Model (Data needs to be given)
--------------------------------

DROP PROCEDURE IF EXISTS generate_linear_model;
GO
CREATE PROCEDURE generate_linear_model
AS
BEGIN
	CREATE TABLE #m (model varbinary(max));
	INSERT INTO #m
    EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
		form <- total_amount ~ RatecodeID+duration_in_minutes+trip_distance+DOLocationID+PULocationID;
		lrmodel <- rxLinMod(formula = form, data = TaxiData); 
		summary(lrmodel);
		lrModel <-  rxLinMod(formula = form, data = TaxiData);
        trained_model <- data.frame(payload = as.raw(serialize(lrModel, connection=NULL)));'
    , @input_data_1 = N'Select total_amount,RatecodeID,duration_in_minutes,trip_distance,DOLocationID,PULocationID from yellowSample;' 
    , @input_data_1_name = N'TaxiData' 
    , @output_data_1_name = N'trained_model';
	
	INSERT INTO Models (timest,model,model_name)
	SELECT CURRENT_TIMESTAMP AS timest, model, 'LinRegAmountSmall' AS name FROM #m;  
	DROP TABLE #m
END;
GO
EXEC generate_linear_model;

--------------------------------
-- Use Model
--------------------------------

DROP PROCEDURE IF EXISTS [dbo].[PredictAmountLinReg]
GO
CREATE PROCEDURE [dbo].[PredictAmountLinReg]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		id,
		total_amount,
		RatecodeID,
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes,
		trip_distance,
		PULocationID,
		DOLocationID 
		from yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   current_model <- unserialize(as.raw(nb_model));
            new <- data.frame(TestData); # Curls my new Data
            predicted.amount <- round(rxPredict(current_model, new),2);
            OutputDataSet <- cbind(new, predicted.amount); 
		'
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
WITH RESULT SETS ((
	[id] UNIQUEIDENTIFIER,
	[total_amount] float,
	[rate] smallint,
	[duration] int,
	[trip_distance] float,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_total_amount] float)) 
	END
GO

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[real_amount_amount] float,
	[trip_distance] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_amount_amount] float
);
GO
Insert into #Results 
EXEC [PredictAmountLinReg] @ModelName="LinRegAmountSmall";
GO
DECLARE @realMean float;
SET @realMean = (SELECT AVG(real_amount_amount) FROM #Results);

SELECT
	(SUM(POWER(real_amount_amount - @realMean,2))) AS RSS,
	(SUM(POWER((real_amount_amount - predicted_amount_amount),2))) AS TSS,
	1- ((SUM(POWER((real_amount_amount - predicted_amount_amount),2)))/(SUM(POWER(real_amount_amount - @realMean,2)))) as RQuadrat,
	sum(abs(real_amount_amount-predicted_amount_amount)) as miss_in_Dollar,
	sum(predicted_amount_amount) as predicted_total_amount, 
	sum(real_amount_amount) as real_amount
FROM #Results;

SELECT Top (100) abs(real_amount_amount-predicted_amount_amount) as miss_in_Dollar, predicted_amount_amount as estamount, real_amount_amount as realamount from #Results;
GO
DROP TABLE IF EXISTS #Results;
GO