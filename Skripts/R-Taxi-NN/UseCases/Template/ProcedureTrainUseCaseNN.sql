--=========================================================================================
-- Creates NN to estimate FFF
-- This is Usecase XXX 
-- Input: A B C
-- Output: D E F
--=========================================================================================
USE Taxi2Bachelor;
GO

DROP PROCEDURE IF EXISTS [dbo].[TrainXXXNN];
GO
CREATE PROCEDURE [dbo].[TrainXXXNN] 
@TrainingSize BigInt	
AS
BEGIN
	--=================
	--Temporary Table for Usecase  
	-- Not every time necessary
	--=================
	DROP TABLE IF EXISTS #TmpData;
	CREATE TABLE #TmpData (
		Placeholder bit,
		Placeholder2 smallint,
	)
	INSERT INTO #TmpData
		SELECT
			CONVERT(BIT, tip_amount),
			RatecodeID
	FROM [dbo].[yellowSample]

	--=====================
	-- Inputselection and Skript as Strings
	--=====================
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N')
		Placeholder, 
		Placeholder2
		FROM #TmpData;')
	SET NOCOUNT ON;
	-- Construct the RML script.
	declare @cmd nvarchar(max)
	set @cmd = N'
		library(MicrosoftML)
		library(dplyr)

		#Netz definieren
		netDefinition <- ("
			input Data auto;
			hidden Mystery [100] sigmoid from Data all;
			hidden Magic [100] sigmoid from Mystery all;
			output Result auto from Magic all;
		")
		
		data <- InputData;
		
		# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$Rate <- factor(data$Rate, levels=(as.factor(c(1:5))));

		optimParms <- list(
		  optimizer = "sgd",
		  learningRate = 0.05,
		  lRateRedRatio = 0.97,
		  lRateRedFreq = 10,
		  momentum = 0.3,
		  decay = 0.95
		);

		optimiser <- with(optimParms, sgd(learningRate  = learningRate,lRateRedRatio = lRateRedRatio,lRateRedFreq  = lRateRedFreq,momentum      = momentum));

		#Formel
		form <-  Placeholder ~ Placeholder2
		model <- rxNeuralNet(
				formula=form, 
				data = data,         
				type            = "binary",
				netDefinition   = netDefinition,
				optimizer=optimiser,
				numIterations = 250,
				verbose         = 0);
		trained_model <- data.frame(payload = as.raw(serialize(model, connection=NULL)));
	'

	CREATE TABLE #m (model varbinary(max));

	--=====================================
	-- Execute and Store
	--=====================================
	INSERT INTO #m
		EXECUTE sp_execute_external_script
		  @language = N'R'
		, @script = @cmd
		, @input_data_1 = @inputcmd 
		, @input_data_1_name=N'InputData'
		, @output_data_1_name = N'trained_model ';
	 
	INSERT INTO Models (timest,model,model_name)
		SELECT CURRENT_TIMESTAMP AS timest, model, 'NNXXX' AS name FROM #m;  
	DROP TABLE #m
	DROP TABLE IF EXISTS #TmpData;
END
GO

