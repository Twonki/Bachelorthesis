-----------------------------------------------------------
-- My First Attempts for R with Taxi Data 
-- Goal: Estimate whether a tip will be given (yes or no, no amount)
-- Does not Include Testing (Different file)
-----------------------------------------------------------

Use Taxi2Bachelor
GO

--------------------------
-- Creating Model (Data needs to be given)
--------------------------

DROP PROCEDURE IF EXISTS generate_logit_model;
GO
CREATE PROCEDURE generate_logit_model
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

EXEC generate_logit_model;
GO
--------------------------------
-- Use the Model
--------------------------------

DECLARE @tipmodel varbinary(max) = (SELECT TOP(1) model FROM Models WHERE model_name='LogitTipSmall' ORDER BY timest DESC);
EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
            current_model <- unserialize(as.raw(tipmodel)); #unfolds the model from binary
            new <- data.frame(greenTipTest); # Curls my new Data
            predicted.tip <- rxPredict(current_model, new);
            OutputDataSet <- cbind(new,predicted.tip);
            '
    , @input_data_1 = N' SELECT total_amount,duration_in_minutes,trip_type,RatecodeID,trip_distance FROM greenTipTest ' 
    , @input_data_1_name = N'greenTipTest'
    , @params = N'@tipmodel varbinary(max)' 
    , @tipmodel = @tipmodel
--WITH RESULT SETS (([new_speed] INT, [predicted_distance] INT)) --Name Stuff with usefull name and datatype
GO

-- Works, but Result is wierd ... i guess 100% TipRate is not correct