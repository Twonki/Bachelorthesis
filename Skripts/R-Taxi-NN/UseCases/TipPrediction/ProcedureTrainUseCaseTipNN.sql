--=========================================================================================
-- Creates NN to estimate the Tip Given
-- This is Usecase #1 
-- Input: PassengerCount, PULocation, Distance, TipAmount
-- Output: Model for TipPrediction
--=========================================================================================
USE Taxi2Bachelor;
GO

DROP PROCEDURE IF EXISTS [dbo].[TrainTipNN];
GO
CREATE PROCEDURE [dbo].[TrainTipNN] 
@TrainingSize BigInt	
AS
BEGIN
	--=====================
	-- Inputselection and Skript as Strings
	--=====================
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N')
		trip_distance as distance,
		PULocationID,
		passenger_count as passengers,
		tip_amount
		FROM mlYellowData
		ORDER BY NEWID() DESC;')
	SET NOCOUNT ON;
	-- Construct the RML script.
	declare @cmd nvarchar(max)
	set @cmd = N'
		library(MicrosoftML)
		library(dplyr)

		#Netz definieren
		netDefinition <- ("
			input Data auto;
			hidden Mystery [50] sigmoid from Data all;
			hidden Magic [50] sigmoid from Mystery all;
			output Result auto from Magic all;
		")
		
		data <- InputData;
		
		# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		
		#Formel
		form <-  tip_amount~distance+PULocationID+passengers
		model <- rxNeuralNet(
				formula=form, 
				data = data,         
				type            = "regression",
				netDefinition   = netDefinition,
				numIterations = 250,
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
		SELECT CURRENT_TIMESTAMP AS timest, model, 'NNTip' AS name FROM #m;  
	DROP TABLE #m
END
GO

