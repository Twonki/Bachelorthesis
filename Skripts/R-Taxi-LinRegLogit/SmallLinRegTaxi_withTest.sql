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

DROP PROCEDURE IF EXISTS generate_small_linear_model;
GO
CREATE PROCEDURE generate_small_linear_model
AS
BEGIN
	CREATE TABLE #m (model varbinary(max));
	INSERT INTO #m
    EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
		form <- total_amount ~ RatecodeID+trip_type+trip_distance;
		lrmodel <- rxLinMod(formula = form, data = TaxiData); 
		summary(lrmodel);
		lrModel <-  rxLinMod(formula = form, data = TaxiData);
        trained_model <- data.frame(payload = as.raw(serialize(lrModel, connection=NULL)));'
    , @input_data_1 = N'Select total_amount,RatecodeID,trip_type,trip_distance from greenAmountSample;' 
    , @input_data_1_name = N'TaxiData' 
    , @output_data_1_name = N'trained_model';

	INSERT INTO Models (timest,model,model_name)
	SELECT CURRENT_TIMESTAMP AS timest, model, 'LinRegAmountSmall' AS name FROM #m;  
	DROP TABLE #m
END;
GO

EXEC generate_small_linear_model;

--------------------------------
-- Use Model
--------------------------------

DROP PROCEDURE IF EXISTS use_my_small_amount_model;
GO
CREATE PROCEDURE use_my_small_amount_model
AS
BEGIN
	DECLARE @amountmodel varbinary(max) = (SELECT Top(1) model FROM Models WHERE model_name='LinRegAmountSmall' ORDER BY timest desc);
	EXEC sp_execute_external_script
		@language = N'R'
		, @script = N'
				current_model <- unserialize(as.raw(amountmodel)); #unfolds the model from binary
				new <- data.frame(greenAmountTest); # Curls my new Data
				predicted.amount <- round(rxPredict(current_model, new),2);
				OutputDataSet <- cbind(new, predicted.amount); #Combine resources and amount for smarter output
				'
		, @input_data_1 = N' SELECT id, real_total_amount, RatecodeID,trip_type,trip_distance FROM greenAmountTest '
		, @input_data_1_name = N'greenAmountTest'
		, @params = N'@amountmodel varbinary(max)'
		, @amountmodel = @amountmodel 
	WITH RESULT SETS (([ID] uniqueidentifier, [real_amount] float, [RatecodeID] smallint,[trip_type] smallint,[trip_distance] float, [predicted_amount] float)) 

END;
GO
DROP TABLE IF EXISTS #Results;
CREATE TABLE #Results(
	ID uniqueidentifier not null primary key,
	real_amount float,
	RatecodeID  smallint,
	trip_type smallint,
	trip_distance float,
	predicted_amount  float	
)

INSERT INTO #Results
EXEC use_my_small_amount_model;
GO

---------------------------
-- Show me the Test Results
---------------------------

SELECT TOP(50) ID,(real_amount-predicted_amount) as miss_in_Dollar, (1-(real_amount/predicted_amount)) as accuracy, real_amount, predicted_amount FROM #Results;
SELECT avg(abs((1-(real_amount/predicted_amount)))) as avg_accuracy From #Results;
SELECT sum(abs(real_amount-predicted_amount)) as total_miss_in_Dollar, sum(real_amount) as total_real_amount, sum(predicted_amount) as total_predicted_amount FROM #Results;
