USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN Passengers
-- This is about UseCase #3 Passengers Issue 24
-- Inputs: Pickup_Datetime,Pickup Location, Rate 
-- Outputs: Predicted Passengercount + InputValues
-- Additional Filters: 1<Passengers<10
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictPassengersNoSingleNN]
GO
CREATE PROCEDURE [dbo].[PredictPassengersNoSingleNN]
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
	SET @inputCmd = N'SELECT
		passenger_count as PCount, 
		PULocationID,
		CONVERT(DATE,pickup_datetime) as Date,
		DATEPART(HOUR,pickup_datetime) as Hour,
		RatecodeID as Rate
		FROM [yellowTest]
		WHERE passenger_count<10
		AND passenger_count>1';
	DECLARE @predictScript nvarchar(max);
	SET @predictScript = N'
		library("MicrosoftML")
		model <- unserialize(as.raw(nb_model)); 

		data <- data.frame(TestData);
		str(data);
		str(data$Date);
	    # Werte als Faktoren aufbereiten
		data$PCount <- factor(data$PCount, levels=(as.factor(c(1:10))));	

		LocationLevels <- as.factor(c(1:255));
		
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$Hour<- factor(data$Hour, levels=(as.factor(c(0:23))));
		data$Date <- as.factor(data$Date);
		#data$Date <- factor(data$Date, levels=(as.factor(c(0:364))));

		data$Rate <- factor(data$Rate, levels=(as.factor(c(1:5))));
		str(data);
		#Use Prediction
		prediction <- rxPredict(model= model, data = data, verbose = 0);

		#Check Prediction for really needed Values and Combine for good Output
		sum <- cbind(data, prediction$PredictedLabel);
		str(sum);
		OutputDataSet <- data.frame(sum)'

	EXECUTE sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
	WITH RESULT SETS ((
		[real_Passengers] smallint,
		[PULocationID] smallint, 
		[Date] date,
		[Hour] smallint,
		[Rate] smallint,
		[predicted_Passengers] smallint)) 
END
GO