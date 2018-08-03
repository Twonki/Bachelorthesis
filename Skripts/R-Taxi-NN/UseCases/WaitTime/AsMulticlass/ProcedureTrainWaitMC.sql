--=========================================================================================
-- Creates NN to estimate Tip given 
-- Only takes "good" Parameters which are predictable, such as time, locations and distance
--=========================================================================================
USE Taxi2Bachelor;
GO

-- =============================================
-- Create Procedure to Create and Train NN
-- Takes Trainingsize as Parameter
-- Safes a model with timestamp in ModelTable
-- =============================================	 
DROP PROCEDURE IF EXISTS [dbo].[TrainWaitMCNN];
GO
CREATE PROCEDURE [dbo].[TrainWaitMCNN] 
@TrainingSize BigInt	
AS
BEGIN
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
		AND DATEDIFF(MINUTE,pickup_datetime,dropOff_datetime)<=20
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
			hidden Magic [50] sigmoid from Mystery all;
			output Result auto from Magic all;
		")
		
		data <- InputData;
		
		# Werte als Faktoren aufbereiten
		LocationLevels <- as.factor(c(1:255));
		data$Duration <- factor(data$Duration, levels=(as.factor(c(1:20))))
		data$Location <- factor(data$Location, levels=LocationLevels);
		data$Month<- factor(data$Month, levels=(as.factor(c(1:12))));
		data$DayTime<- factor(data$DayTime, levels=(as.factor(c(0:23))));

		#Formel
		form <-  Duration ~ Location+Month+DayTime+TempLevel
		model <- rxNeuralNet(
				formula=form, 
				data = data,         
				type            = "multiClass",
				netDefinition   = netDefinition,
				numIterations = 50,
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
		select CURRENT_TIMESTAMP as timest, model, 'NNWaitMC' as name from #m;  
	drop table #m
END