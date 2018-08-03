--=========================================================================================
-- Procedure to Evaluate the Prediction
-- A Temporary Resulttable is created and filled by PredictUseCaseWaitSeconds (#2)
-- Fitting Summarization is done on the Temporary Table and outputtet
-- Outputs: A B C 
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS EvaluateUseCaseWaitSecondsNN
GO
CREATE PROCEDURE EvaluateUseCaseWaitSecondsNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		[real_Duration] Integer,
		[Month] smallint,
		[DayTime] smallint,
		[TempLevel] smallint,
		[Location] smallint, 
		[predicted_Duration] integer
	);
	INSERT INTO #Results 
		EXEC [PredictUseCaseWaitSecondsNN] @Modelname = "NNWaitSeconds";

	SELECT TOP(10) * FROM #Results;
	--Lookup for R^2 in RegressionModels
	DECLARE @realMean float;
	SET @realMean = (SELECT AVG(real_Duration) FROM #Results);

	SELECT
		(SUM(POWER(real_Duration - @realMean,2))) AS RSS,
		(SUM(POWER((real_Duration - predicted_Duration),2))) AS TSS,
		1- ((SUM(POWER((real_Duration - predicted_Duration),2)))/(SUM(POWER(real_Duration - @realMean,2)))) as RQuadrat,
		sum(abs(real_Duration-predicted_Duration)) as miss_in_Minutes,
		sum(predicted_Duration) as predicted_total_Duration, 
		sum(real_Duration) as real_total_Duration
	FROM #Results;
	--==============================
	-- Plot here?
	--==============================

	DROP TABLE IF EXISTS #Results;
END
GO