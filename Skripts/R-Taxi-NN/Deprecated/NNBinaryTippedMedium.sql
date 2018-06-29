--=========================================================================================
-- Creates NN to estimate Tip given 
-- Only takes "NN" Parameters which are predictable, such as time, locations and distance
--=========================================================================================
USE Taxi2Bachelor;
GO

-- =============================================
-- Create Procedure to Create and Train NN
-- Takes Trainingsize as Parameter
-- Safes a model with timestamp in ModelTable
-- =============================================
DROP TABLE IF EXISTS #TmpData;
DROP TABLE IF EXISTS #Results;
CREATE TABLE #TmpData (
		tipped bit,
		Rate smallint, 
		trip_distance FLOAT, 
		total_amount FLOAT,
		duration_in_minutes INT,
		passenger_count SMALLINT,
		PULocationID INT,
		DOLocationID INT
)

INSERT INTO #TmpData
		SELECT
			CONVERT(BIT, tip_amount),
			RatecodeID, 
			trip_distance, 
			total_amount,
			duration_in_minutes,
			passenger_count,
			PULocationID,
			DOLocationID
FROM [dbo].[yellowSample]

DROP PROCEDURE IF EXISTS [dbo].[TrainTippedNN];
GO
CREATE PROCEDURE [dbo].[TrainTippedNN] 
@TrainingSize BigInt	
AS
BEGIN
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N')
		tipped, 
		Rate, 
		trip_distance, 
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID
		from #TmpData;')
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
			output Result auto from Magic all;
		")
		
		data <- InputData;

		data$tipped <- factor(data$tipped, levels=c("TRUE","FALSE"));

		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$Rate <- factor(data$Rate, levels=(as.factor(c(1:5))));
		form <-  tipped ~ Rate+trip_distance+total_amount+duration_in_minutes+passenger_count+PULocationID+DOLocationID;
		
		model <- rxNeuralNet(
				formula=form, 
				data = data,         
				type            = "binary",
				netDefinition   = netDefinition,
				numIterations = 250,
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
	select CURRENT_TIMESTAMP as timest, model, 'NNBinaryTippedMedium' as name from #m;  
	drop table #m
END

GO
EXEC TrainTippedNN @TrainingSize=1000000;
GO


-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictBinaryTippedNN]
GO
CREATE PROCEDURE [dbo].[PredictBinaryTippedNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		id,
		CONVERT(BIT,tip_amount) as tipped,
		RatecodeID as Rate,
		trip_distance,
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID 
		from yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   library("MicrosoftML")
       model <- unserialize(as.raw(nb_model)); 

	   data <- data.frame(TestData);
	   data$tipped <- as.factor(data$tipped);	
	   LocationLevels <- as.factor(c(1:265));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);

	   data$Rate <- factor(data$Rate, levels= as.factor(c(1:6)));
	   prediction <- rxPredict(model= model, data = data, verbose = 1);
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
	[real_tipped] bit,
	[rate] smallint,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_tipped] bit)) 
END
GO

--Exec PredictBinaryTippedNN @ModelName="NNBinaryTippedMedium";


-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
	[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[real_tipped] BIT,
	[Rate] smallint,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_tip] float
);
GO
Insert into #Results 
Exec [PredictBinaryTippedNN] @Modelname = "NNBinaryTippedMedium";
GO
SELECT Count(*) as total_misses FROM #Results WHERE real_tipped != predicted_tip;
SELECT TOP(10) * FROM #Results;
GO
DROP TABLE IF EXISTS #Results;
GO

DROP TABLE IF EXISTS #TmpData;

