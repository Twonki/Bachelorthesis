-- Test for some other Code
execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
	library(MicrosoftML);
	r <- 10000;
	c <- 10;
	normData <- data.frame(matrix(rnorm(r*c,0,1),r,c)) 
	#print(summary(normData));
	label = sample(c(0, 1), r, replace = T)
	#print(summary(label));
	normData = cbind(normData, label=as.factor(label))
	#print(summary(normData));
	str(normData);
	#model=rxNeuralNet(formula=label~., data = normData, type = "binary")
	'
	 
USE Taxi2Bachelor
GO

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
GO

DROP PROCEDURE IF EXISTS [dbo].[TestBinary];
GO
CREATE PROCEDURE [dbo].[TestBinary]
AS
BEGIN
	declare @inputcmd nvarchar(max)
	set @inputcmd = N'Select
		tipped, 
		Rate, 
		trip_distance, 
		total_amount,
		duration_in_minutes,
		passenger_count,
		PULocationID,
		DOLocationID
		from #TmpData;'
	SET NOCOUNT ON;
	declare @cmd nvarchar(max)
	set @cmd = N'
		library(MicrosoftML);
		df <- InputData;
		str(df);
		df$tipped <- as.factor(df$tipped);
		df$Rate <- as.factor(df$Rate);
		df$PULocationID <-as.factor(df$PULocationID);
		df$DOLocationID <-as.factor(df$DOLocationID);
		str(df);
		model=rxNeuralNet(formula=tipped~., data = df, type = "binary", numIterations=100)
	'

	--create table #m (model varbinary(max));
	--insert into #m
	execute sp_execute_external_script
	  @language = N'R'
	, @script = @cmd
	, @input_data_1 = @inputcmd 
    , @input_data_1_name=N'InputData'
	, @output_data_1_name = N'trained_model ';
	 
	--insert into Models (timest,model,model_name)
	--select CURRENT_TIMESTAMP as timest, model, 'NNBinaryTippedMedium' as name from #m;  
	--drop table #m
END

GO
EXEC TestBinary;
GO


DROP TABLE #TmpData