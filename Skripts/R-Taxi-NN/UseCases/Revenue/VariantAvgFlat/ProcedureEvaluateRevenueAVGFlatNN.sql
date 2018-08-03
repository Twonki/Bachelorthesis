--=========================================================================================
-- Procedure to Evaluate the Prediction of Revenue
-- A Temporary Resulttable is created and filled by PredictRevenueNN
-- Fitting Summarization is done on the Temporary Table and outputtet
-- Outputs:RSS,TSS, R^2, Miss in Total, Prediction in Total, Real in Total
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS EvaluateRevenueAVGFlatNN
GO
CREATE PROCEDURE EvaluateRevenueAVGFlatNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		trainRevenue FLOAT,
		trainDate DATE,
		trainLocation SMALLINT,
		trainDayTime SMALLINT,
		trainTempLevel SMALLINT, 
		[predictedRevenue] FLOAT
	);
	INSERT INTO #Results 
		EXEC [PredictRevenueAVGFlatNN] @Modelname = "NNRevenueAVGFlat";
	
	DECLARE @realMean float;
	SET @realMean = (SELECT AVG(trainRevenue) FROM #Results);

	SELECT
		(SUM(POWER(trainRevenue - @realMean,2))) AS RSS,
		(SUM(POWER((trainRevenue - predictedRevenue),2))) AS TSS,
		1- ((SUM(POWER((trainRevenue -  predictedRevenue),2)))/(SUM(POWER(trainRevenue - @realMean,2)))) as RQuadrat,
		sum(abs(trainRevenue- predictedRevenue)) as miss_in_total,
		sum( predictedRevenue) as  predicted_total_Placeholder, 
		sum(trainRevenue) as real_total_Placeholder,
		Count(*) as total_count
	FROM #Results;
	SELECT TOP 10 * FROM #Results;
	DROP TABLE IF EXISTS #Results;
END
GO