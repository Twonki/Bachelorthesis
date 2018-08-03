USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN
-- This is about UseCase XXX
-- Inputs
-- Outputs
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictUseCaseNN]
GO
CREATE PROCEDURE [dbo].[PredictUseCaseNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	--=================
	-- Temporary Table for Usecase  
	-- Not every time necessary
	--=================
	DROP TABLE IF EXISTS #TmpTestData;
	CREATE TABLE #TmpTestData (
		Placeholder BIT,
		Placeholder2 smallint,
	)
	INSERT INTO #TmpTestData
		SELECT
			CONVERT(BIT, tip_amount),
			RatecodeID
	FROM [dbo].[yellowTest]

	--=====================
	-- Inputselection and Skript as Strings
	-- Curling newest Model from Database 
	--=====================
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	DECLARE @inputCmd nvarchar(max)
	SET @inputCmd = N'SELECT
		Placeholder,
		Placeholder2
		FROM #TmpTestData;';
	DECLARE @predictScript nvarchar(max);
	SET @predictScript = N'
		library("MicrosoftML")
		model <- unserialize(as.raw(nb_model)); 

		data <- data.frame(TestData);
	   
		#Factorize Input Accodringly
		PlaceholderLevels <- as.factor(c("Test1","Test2"));	
		data$Placeholder <- factor(data$Placeholder, levels=LocationLevels);
		
		#Use Prediction
		prediction <- rxPredict(model= model, data = data, verbose = 0);

		#For (multi)-class prediction
		sum <- cbind(data, prediction$PredictedLabel);

		#For Regression
		sum <- cbind(data,prediction);
		OutputDataSet <- data.frame(sum)'

	EXECUTE sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
	WITH RESULT SETS ((
		[real_Placeholder] Bit,
		[ID] uniqueidentifier, 
		[predicted_Placeholder] Bit)) 
END
GO