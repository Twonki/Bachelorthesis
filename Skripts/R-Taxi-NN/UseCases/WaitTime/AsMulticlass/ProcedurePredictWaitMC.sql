USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictWaitMCNN]
GO
CREATE PROCEDURE [dbo].[PredictWaitMCNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	SET @inputCmd = N'SELECT TOP 10000
		DATEDIFF(MINUTE,pickup_datetime,dropOff_datetime) as Duration,
		DATEPART(MONTH, pickup_datetime) as Month,
		DATEPART(HOUR,pickup_datetime) as DayTime,
		ROUND((WetBulbTemp/10),0) as TempLevel,
		PULocationID as Location
		FROM mlYellowData
		WHERE PULocationID=DOLocationID 
		AND trip_distance=0
		AND DATEDIFF(MINUTE,pickup_datetime,dropOff_datetime) >=0
		AND DATEDIFF(MINUTE,pickup_datetime,dropOff_datetime) <=20
		ORDER BY NEWID() DESC;';

	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
		model <- unserialize(as.raw(nb_model)); 

		data <- data.frame(TestData);
		print(summary(data));
		print(summary(model));
	   	# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));
		data$Duration <- factor(data$Duration, levels=(as.factor(c(1:20))));
		data$Location <- factor(data$Location, levels=LocationLevels);
		data$DayTime<- factor(data$DayTime, levels=(as.factor(c(0:23))));
		data$Month<- factor(data$Month, levels=(as.factor(c(1:12))));

		#Use Prediction
		prediction <- rxPredict(model= model, data = data, verbose = 0);

		#Check Prediction for really needed Values and Combine for good Output
		sum <- cbind(data, prediction$PredictedLabel);
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
	WITH RESULT SETS ((
		[real_Duration] Integer,
		[Month] smallint,
		[DayTime] smallint,
		[TempLevel] smallint,
		[Location] smallint, 
		[predicted_Duration] integer)) 
END
GO
