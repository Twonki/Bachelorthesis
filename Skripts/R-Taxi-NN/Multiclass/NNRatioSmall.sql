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
		passenger_count
		from YellowSample;')
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
			output Result auto softmax from Magic all;
		")
		
		dat_all <- InputData;
		
		dat_all$RatecodeID <- factor(dat_all$RatecodeID, levels=as.factor(c(1:6)) );
		#dat_all$RatecodeID <- as.factor(dat_all$RatecodeID);
		str(dat_all);
		#print(dat_all);
		#print(summary(dat_all));

		form <- RatecodeID ~ trip_distance+total_amount+duration_in_minutes+passenger_count

		model <- rxNeuralNet(
				formula = form, 
				#formula= Rate~.,
				data = dat_all, 
				netDefinition=netDefinition,            
				type            = "multiClass",
				numIterations = 100,
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
	select CURRENT_TIMESTAMP as timest, model, 'NNRatioModelMedium' as name from #m;  
	drop table #m
END

GO
EXEC TrainRatioNN @TrainingSize=1000;
GO

/*
-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictTipAmountNN]
GO
CREATE PROCEDURE [dbo].[PredictTipAmountNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		id,
		tip_amount,trip_distance,total_amount,
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes,
		passenger_count,PULocationID,DOLocationID 
		from yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   library("MicrosoftML")
	   print(summary(TestData));
       model_un <- unserialize(as.raw(nb_model)); 
	   print(summary(model_un));
	   new <- data.frame(TestData);
	   #score the model
	   prediction <- rxPredict(model= model_un, data = new, verbose = 1);
	   prediction <- round(prediction,2);
	   sum <- cbind(new, prediction);
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
	[real_tip_amount] float,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_tip_amount] float)) 
END
GO




-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[real_tip_amount] float,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_tip_amount] float
);
GO
Insert into #Results 
Exec [PredictTipAmountNN] @Modelname = "NNRatioModelMedium";

SELECT sum(abs(real_tip_amount-predicted_tip_amount)) as miss_in_Dollar,sum(predicted_tip_amount) as predicted_total_tip, sum(real_tip_amount) as real_tip from #Results;
SELECT Top (1000) abs(real_tip_amount-predicted_tip_amount) as miss_in_Dollar, predicted_tip_amount as estTip, real_tip_amount as realTip from #Results order by abs(real_tip_amount-predicted_tip_amount) desc;
GO
DROP TABLE IF EXISTS #Results;
GO
*/
