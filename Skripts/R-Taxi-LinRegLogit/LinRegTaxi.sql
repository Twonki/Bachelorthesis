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
EXEC generate_linear_model;

--------------------------------
-- Use Model
--------------------------------

DECLARE @amountmodel varbinary(max) = (SELECT Top(1) model FROM Models WHERE model_name='LinRegAmountSmall' ORDER BY timest DESC);
EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
            current_model <- unserialize(as.raw(amountmodel)); #unfolds the model from binary
            new <- data.frame(greenAmountTest); # Curls my new Data
            predicted.amount <- rxPredict(current_model, new);
            OutputDataSet <- cbind(new, predicted.amount); #Combine resources and amount for smarter output
            '
    , @input_data_1 = N' SELECT RatecodeID,trip_type,trip_distance FROM greenAmountTest '
    , @input_data_1_name = N'greenAmountTest'
    , @params = N'@amountmodel varbinary(max)'
    , @amountmodel = @amountmodel 
WITH RESULT SETS (([RatecodeID] smallint,[trip_type] smallint,[trip_distance] float, [predicted_amount] float)) 
GO