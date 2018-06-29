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

DROP PROCEDURE IF EXISTS [dbo].[TrainBinaryTippedMediumNN];
GO
CREATE PROCEDURE [dbo].[TrainBinaryTippedMediumNN] 
@TrainingSize BigInt	
AS
BEGIN
	--=================
	--Temporary Table for Tipped Y/N
	--=================
	DROP TABLE IF EXISTS #TmpData;
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
		FROM #TmpData;')
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
				verbose         = 0);
		trained_model <- data.frame(payload = as.raw(serialize(model, connection=NULL)));
	'

	CREATE TABLE #m (model varbinary(max));
	INSERT INTO #m
	EXECUTE sp_execute_external_script
	  @language = N'R'
	, @script = @cmd
	, @input_data_1 = @inputcmd 
    , @input_data_1_name=N'InputData'
	, @output_data_1_name = N'trained_model ';
	 
	INSERT INTO Models (timest,model,model_name)
	SELECT CURRENT_TIMESTAMP AS timest, model, 'NNBinaryTippedMedium' AS name FROM #m;  
	DROP TABLE #m

	DROP TABLE IF EXISTS #TmpData;
END
GO

