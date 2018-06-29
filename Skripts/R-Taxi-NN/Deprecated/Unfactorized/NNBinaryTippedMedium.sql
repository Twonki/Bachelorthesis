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

DROP PROCEDURE IF EXISTS [dbo].[TrainTippedNN];
GO
CREATE PROCEDURE [dbo].[TrainTippedNN] 
@TrainingSize BigInt	
AS
BEGIN
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
		from #TmpData;')
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
		
		dat_all <- InputData;
		str(dat_all);

		dat_all$tipped <- as.factor(dat_all$tipped);
		dat_all$PULocationID <- as.factor(dat_all$PULocationID);
		dat_all$DOLocationID <- as.factor(dat_all$DOLocationID);
		dat_all$Rate <- as.factor(dat_all$Rate);
		
		str(dat_all);

		sizeAll <- length(InputData$total_amount);

		sample_train <- base::sample(nrow(dat_all), 
									 size = (sizeAll*0.9))

		sample_test  <- base::sample((1:nrow(dat_all))[-sample_train], 
									 size = (sizeAll*0.1))

		dat_train <- dat_all %>% 
		  slice(sample_train) 

		dat_test <- dat_all %>% 
		  slice(sample_test)


		#form <-  isTipped ~ Rate+trip_distance+total_amount+duration_in_minutes+passenger_count+PULocationID+DOLocationID;
		#form <-  tipped ~ Rate+trip_distance+total_amount+duration_in_minutes+passenger_count+PULocationID+DOLocationID;
		
		model <- rxNeuralNet(
				formula=tipped~., 
				data = dat_train,
				#transforms = list(isTipped = tipped==1),             
				type            = "binary",
				netDefinition   = netDefinition,
				numIterations = 100,
				# normalize       = "yes",
				verbose         = 1);

		prediction <- rxPredict(model= model, data = dat_test, verbose = 1);
		#print(prediction);
		
		sum <- cbind(prediction,dat_train$tipped);
		print(sum);
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
	select CURRENT_TIMESTAMP as timest, model, 'NNBinaryTippedMedium' as name from #m;  
	drop table #m
END

GO
EXEC TrainTippedNN @TrainingSize=1000000;
GO

/*
-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictBinaryTippedNN]
GO
CREATE PROCEDURE [dbo].[PredictBinaryTippedNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		id,
		CONVERT(BIT,tip_amount) as tipped,
		RatecodeID as Rate,
		trip_distance,
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID 
		from yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   library("MicrosoftML")
	   print(summary(TestData));
       model_un <- unserialize(as.raw(nb_model)); 
	   print(summary(model_un));
	   new <- data.frame(TestData);
	   new$tipped <- as.factor(new$tipped);
	   new$PULocationID <- as.factor(new$PULocationID);
	   new$DOLocationID <- as.factor(new$DOLocationID);
	   new$Rate <- as.factor(new$Rate);
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
	[real_tipped] bit,
	[rate] smallint,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_tipped] bit)) 
END
GO




-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
	[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[real_tipped] BIT,
	[Rate] smallint,
	[trip_distance] float,
	[total_amount] float,
	[duration] int,
	[passenger_count] smallint,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[predicted_tip_chance] float
);
GO
Insert into #Results 
Exec [PredictBinaryTippedNN] @Modelname = "NNBinaryTippedMedium";

SELECT * FROM #Results;

--SELECT sum(abs(real_tip_amount-predicted_tip_amount)) as miss_in_Dollar,sum(predicted_tip_amount) as predicted_total_tip, sum(real_tip_amount) as real_tip from #Results;
--SELECT Top (1000) abs(real_tip_amount-predicted_tip_amount) as miss_in_Dollar, predicted_tip_amount as estTip, real_tip_amount as realTip from #Results order by abs(real_tip_amount-predicted_tip_amount) desc;
GO
DROP TABLE IF EXISTS #Results;
GO

*/
DROP TABLE #TmpData;

