--------------------------------
-- Creates a NN to predict total amount of the taxiride
--------------------------------
USE Taxi2Bachelor;
GO

-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictAmountNN]
GO
CREATE PROCEDURE [dbo].[PredictAmountNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	-- Get the latest Model.
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);  
	-- Produce input to the RML script.
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) id,total_amount,RatecodeID,trip_distance,duration_in_minutes,WetBulbTemp,DryBulbTemp,RelativeHumidity,passenger_count,Windspeed,extra,mta_tax,PULocationID,DOLocationID,fare_amount from yellowTest;';
	-- Prediction Script
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
		library("MicrosoftML")
		model <- unserialize(as.raw(nb_model)); 
		data <- data.frame(TestData);
		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$RatecodeID <- factor(data$RatecodeID, levels=(as.factor(c(1:5))));
		prediction <- rxPredict(model= model, data = data, verbose = 0);
		sum <- cbind(data, prediction);
		OutputDataSet <- data.frame(sum)
	   '
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
	WITH RESULT SETS ((
	[ID] uniqueidentifier, 
	[real_amount] float, 
	[RatecodeID] smallint,
	[trip_distance] float,
	[duration_in_minutes] float,
	[WetBulbTemp] real,
	[DryBulbTemp] real,
	[RelativeHumidity] smallint,
	[passenger_count] smallint,
	[Windspeed] smallint,
	[extra] real,
	[mta_tax] real,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[fare_amount] real, 
	[predicted_amount] float)) 
END
GO