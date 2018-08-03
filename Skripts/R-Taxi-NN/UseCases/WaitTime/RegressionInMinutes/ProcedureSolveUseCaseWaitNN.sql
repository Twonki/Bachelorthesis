use Taxi2Bachelor;
GO

--=================================================
-- Fullfill the useCase:
-- Feed some Variables for the UseCase and predict with the Model
-- Input: PassengerCount, Distance, PULocation
-- Output: Input+PredictedTipAmount
--=================================================

DROP PROCEDURE IF EXISTS [dbo].[SolveUseCaseTipNN]
GO
CREATE PROCEDURE [dbo].[SolveUseCaseTipNN]
	@ModelName nvarchar(50),
	@Distance float,
	@PULocationID smallint,
	@Passengers smallint
AS
BEGIN	
	SET NOCOUNT ON;
	--=====================
	-- TemporaryTable
	--=====================
	CREATE TABLE #TmpData (
		tip_amount float,
		distance float,
		PULocationID smallint,
		passengers smallint
	)
	Insert Into #TmpData 
		VALUES(0,@Distance,@PULocationID,@Passengers);
	--=====================
	-- Inputselection and Skript as Strings
	-- Curling newest Model from Database 
	--=====================
	DECLARE @dbModel varbinary(max) = 
		(SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	DECLARE @inputCmd nvarchar(max)
	SET @inputCmd = N' SELECT
		tip_amount,
		distance,
		PULocationID,
		passengers
		FROM #TmpData;'
	DECLARE @predictScript nvarchar(max);
	SET @predictScript = N'
		library("MicrosoftML")
		model <- unserialize(as.raw(nb_model));
		data <- data.frame(TestData);
		
		print(summary(data));
		print(summary(model));

		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
				
		#Use Prediction
		prediction <- rxPredict(model= model, data = data, verbose = 1);
		print(summary(prediction));
		#Check Prediction for really needed Values and Combine for good Output
		sum <- cbind(data, prediction);
		OutputDataSet <- data.frame(sum)'

	EXECUTE sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
	WITH RESULT SETS ((
		[placeholder] float,
		[distance] float,
		[PULocationID] smallint,
		[passengers] smallint,
		[predicted_tip_amount] float))

	DROP TABLE IF EXISTS #TmpData;
END
GO