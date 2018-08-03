USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN
-- This is about UseCase XXX
-- Inputs
-- Outputs
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictRidesNN]
GO
CREATE PROCEDURE [dbo].[PredictRidesNN]
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
		trainRides INT,
		trainDate DATE,
		trainLocation SMALLINT,
		trainDayTime SMALLINT,
		trainTempLevel SMALLINT
	)
	INSERT INTO #TmpTestData
		Select COUNT(total_amount)as trainRides 
			,Convert(Date, pickup_datetime) as trainDate
			,PULocationID as trainLocation
			,DatePart(HOUR, pickup_datetime) as trainDayTime
			,CONVERT(SMALLINT,AVG(DryBulbTemp)/10) as trainTempLevel
		--from mlYellowData 
		from yellowTest
		group by
			PULocationID
			,Convert(DATE,pickup_datetime)
			,DATEPART(HOUR,pickup_datetime)
	--=====================
	-- Inputselection and Skript as Strings
	-- Curling newest Model from Database 
	--=====================
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	DECLARE @inputCmd nvarchar(max)
	set @inputCmd = N'Select 
		Rides as trainRides, 
		Date as trainDate,
		Location as trainLocation,
		DayTime as trainDayTime,
		TempLevel as trainTempLevel
		FROM aggregatedTest;';
	DECLARE @predictScript nvarchar(max);
	SET @predictScript = N'
		library("MicrosoftML")
		model <- unserialize(as.raw(nb_model)); 

		data <- data.frame(TestData);
	   
		# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));	
		data$trainLocation <- factor(data$trainLocation, levels=LocationLevels);
		data$trainTempLevel <- as.factor(data$trainTempLevel);
		data$trainDayTime <- as.factor(data$trainDayTime);

		data$trainDate <- as.factor(data$trainDate);
		#Use Prediction
		prediction <- rxPredict(model= model, data = data, verbose = 0);
		prediction <- round(prediction,0);
		#Check Prediction for really needed Values and Combine for good Output
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
		trainRides INT,
		trainDate DATE,
		trainLocation SMALLINT,
		trainDayTime SMALLINT,
		trainTempLevel SMALLINT, 
		[predictedRides] INT)) 
END
GO