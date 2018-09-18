--------------------------------
-- Mein NN Gerüst!
--------------------------------
USE Taxi2Bachelor;
GO
-- =============================
-- Modell Datenbank
-- =============================
DROP TABLE IF Exists NNAmountModel
CREATE TABLE NNAmountModel(
	[id] [uniqueidentifier] NOT NULL,
	[model_name] [varchar](30) NOT NULL,
	[model] [varbinary](max) NOT NULL,
	[timest] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE NNAmountModel ADD  DEFAULT NEWID() FOR [id]
ALTER TABLE NNAmountModel ADD  DEFAULT ('default model') FOR [model_name]
GO


-- =============================================
-- Geklaut aus NN3 (Siehe R-Learning)
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[TrainAmountNN];
GO
CREATE PROCEDURE [dbo].[TrainAmountNN] 
	
AS
BEGIN

	SET NOCOUNT ON;
	-- Construct the RML script.
	declare @cmd nvarchar(max)
	set @cmd = N'
library(MicrosoftML)
library(dplyr)

set.seed(123)
dataParms <- list(
  training_rows = 99000,
  test_rows     = 1000
)

hyperParms <- list(
  augmentation = "none",
  netDefSummary = "All Input ->  Output",
  numIterations = 250,
  miniBatchSize = 1,
  acceleration = "sse"
)

optimParms <- list(
  optimizer = "sgd",
  learningRate = 0.05,
  lRateRedRatio = 0.98,
  lRateRedFreq = 5,
  momentum = 0.2,
  decay = 0.96,
  conditioningConst = 1e-6
)

# Read csv with Labels info.
dat_all <- InputData
str(dat_all);
sample_train <- base::sample(nrow(dat_all), 
                             size = dataParms$training_rows)
sample_test  <- base::sample((1:nrow(dat_all))[-sample_train], 
                             size = dataParms$test_rows)

dat_train <- dat_all %>% 
  slice(sample_train) 

  #str(dat_train);
dat_test <- dat_all %>% 
  slice(sample_test)
 # str(dat_test);


# my own netDefinition, if Result Number =1 Regression
# Try this later with more than 1 Hidden layer
netDefinition <- ("
	input Data auto;
	output Result [1] from Data all;
")


optimiser <- with(optimParms, sgd(learningRate  = learningRate,
                                  lRateRedRatio = lRateRedRatio,
                                  lRateRedFreq  = lRateRedFreq,
                                  momentum      = momentum))

form <- total_amount ~ RatecodeID+trip_type+trip_distance+duration_in_minutes+WetBulbTemp+DryBulbTemp+RelativeHumidity+passenger_count+Windspeed+extra+mta_tax+PULocationID+DOLocationID+fare_amount;

model <- rxNeuralNet(formula=form, data = dat_train,
                   type            = "regression",
                   netDefinition = netDefinition, 
                   optimizer     = optimiser,
                   acceleration  = hyperParms$acceleration,
                   miniBatchSize = hyperParms$miniBatchSize,
                   numIterations = hyperParms$numIterations,
                   normalize       = "auto",
                   initWtsDiameter = 0.1,
                   verbose         = 1,
                   postTransformCache = "Disk");
summary(model);
trained_model <- data.frame(payload = as.raw(serialize(model, connection=NULL)));
	'
	create table #m (model varbinary(max));
	insert into #m
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @cmd
	, @input_data_1 = N'Select Top(100000) total_amount,RatecodeID,trip_type,trip_distance, DATEDIFF(MINUTE,pickup_datetime,dropoff_datetime) as duration_in_minutes ,WetBulbTemp,DryBulbTemp,RelativeHumidity,passenger_count,Windspeed,extra,mta_tax,PULocationID,DOLocationID,fare_amount from mlGreenData order by NEWID() ASC;' 
    , @input_data_1_name=N'InputData'
	, @output_data_1_name = N'trained_model ';

	
	--insert into [dbo].GalaxiesModels(CreationDate, Model, [Name]) 
	insert into NNAmountModel (timest,model,model_name)
	select CURRENT_TIMESTAMP as timest, model, 'prod' as name from #m;  

	drop table #m
END

GO
EXEC TrainAmountNN;
GO

-- =============================================
-- Stolen From NN1
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictAmountNN]
GO
CREATE PROCEDURE [dbo].[PredictAmountNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	-- Get the latest Model.
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM NNAmountModel WHERE [model_name] = @ModelName ORDER BY timest DESC);  

	-- Produce input to the RML script.
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'select * from greenBigAmountTest';

	-- Prediction Script
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   library("MicrosoftML")
       model_un <- unserialize(as.raw(nb_model)); 
	   summary(model_un);
	   new <- data.frame(greenBigAmountTest);
	   #score the model
	   prediction <- rxPredict(model= model_un, data = new, verbose = 1)
	   str(prediction);
	   sum <- cbind(new, prediction);
	   #str(sum);
	   OutputDataSet <- data.frame(sum)
	   '
	  -- Execute the RML script (train & score).
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	,@input_data_1 = N'Select id,real_total_amount as total_amount,RatecodeID,trip_type,trip_distance,duration_in_minutes,WetBulbTemp,DryBulbTemp,RelativeHumidity,passenger_count,Windspeed,extra,mta_tax,PULocationID,DOLocationID,fare_amount from greenBigAmountTest;'
	, @input_data_1_name = N'greenBigAmountTest'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
	WITH RESULT SETS ((
	[ID] uniqueidentifier, 
	[real_amount] float, 
	[RatecodeID] smallint,
	[trip_type] smallint,
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
Exec PredictAmountNN @Modelname = "prod";
GO

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[real_amount] float, 
	[RatecodeID] smallint,
	[trip_type] smallint,
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
Exec PredictAmountNN @Modelname = "prod";


---------------------------
-- Show me the Test Results
---------------------------

SELECT TOP(50) ID,(real_amount-predicted_amount) as miss_in_Dollar, (1-(real_amount/predicted_amount)) as accuracy, real_amount, predicted_amount FROM #Results;
SELECT avg(abs((1-(real_amount/predicted_amount)))) as avg_accuracy From #Results;
SELECT sum(abs(real_amount-predicted_amount)) as total_miss_in_Dollar, sum(real_amount) as total_real_amount, sum(predicted_amount) as total_predicted_amount FROM #Results;
GO
DROP TABLE IF EXISTS #Results;
GO