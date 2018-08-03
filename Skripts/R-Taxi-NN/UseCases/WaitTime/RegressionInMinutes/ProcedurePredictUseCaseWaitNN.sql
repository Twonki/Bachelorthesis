USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN
-- This is about UseCase XXX
-- Inputs
-- Outputs
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictUseCaseWaitNN]
GO
CREATE PROCEDURE [dbo].[PredictUseCaseWaitNN]
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
	SET @inputCmd = N'SELECT TOP 10000
		DATEDIFF(MINUTE,pickup_datetime,dropOff_datetime) as Duration,
		DATEPART(MONTH, pickup_datetime) as Month,
		DATEPART(HOUR,pickup_datetime) as DayTime,
		ROUND((WetBulbTemp/10),0) as TempLevel,
		PULocationID as Location
		FROM mlYellowData
		WHERE PULocationID=DOLocationID 
		AND trip_distance=0
		ORDER BY NEWID() DESC;';
	DECLARE @predictScript nvarchar(max);
	SET @predictScript = N'
		library("MicrosoftML")
		model <- unserialize(as.raw(nb_model)); 

		data <- data.frame(TestData);
		print(summary(data));
		print(summary(model));
	   	# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));	
		data$Location <- factor(data$Location, levels=LocationLevels);
		data$DayTime<- factor(data$DayTime, levels=(as.factor(c(0:23))));
		data$Month<- factor(data$Month, levels=(as.factor(c(1:12))));

		#Use Prediction
		prediction <- rxPredict(model= model, data = data, verbose = 0);
		prediction <- round(prediction,0);
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
		[real_Duration] Integer,
		[Month] smallint,
		[DayTime] smallint,
		[TempLevel] smallint,
		[Location] smallint, 
		[predicted_Duration] integer)) 
END
GO