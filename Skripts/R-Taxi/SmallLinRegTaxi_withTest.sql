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
    , @output_data_1_name = N'trained_model'
    WITH RESULT SETS ((model varbinary(max)));
END;
GO

INSERT INTO total_amounts_models (model)
EXEC generate_small_linear_model;
GO
UPDATE total_amounts_models
SET model_name = ('rxSmallLinMod ' + format(getdate(), 'yyyy.MM.HH.mm', 'en-gb'))
WHERE model_name = 'default model';
GO
Select * from total_amounts_models;

--------------------------------
-- Use Model
--------------------------------

DROP PROCEDURE IF EXISTS use_my_small_amount_model;
GO
CREATE PROCEDURE use_my_small_amount_model
AS
BEGIN
	DECLARE @amountmodel varbinary(max) = (SELECT Top(1) model FROM total_amounts_models WHERE model_name LIKE 'rxSmallLinMod%'ORDER BY model_name desc);
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
EXEC use_my_small_amount_model;

DROP TABLE IF EXISTS #tmpAmountTestData;
CREATE TABLE #tmpAmountTestData(
	ID uniqueidentifier not null primary key,
	real_amount float,
	RatecodeID  smallint,
	trip_type smallint,
	trip_distance float,
	predicted_amount  float	
)

INSERT INTO #tmpAmountTestData
EXEC use_my_small_amount_model;
GO

---------------------------
-- Show me the Test Results
---------------------------

SELECT TOP(50) ID,(real_amount-predicted_amount) as miss_in_Dollar, (1-(real_amount/predicted_amount)) as accuracy, real_amount, predicted_amount FROM #tmpAmountTestData;
SELECT avg(abs((1-(real_amount/predicted_amount)))) as avg_accuracy From #tmpAmountTestData;
SELECT sum(abs(real_amount-predicted_amount)) as total_miss_in_Dollar, sum(real_amount) as total_real_amount, sum(predicted_amount) as total_predicted_amount FROM #tmpAmountTestData;

/* This is dumb, because it's not the mean-squared error. Faults in one direction tilt the ones in the other direction
SELECT avg( (1-(real_amount/predicted_amount))) as avg_accuracy From #tmpTestData;
SELECT avg( ((real_amount/predicted_amount))) as avg_accuracy From #tmpTestData;
Do not do this
*/
