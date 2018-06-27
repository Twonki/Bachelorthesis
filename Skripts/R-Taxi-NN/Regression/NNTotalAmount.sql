--------------------------------
-- Creates a NN to predict total amount of the taxiride
--------------------------------
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
	SET NOCOUNT ON;

	declare @inputCmd nvarchar(max)
	set @inputCmd = CONCAT( N'Select Top(',@TrainingSize,N') 
		total_amount,RatecodeID,trip_distance, 
		DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes,
		WetBulbTemp,DryBulbTemp,RelativeHumidity,passenger_count,Windspeed,extra,
		mta_tax,PULocationID,DOLocationID,fare_amount 
		from [dbo].[yellowSample];')
	
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
		LocationLevels <- as.factor(c(1:255));	
		dat_all$PULocationID <- factor(dat_all$PULocationID, levels=LocationLevels);
		dat_all$DOLocationID <- factor(dat_all$DOLocationID, levels=LocationLevels);
		
		dat_all$RatecodeID <- factor(dat_all$RatecodeID, levels=(as.factor(c(1:5))));
		

		sizeAll <- length(InputData$total_amount);

		sample_train <- base::sample(nrow(dat_all), 
									 size = (sizeAll*0.9))
		sample_test  <- base::sample((1:nrow(dat_all))[-sample_train], 
									 size = (sizeAll*0.1))

		dat_train <- dat_all %>% 
		  slice(sample_train) 

		dat_test <- dat_all %>% 
		  slice(sample_test)
		form <- total_amount ~ RatecodeID+trip_distance+duration_in_minutes+WetBulbTemp+DryBulbTemp+RelativeHumidity+passenger_count+Windspeed+extra+mta_tax+PULocationID+DOLocationID+fare_amount;

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
	, @input_data_1 = @inputCmd 
	, @input_data_1_name=N'InputData'
	, @output_data_1_name = N'trained_model ';

	INSERT INTO Models (timest,model,model_name)
	SELECT CURRENT_TIMESTAMP AS timest, model, 'NNTotalAmount' AS name FROM #m;  
	DROP TABLE #m
END

GO
EXEC TrainAmountNN @TrainingSize = 10000;
GO

-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictAmountNN]
GO
CREATE PROCEDURE [dbo].[PredictAmountNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	-- Get the latest Model.
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);  
	-- Produce input to the RML script.
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (1000) NEWID() as id,total_amount,RatecodeID,trip_distance,DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes,WetBulbTemp,DryBulbTemp,RelativeHumidity,passenger_count,Windspeed,extra,mta_tax,PULocationID,DOLocationID,fare_amount from mlYellowData;';
	-- Prediction Script
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   library("MicrosoftML")
	   #print(summary(TestData));
       model_un <- unserialize(as.raw(nb_model)); 
	   #print(summary(model_un));
	   dat_all <- data.frame(TestData);
	   LocationLevels <- as.factor(c(1:255));	
		dat_all$PULocationID <- factor(dat_all$PULocationID, levels=LocationLevels);
		dat_all$DOLocationID <- factor(dat_all$DOLocationID, levels=LocationLevels);
		
		dat_all$RatecodeID <- factor(dat_all$RatecodeID, levels=(as.factor(c(1:5))));
		
	   #score the model
	   prediction <- rxPredict(model= model_un, data = dat_all, verbose = 0);
	   sum <- cbind(dat_all, prediction);
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
	[real_amount] float, 
	[RatecodeID] smallint,
	[trip_distance] float,
	[duration_in_minutes] float,
	[WetBulbTemp] real,
	[DryBulbTemp] real,
	[RelativeHumidity] smallint,
	[passenger_count] smallint,
	[Windspeed] smallint,
	[extra] real,
	[mta_tax] real,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[fare_amount] real, 
	[predicted_amount] float)) 
END
GO
Exec PredictAmountNN @Modelname = "NNTotalAmount";
GO


-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[real_amount] float, 
	[RatecodeID] smallint,
	[trip_distance] float,
	[duration_in_minutes] float,
	[WetBulbTemp] real,
	[DryBulbTemp] real,
	[RelativeHumidity] smallint,
	[passenger_count] smallint,
	[Windspeed] smallint,
	[extra] real,
	[mta_tax] real,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[fare_amount] real, 
	[predicted_amount] float
);
GO
Insert into #Results 
Exec PredictAmountNN @Modelname = "NNTotalAmount";


SELECT TOP(50) ID,(real_amount-predicted_amount) as miss_in_Dollar, (1-(real_amount/predicted_amount)) as accuracy, real_amount, predicted_amount FROM #Results;
SELECT avg(abs((1-(real_amount/predicted_amount)))) as avg_accuracy From #Results;
SELECT sum(abs(real_amount-predicted_amount)) as total_miss_in_Dollar, sum(real_amount) as total_real_amount, sum(predicted_amount) as total_predicted_amount FROM #Results;
GO
DROP TABLE IF EXISTS #Results;
GO
