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

DROP PROCEDURE IF EXISTS [dbo].[TrainAmountNN];
GO
CREATE PROCEDURE [dbo].[TrainAmountNN] 
@TrainingSize BigInt	
AS
BEGIN
	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N') 
		tip_amount,trip_distance, total_amount,
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID
		from [dbo].[mlYellowData] 
		WHERE tip_amount>=0 AND tip_amount <50 AND 
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime)<180 AND 
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime)>=0 AND 
		trip_distance <100
		ORDER BY NEWID() ASC;')
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
			output Result [1] linear from Magic all;
		")
		
		dat_all <- InputData;
		sizeAll <- length(InputData$tip_amount);

		sample_train <- base::sample(nrow(dat_all), 
									 size = (sizeAll*0.9))

		sample_test  <- base::sample((1:nrow(dat_all))[-sample_train], 
									 size = (sizeAll*0.1))

		dat_train <- dat_all %>% 
		  slice(sample_train) 

		dat_test <- dat_all %>% 
		  slice(sample_test)
		form <- tip_amount ~total_amount+trip_distance+duration_in_minutes+passenger_count+PULocationID+DOLocationID;

		model <- rxNeuralNet(formula=form, data = dat_train,              
						   type            = "regression",
						   netDefinition   = netDefinition,
						   numIterations = 100,
						   normalize       = "yes",
						   verbose         = 0,
						   postTransformCache = "Disk");
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
	select CURRENT_TIMESTAMP as timest, model, 'NNtipModelMedium' as name from #m;  
	drop table #m
END

GO
EXEC TrainAmountNN @TrainingSize=100000;
GO

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
	set @inputCmd = N'Select TOP (1000) 
		NEWID() as id,
		tip_amount,trip_distance,total_amount,
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes,
		passenger_count,PULocationID,DOLocationID 
		from mlYellowData 
		ORDER BY NEWID() ASC;';
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
Exec [PredictTipAmountNN] @Modelname = "NNtipModelMedium";

SELECT sum(abs(real_tip_amount-predicted_tip_amount)) as miss_in_Dollar,sum(predicted_tip_amount) as predicted_total_tip, sum(real_tip_amount) as real_tip from #Results;
SELECT Top (100) abs(real_tip_amount-predicted_tip_amount) as miss_in_Dollar, predicted_tip_amount as estTip, real_tip_amount as realTip from #Results order by abs(real_tip_amount-predicted_tip_amount) desc;
GO
DROP TABLE IF EXISTS #Results;
GO