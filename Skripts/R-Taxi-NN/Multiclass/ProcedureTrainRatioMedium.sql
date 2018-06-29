--=========================================================================================
-- Creates NN to predict the RatecodeID of the Ride
-- Only takes "good" Parameters which are predictable, such as time, locations and distance
--=========================================================================================
USE Taxi2Bachelor;
GO
-- =============================================
-- Create Procedure to Create and Train NN
-- Takes Trainingsize as Parameter
-- Safes a model with timestamp in ModelTable
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[TrainRatioMediumNN];
GO
CREATE PROCEDURE [dbo].[TrainRatioMediumNN] 
@TrainingSize BigInt	
AS
BEGIN
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N') 
		RatecodeID, 
		trip_distance, 
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID
		from yellowSample;')
	SET NOCOUNT ON;
	-- Construct the RML script.
	declare @cmd nvarchar(max)
	set @cmd = N'
		library(MicrosoftML)
		library(dplyr)
		netDefinition <- ("
			input Data auto;
			hidden Mystery [100] sigmoid from Data all;
			hidden Magic [100] sigmoid from Mystery all;
			output Result auto softmax from Magic all;
		")
		data <- InputData;
		LocationLevels <- as.factor(c(1:265));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		data$RatecodeID <- factor(data$RatecodeID, levels=as.factor(c(1:6)) );
		form <- RatecodeID ~ trip_distance+total_amount+duration_in_minutes+passenger_count+PULocationID+DOLocationID;
		
		model <- rxNeuralNet(
				formula = form, 
				data = data, 
				netDefinition=netDefinition,            
				type            = "multiClass",
				numIterations = 250,
				verbose         = 0);
		trained_model <- data.frame(payload = as.raw(serialize(model, connection=NULL)));
	'
	create table #m (model varbinary(max));
	insert into #m
		execute sp_execute_external_script
		  @language = N'R'
		, @script = @cmd
		, @input_data_1 = @inputcmd 
		, @input_data_1_name=N'InputData'
		, @output_data_1_name = N'trained_model ';
	insert into Models (timest,model,model_name)
		select CURRENT_TIMESTAMP as timest, model, 'NNRatioMedium' as name from #m;  
	drop table #m
END