-----------------------------------------------------------
-- My First Attempts for R with Taxi Data 
-- Goal: Estimate whether a tip will be given (yes or no, no amount)
-----------------------------------------------------------

Use Taxi2Bachelor
GO

--------------------------
-- Creating Model (Data needs to be given)
--------------------------

DROP PROCEDURE IF EXISTS generate_small_logit_model;
GO
CREATE PROCEDURE generate_small_logit_model
AS
BEGIN
	CREATE TABLE #m (model varbinary(max));
	INSERT INTO #m
    EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
		form <- tipped ~ duration_in_minutes+total_amount+RatecodeID+trip_type+trip_distance;
		logitmodel <- rxLogit(formula = form, data = TaxiData) ; 
        trained_model <- data.frame(payload = as.raw(serialize(logitmodel, connection=NULL)));
		'
    , @input_data_1 = N'Select tipped,duration_in_minutes, total_amount,trip_type,RatecodeID,trip_distance  from greenTipSample;' 
    , @input_data_1_name = N'TaxiData'
    , @output_data_1_name = N'trained_model';

	INSERT INTO Models (timest,model,model_name)
	SELECT CURRENT_TIMESTAMP AS timest, model, 'LogitTipSmall' AS name FROM #m;  
	DROP TABLE #m
END;
GO

EXEC generate_small_logit_model;

--------------------------------
-- Use the Model
-- Put the Data in a temporary table
--------------------------------

DROP PROCEDURE IF EXISTS use_my_small_tip_model
GO
CREATE PROCEDURE use_my_small_tip_model
AS
BEGIN
	DECLARE @tipmodel varbinary(max) = (SELECT TOP(1) model FROM Models WHERE (model_name= 'LogitTipSmall') ORDER BY timest DESC);
	EXEC sp_execute_external_script
		@language = N'R'
		, @script = N'
				current_model <- unserialize(as.raw(tipmodel)); #unfolds the model from binary
				new <- data.frame(greenTipTest); # Curls my new Data
				predicted.tip <- rxPredict(current_model, new);
				OutputDataSet <- cbind(new,predicted.tip);
				'
		, @input_data_1 = N' SELECT id,real_tipped,total_amount,duration_in_minutes,trip_type,RatecodeID,trip_distance FROM greenTipTest ' 
		, @input_data_1_name = N'greenTipTest'
		, @params = N'@tipmodel varbinary(max)' 
		, @tipmodel = @tipmodel
	WITH RESULT SETS ((
	[ID] uniqueidentifier,[real_tipped] bit, [total_amount] float,
	[duration_in_minutes] int, [trip_type] smallint, [RatecodeID] smallint,
	[trip_distance] float, [estimated_tip] float ))
END
GO

DROP TABLE IF EXISTS #Results;
CREATE TABLE #Results(
	ID uniqueidentifier not null primary key,
	real_tipped bit,
	total_amount float,
	duration_in_minutes int,
	RatecodeID  smallint,
	trip_type smallint,
	trip_distance float,
	estimated_tip  float	
)

INSERT INTO #Results
EXEC use_my_small_tip_model;
GO

--------------------------
-- Test the Model
--------------------------

SELECT ID, real_tipped, ROUND(estimated_tip,0) as predicted_tip, estimated_tip as estimated_chance FROM #Results;

SELECT sum(abs(real_tipped - ROUND(estimated_tip,0))) as total_misses from #Results;
