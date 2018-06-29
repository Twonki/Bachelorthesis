--=========================================================================================
-- Creates NN to estimate DropOff-Location
-- Only takes "good" Parameters which are predictable, such as time, locations and distance
--=========================================================================================
USE Taxi2Bachelor;
GO
-- =============================================
-- Procedure to use the NN
-- =============================================
DROP PROCEDURE IF EXISTS [dbo].PredictDONN
GO
CREATE PROCEDURE [dbo].PredictDONN
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		id,
		RatecodeID, 
		trip_distance, 
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID 
		from yellowTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
		library("MicrosoftML");
		model_un <- unserialize(as.raw(nb_model)); 
		data <- data.frame(TestData); 
		LocationLevels <- as.factor(c(1:265));	
		data$PULocationID <- factor(data$PULocationID, levels=LocationLevels);
		data$DOLocationID <- factor(data$DOLocationID, levels=LocationLevels);
		
		data$RatecodeID <- factor(data$RatecodeID, levels=as.factor(c(1:6)) );
		prediction <- rxPredict(model= model_un, data = data, verbose = 0);

		sum <- cbind(data$DOLocationID,levels(data$id), prediction$PredictedLabel);
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
	[RealDOLocation] smallint,
	[ID] uniqueidentifier, 
	[PredictedDOLocation] smallint)) 
END
GO