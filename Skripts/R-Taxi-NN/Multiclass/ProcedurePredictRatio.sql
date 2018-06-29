USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].[PredictRatioNN]
GO
CREATE PROCEDURE [dbo].[PredictRatioNN]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		ID as uID,
		RatecodeID, 
		trip_distance, 
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID,
		extra,
		mta_tax,
		fare_amount
		from yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
		library("MicrosoftML")
		model_un <- unserialize(as.raw(nb_model)); 
		mydata <- data.frame(TestData);
		str(mydata);
		LocationLevels <- as.factor(c(1:265));	
		mydata$PULocationID <- factor(mydata$PULocationID, levels=LocationLevels);
		mydata$DOLocationID <- factor(mydata$DOLocationID, levels=LocationLevels);
		mydata$RatecodeID <- factor(mydata$RatecodeID, levels=as.factor(c(1:6)) );
		
		prediction <- rxPredict(model= model_un, data = mydata, verbose = 1);
		sum <- cbind(mydata$RatecodeID, levels(mydata$uID), prediction$PredictedLabel);
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
	[RealLabel] smallInt,
	[ID] uniqueidentifier, 
	[PredictedLabel] smallint)) 
END
GO
