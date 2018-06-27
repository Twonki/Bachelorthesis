--=========================================================================================
-- Creates NN to estimate DropOff-Location
-- Only takes "good" Parameters which are predictable, such as time, locations and distance
--=========================================================================================
USE Taxi2Bachelor;
GO

-- =============================================
-- Create Procedure to Create and Train NN
-- Takes Trainingsize as Parameter
-- Safes a model with timestamp in ModelTable
-- =============================================
	 
DROP PROCEDURE IF EXISTS [dbo].[TrainRatioNN];
GO
CREATE PROCEDURE [dbo].[TrainRatioNN] 
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
			output Result auto sigmoid from Magic all;
		")
		data <- InputData;	
		LocationLevels <- as.factor(c(1:265));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$RatecodeID <- factor(data$RatecodeID, levels=as.factor(c(1:6)) );
		
		form <- DOLocationID ~ total_amount+trip_distance+duration_in_minutes+passenger_count+PULocationID+RatecodeID;
		model <- rxNeuralNet(
				formula=form, 
				data = data,              
				type            = "multiClass",
				#netDefinition   = netDefinition,
				numIterations = 250,
				# normalize       = "yes",
				verbose         = 1);
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
	select CURRENT_TIMESTAMP as timest, model, 'NNDropOffModelMedium' as name from #m;  
	drop table #m
END

GO
EXEC TrainRatioNN @TrainingSize=1000000;
GO

-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].PredictDOLocationNN
GO
CREATE PROCEDURE [dbo].PredictDOLocationNN
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		id,
		RatecodeID, 
		trip_distance, 
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID 
		from yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   library("MicrosoftML");
       model_un <- unserialize(as.raw(nb_model)); 
	   data <- data.frame(TestData); 
		LocationLevels <- as.factor(c(1:265));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$RatecodeID <- factor(data$RatecodeID, levels=as.factor(c(1:6)) );
	   prediction <- rxPredict(model= model_un, data = data, verbose = 1);

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
	[ID] uniqueidentifier, 
	[RateCode] float,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_DropOffLocation] smallint)) 
END
GO

EXEC PredictDOLocationNN @ModelName="NNDropOffModelMedium";
-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
	[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[RateCode] float,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_DropOffLocation] smallint
	)
GO
Insert into #Results 
EXEC PredictDOLocationNN @ModelName="NNDropOffModelMedium";
SELECT COUNT(*) FROM #Results WHERE DOLocationID!=predicted_DropOffLocation;
SELECT TOP(50) * FROM #Results;
GO
DROP TABLE IF EXISTS #Results;
GO
