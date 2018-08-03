USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN
-- This is about UseCase TIP
-- Inputs
-- Outputs
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictUseCaseTipNN]
GO
CREATE PROCEDURE [dbo].[PredictUseCaseTipNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	
	--=====================
	-- Inputselection and Skript as Strings
	-- Curling newest Model from Database 
	--=====================
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	DECLARE @inputCmd nvarchar(max)
	set @inputCmd = N' SELECT
		trip_distance as distance,
		PULocationID,
		passenger_count as passengers,
		tip_amount
		FROM yellowTest;'
	DECLARE @predictScript nvarchar(max);
	SET @predictScript = N'
		library("MicrosoftML")
		model <- unserialize(as.raw(nb_model)); 
		print(summary(model));
		data <- data.frame(TestData);
		
		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		print(summary(data))
				
		#Use Prediction
		prediction <- rxPredict(model= model, data = data, verbose = 1);

		#Check Prediction for really needed Values and Combine for good Output
		sum <- cbind(data, prediction);

		print(summary(sum));

		OutputDataSet <- data.frame(sum)'

	EXECUTE sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
	WITH RESULT SETS ((
		[distance] float,
		[PULocationID] smallint,
		[passengers] smallint,
		[real_tip_amount] float,
		[predicted_tip_amount] float))
END
GO