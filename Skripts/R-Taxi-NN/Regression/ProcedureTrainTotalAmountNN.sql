USE Taxi2Bachelor;
GO

-- =============================================
-- Create Procedure to Create and Train NN
-- Takes Trainingsize as Parameter
-- Safes a model with timestamp in ModelTable
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[TrainAmountNN];
GO
CREATE PROCEDURE [dbo].[TrainAmountNN] 
@TrainingSize BigInt	
AS
BEGIN
	SET NOCOUNT ON;

	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N') 
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
		from [dbo].[yellowSample];')
	
	-- Construct the RML script.
	declare @cmd nvarchar(max)
	set @cmd = N'
		library(MicrosoftML)
		library(dplyr)

		netDefinition <- ("
			input Data auto;
			hidden Mystery [100] sigmoid from Data all;
			hidden Magic [100] sigmoid from Mystery all;
			output Result [1] linear from Magic all;
		")

		data <- InputData;
		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$RatecodeID <- factor(data$RatecodeID, levels=(as.factor(c(1:5))));

		form <- total_amount ~ RatecodeID+trip_distance+duration_in_minutes+WetBulbTemp+DryBulbTemp+RelativeHumidity+passenger_count+Windspeed+extra+mta_tax+PULocationID+DOLocationID+fare_amount;

		model <- rxNeuralNet(formula=form, data = data,              
						   type            = "regression",
						   netDefinition   = netDefinition,
						   numIterations = 250,
						   normalize       = "yes",
						   verbose         = 0,
						   postTransformCache = "Disk");
		trained_model <- data.frame(payload = as.raw(serialize(model, connection=NULL)));
	'

	create table #m (model varbinary(max));
	insert into #m
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @cmd
	, @input_data_1 = @inputCmd 
	, @input_data_1_name=N'InputData'
	, @output_data_1_name = N'trained_model ';

	INSERT INTO Models (timest,model,model_name)
	SELECT CURRENT_TIMESTAMP AS timest, model, 'NNTotalAmount' AS name FROM #m;  
	DROP TABLE #m
END
GO