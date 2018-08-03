--=========================================================================================
-- Procedure to Evaluate the Prediction of Rides
-- A Temporary Resulttable is created and filled by PredictRidesNN
-- Fitting Summarization is done on the Temporary Table and outputtet
-- Outputs:RSS,TSS, R^2, Miss in Total, Prediction in Total, Real in Total
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS EvaluateRidesNN
GO
CREATE PROCEDURE EvaluateRidesNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		trainRides INT,
		trainDate DATE,
		trainLocation SMALLINT,
		trainDayTime SMALLINT,
		trainTempLevel SMALLINT, 
		[predictedRides] FLOAT
	);
	INSERT INTO #Results 
		EXEC [PredictRidesNN] @Modelname = "NNRides";
	
	DECLARE @realMean float;
	SET @realMean = (SELECT AVG(trainRides) FROM #Results);

	SELECT
		(SUM(POWER(trainRides - @realMean,2))) AS RSS,
		(SUM(POWER((trainRides - predictedRides),2))) AS TSS,
		1- ((SUM(POWER((trainRides -  predictedRides),2)))/(SUM(POWER(trainRides - @realMean,2)))) as RQuadrat,
		sum(abs(trainRides- predictedRides)) as miss_in_total,
		sum( predictedRides) as  predicted_total_Placeholder, 
		sum(trainRides) as real_total_Placeholder,
		Count(*) as total_count
	FROM #Results;
	SELECT TOP 10 * FROM #Results;
	DROP TABLE IF EXISTS #Results;
END
GO