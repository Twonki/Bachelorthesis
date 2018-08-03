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

DROP PROCEDURE IF EXISTS [dbo].[TrainRevenueNN];
GO
CREATE PROCEDURE [dbo].[TrainRevenueNN] 
@TrainingSize BigInt	
AS
BEGIN
	DROP TABLE IF EXISTS #TmpData;

	CREATE TABLE #TmpData (
		trainRevenue FLOAT,
		fahrten int,
		trainDate DATE,
		trainLocation SMALLINT,
		trainDayTime SMALLINT,
		trainTempLevel SMALLINT
	);

	INSERT INTO #TmpData
		Select 
			SUM(total_amount)as trainRevenue
			,Count(total_amount) as Fahrten 
			,Convert(Date, pickup_datetime) as trainDate
			,PULocationID as trainLocation
			,DatePart(HOUR, pickup_datetime) as trainDayTime
			--,AVG(RelativeHumidity) as Humidity
			,CONVERT(SMALLINT,AVG(DryBulbTemp)/10) as trainTempLevel
		--from mlYellowData 
		from yellowSample
		group by
			PULocationID
			,Convert(DATE,pickup_datetime)
			,DATEPART(HOUR,pickup_datetime)
		Having Count(total_amount)>2
	;
	--SELECT * FROM #TmpData;

	--Select SUM(total_amount)as trainRevenue 
	--		,Convert(Date, pickup_datetime) as trainDate
	--		,PULocationID as trainLocation
	--		--,DatePart(HOUR, pickup_datetime) as trainDayTime
	--		--,AVG(RelativeHumidity) as Humidity
	--		,CONVERT(SMALLINT,AVG(DryBulbTemp)/10) as trainTempLevel
	--	--from mlYellowData 
	--	from yellowSample
	--	group by
	--	Convert(DATE,pickup_datetime)
	--		,PULocationID
	--		,DATEPART(HOUR,pickup_datetime)
	--=====================
	-- Inputselection and Skript as Strings
	--=====================
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N')
		trainRevenue, 
		trainDate,
		trainLocation,
		trainDayTime,
		trainTempLevel
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
			hidden Mystery [50] sigmoid from Data all;
			hidden Magic [50] sigmoid from Mystery all;
			output Result auto from Magic all;
		")
		
		data <- InputData;
		
		# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));	
		data$trainLocation <- factor(data$trainLocation, levels=LocationLevels);
		data$trainTempLevel <- as.factor(data$trainTempLevel);
		data$trainDayTime <- as.factor(data$trainDayTime);
		#data$RainFlag <- as.factor(data$RainFlag);

		data$trainDate <- as.factor(data$trainDate);

		str(data);
		print(summary(data));

		#Optimiser
		optimParms <- list(
		  optimizer = "sgd",
		  learningRate = 0.15,
		  lRateRedRatio = 0.97,
		  lRateRedFreq = 10,
		  momentum = 0.3,
		  decay = 0.95
		);

		optimiser <- with(optimParms, sgd(learningRate  = learningRate,lRateRedRatio = lRateRedRatio,lRateRedFreq  = lRateRedFreq,momentum      = momentum));

		#Formel
		form <-  trainRevenue ~ trainDate+trainTempLevel+trainLocation+trainDayTime

		model <- rxNeuralNet(
				formula=form, 
				data = data,         
				type            = "regression",
				netDefinition   = netDefinition,
				numIterations = 50,
				norm="no",
				optimizer= optimiser,
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
		SELECT CURRENT_TIMESTAMP AS timest, model, 'NNRevenue' AS name FROM #m;  
	DROP TABLE #m
	DROP TABLE IF EXISTS #TmpData;
END
GO

GO