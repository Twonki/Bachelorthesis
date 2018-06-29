--=============================================
-- Mein NN Gerüst für Taschengeld
--==============================================
USE Taxi2Bachelor;
GO

-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictTipNN]
GO
CREATE PROCEDURE [dbo].[PredictTipNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'SELECT TOP (10000) 
		id,
		tip_amount,
		total_amount,
		RatecodeID,
		trip_distance,
		duration_in_minutes,
		WetBulbTemp,
		DryBulbTemp,
		RelativeHumidity,
		passenger_count,
		Windspeed,
		extra,
		mta_tax,
		PULocationID,
		DOLocationID,
		fare_amount
		FROM yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
		library("MicrosoftML");
		model <- unserialize(as.raw(nb_model));

		data <- data.frame(TestData);
		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$RatecodeID <- factor(data$RatecodeID, levels=(as.factor(c(1:5))));
		

		#score the model
		prediction <- rxPredict(model= model, data = data, verbose = 1);
		prediction <- round(prediction,2);
		sum <- cbind(data$tip_amount,data$id, prediction);
		OutputDataSet <- data.frame(sum)
	   '
	  -- Execute the RML script (train & score).
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
	WITH RESULT SETS((
		[real_tip_amount] float,
		[ID] UNIQUEIDENTIFIER,
		[predicted_tip_amount] float
	))
END
GO
