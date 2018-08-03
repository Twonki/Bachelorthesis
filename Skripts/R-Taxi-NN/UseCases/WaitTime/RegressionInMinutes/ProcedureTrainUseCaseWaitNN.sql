--=========================================================================================
-- Creates NN to estimate WaitTime
-- This is Usecase #2
-- Input: A B C
-- Output: D E F
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS [dbo].[TrainWaitNN];
GO
CREATE PROCEDURE [dbo].[TrainWaitNN] 
@TrainingSize BigInt	
AS
BEGIN
	--=====================
	-- Inputselection and Skript as Strings
	--=====================
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N')
		DATEDIFF(MINUTE,pickup_datetime,dropOff_datetime) as Duration, 
		DATEPART(MONTH,pickup_datetime) as Month,
		DATEPART(HOUR,pickup_datetime) as DayTime,
		ROUND((WetBulbTemp/10),0) as TempLevel,
		PULocationID as Location
		FROM mlYellowData
		WHERE PULocationID=DOLocationID
		AND trip_distance=0
		AND DATEDIFF(MINUTE,pickup_datetime,dropOff_datetime)>0
		ORDER BY NEWID();')
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
			hidden Magic [50] tanh from Mystery all;
			output Result auto from Magic all;
		")
		
		data <- InputData;
		
		# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));	
		data$Location <- factor(data$Location, levels=LocationLevels);
		
		data$Month<- factor(data$Month, levels=(as.factor(c(1:12))));
		data$DayTime<- factor(data$DayTime, levels=(as.factor(c(0:23))));

		#Formel
		form <-  Duration ~ Location+Month+DayTime+TempLevel
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
		SELECT CURRENT_TIMESTAMP AS timest, model, 'NNWait' AS name FROM #m;  
	DROP TABLE #m
END
GO

