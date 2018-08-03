--=========================================================================================
-- Creates NN to estimate The PassengerCount in Given Area at given Time/Date
-- This is Usecase Passengers #3 Issue 24
-- Input: PassengerCount, PULocationID, pickup_time split in date and hour, Rate
-- Additional Filters: Passengers<10
-- Output: Multiclass Model for Passengercount Prediction
-- Model is instantly stored in Model Table
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS [dbo].[TrainPassengersNN];
GO
CREATE PROCEDURE [dbo].[TrainPassengersNN] 
@TrainingSize BigInt	
AS
BEGIN
	--=====================
	-- Inputselection and Skript as Strings
	--=====================
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N')
		passenger_count as PCount, 
		PULocationID,
		CONVERT(DATE,pickup_datetime) as Date,
		DATEPART(HOUR,pickup_datetime) as Hour,
		RatecodeID as Rate
		FROM [yellowSample]
		WHERE passenger_count<10')
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
		data$PCount <- factor(data$PCount, levels=(as.factor(c(1:10))));	

		LocationLevels <- as.factor(c(1:255));
		
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$Hour<- factor(data$Hour, levels=(as.factor(c(0:23))));
		data$Date <- as.factor(data$Date);
		#data$Date <- factor(data$Date, level=(as.factor(c(0:364))));

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
		form <-  PCount ~ PULocationID+Hour+Date+Rate;
		model <- rxNeuralNet(
				formula=form, 
				data = data, 
				optimizer=optimiser,        
				type            = "multiClass",
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
		SELECT CURRENT_TIMESTAMP AS timest, model, 'NNPassengers' AS name FROM #m;  
	DROP TABLE #m
	DROP TABLE IF EXISTS #TmpData;
END
GO

