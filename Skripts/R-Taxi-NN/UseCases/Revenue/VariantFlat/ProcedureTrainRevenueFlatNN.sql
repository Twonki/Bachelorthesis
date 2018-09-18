--=========================================================================================
-- Creates NN to estimate the Revenue
-- This is Usecase Revenue #5 Issue 21
-- The MLYellowData is grouped by Date, Hour and (Pickup)Location
-- A Flag will be set for Rain (y/n) and heat will be factorized in MinusDegrees, LowTemp, AvgTemp, HighTemp
-- Input: Sum(Costs), PickupLocation, Date, Hour, Rain(y/n) 
-- Output: A Linear Regression Model to predict revenue
--=========================================================================================
USE Taxi2Bachelor;
GO

DROP PROCEDURE IF EXISTS [dbo].[TrainRevenueFlatNN];
GO
CREATE PROCEDURE [dbo].[TrainRevenueFlatNN] 
@TrainingSize BigInt	
AS
BEGIN
	DROP TABLE IF EXISTS #TmpData;

	--=====================
	-- Inputselection and Skript as Strings
	--=====================
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N')
		Revenue as trainRevenue, 
		Date as trainDate,
		Location as trainLocation,
		DayTime as trainDayTime,
		TempLevel as trainTempLevel
		FROM aggregatedSample;')
	SET NOCOUNT ON;
	-- Construct the RML script.
	declare @cmd nvarchar(max)
	set @cmd = N'
		library(MicrosoftML)
		library(dplyr)

		#Netz definieren
		netDefinition <- ("
			input Data auto;
			hidden Mystery [250] tanh from Data all;
			output Result [1] linear from Mystery all;
		")
		
		data <- InputData;
		
		# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:265));	
		data$trainLocation <- factor(data$trainLocation, levels=LocationLevels);
		data$trainTempLevel <- as.factor(data$trainTempLevel);
		data$trainDayTime <- as.factor(data$trainDayTime);
		
		data$trainDate <- as.factor(data$trainDate);

		str(data);
		print(summary(data));

		optimiser <- sgd();
		#Formel
		form <-  trainRevenue ~ trainDate+trainTempLevel+trainLocation+trainDayTime

		model <- rxNeuralNet(
				formula=form, 
				data = data,         
				type            = "regression",
				netDefinition   = netDefinition,
				numIterations = 500,
				optimizer= optimiser,
				verbose         = 1);
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
		SELECT CURRENT_TIMESTAMP AS timest, model, 'NNRevenueFlat' AS name FROM #m;  
	DROP TABLE #m
	DROP TABLE IF EXISTS #TmpData;
END
GO
