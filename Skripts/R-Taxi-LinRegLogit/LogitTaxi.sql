-----------------------------------------------------------
-- My First Attempts for R with Taxi Data 
-- Goal: Estimate whether a tip will be given (yes or no, no amount)
-- Does not Include Testing (Different file)
-----------------------------------------------------------

Use Taxi2Bachelor
GO

DROP TABLE IF EXISTS #TipSample
CREATE TABLE #TipSample (
	tipped BIT,
	total_amount float,
	rate smallint,
	duration int,
	trip_distance float,
	PULocationID smallint,
	DOLocationID smallint
)
GO
INSERT INTO #TipSample
	SELECT 
		CONVERT(BIT,tip_amount),
		total_amount ,
		RatecodeID ,
		duration_in_minutes ,
		trip_distance,
		PULocationID ,
		DOLocationID 
	FROM yellowSample;

DROP TABLE IF EXISTS #TipTest
CREATE TABLE #TipTest (
	id uniqueidentifier,
	tipped BIT,
	total_amount float,
	rate smallint,
	duration int,
	trip_distance float,
	PULocationID smallint,
	DOLocationID smallint
)
GO
INSERT INTO #TipTest
	SELECT
		id,
		CONVERT(BIT,tip_amount),
		total_amount ,
		RatecodeID ,
		duration_in_minutes ,
		trip_distance,
		PULocationID ,
		DOLocationID 
	FROM yellowTest;

DROP PROCEDURE IF EXISTS generate_logit_model;
GO
CREATE PROCEDURE generate_logit_model
AS
BEGIN
	CREATE TABLE #m (model varbinary(max));
	INSERT INTO #m
    EXEC sp_execute_external_script
    @language = N'R'
    , @script =N'
		form <- tipped ~ duration+total_amount+rate+trip_distance+PULocationID+DOLocationID;
		logitmodel <- rxLogit(formula = form, data = TaxiData) ; 
        trained_model <- data.frame(payload = as.raw(serialize(logitmodel, connection=NULL)));
		'
    , @input_data_1 = N'Select tipped,duration,total_amount,rate,trip_distance,PULocationID,DOLocationID from #TipSample;' 
    , @input_data_1_name = N'TaxiData' 
    , @output_data_1_name = N'trained_model';
	
	INSERT INTO Models (timest,model,model_name)
	SELECT CURRENT_TIMESTAMP AS timest, model, 'LogitTippedMedium' AS name FROM #m;  
	DROP TABLE #m
END;
GO
EXEC generate_logit_model;

--000000000000000000000

DROP PROCEDURE IF EXISTS [dbo].[PredictTippedLogit]
GO
CREATE PROCEDURE [dbo].[PredictTippedLogit]
@ModelName nvarchar(50)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @dbModel varbinary(max) = (SELECT TOP (1) Model FROM Models WHERE [model_name] = @ModelName ORDER BY timest DESC);
	declare @inputCmd nvarchar(max)
	set @inputCmd = N'Select TOP (10000) 
		id,
		tipped,
		total_amount,
		rate,
		duration,
		trip_distance,
		PULocationID,
		DOLocationID 
		from #TipTest;';
	DECLARE @predictScript nvarchar(max);
	set @predictScript = N'
	   current_model <- unserialize(as.raw(nb_model));
            new <- data.frame(TestData); 
            predicted.amount <- round(rxPredict(current_model, new),2);
            OutputDataSet <- cbind(new, predicted.amount); 
		'
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @predictScript
	, @input_data_1 = @inputCmd
	, @input_data_1_name = N'TestData'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @dbModel
WITH RESULT SETS ((
	[id] UNIQUEIDENTIFIER,
	[real_tipped] BIT,
	[total_amount] FLOAT,
	[rate] SMALLINT,
	[duration] INT,
	[trip_distance] FLOAT,
	[PULocationID] SMALLINT,
	[DOLocationID] SMALLINT,
	[predicted_tipped_chance] FLOAT)) 
	END
GO
--EXEC PredictTippedLogit @ModelName="LogitTippedMedium";

DROP TABLE IF EXISTS #Results;
CREATE TABLE #Results (
	[id] UNIQUEIDENTIFIER,
	[real_tipped] BIT,
	[total_amount] FLOAT,
	[rate] SMALLINT,
	[duration] INT,
	[trip_distance] FLOAT,
	[PULocationID] SMALLINT,
	[DOLocationID] SMALLINT,
	[predicted_tipped_chance] FLOAT
)
GO
INSERT INTO #Results
EXEC PredictTippedLogit @ModelName="LogitTippedMedium";
GO
SELECT real_tipped, round(predicted_tipped_chance,0) as est_tipped, predicted_tipped_chance from #Results;


SELECT sum(abs((real_tipped - round(predicted_tipped_chance,0)))) as misses  from #Results;
GO
DROP TABLE IF EXISTS #Results;
DROP TABLE IF EXISTS #TipSample;
DROP TABLE IF EXISTS #TipTest;
GO