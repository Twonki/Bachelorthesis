--=========================================================================================
-- Procedure to Evaluate the Prediction
-- A Temporary Resulttable is created and filled by PredictUseCaseXXX
-- Fitting Summarization is done on the Temporary Table and outputtet
-- Outputs: A B C 
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS EvaluateUseCaseNN
GO
CREATE PROCEDURE EvaluateUseCaseNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		[real_Placeholder] smallint,
		[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
		[predicted_Placeholder] smallint
	);
	INSERT INTO #Results 
		EXEC [PredictUseCaseNN] @Modelname = "NNUseCase";
	
	--=========================================================
	-- For Classification:
	DECLARE @Total bigint;
	SET @Total = (SELECT Count(*) FROM #Results);

	SELECT Count(*) AS total_misses, @Total as total_results,(1-Count(*)/CONVERT(float,@Total)) as accuracy  FROM #Results WHERE [real_Placeholder] != [predicted_Placeholder];
	SELECT TOP(10) * FROM #Results;

	--=========================================================
	-- For Regression
	DECLARE @realMean float;
	SET @realMean = (SELECT AVG(real_Placeholder) FROM #Results);

	SELECT
		(SUM(POWER(real_Placeholder - @realMean,2))) AS RSS,
		(SUM(POWER((real_Placeholder - predicted_Placeholder),2))) AS TSS,
		1- ((SUM(POWER((real_Placeholder -  predicted_Placeholder),2)))/(SUM(POWER(real_Placeholder - @realMean,2)))) as RQuadrat,
		sum(abs(real_Placeholder- predicted_Placeholder)) as miss_in_total,
		sum( predicted_Placeholder) as  predicted_total_Placeholder, 
		sum(real_Placeholder) as real_total_Placeholder
	FROM #Results;
	SELECT TOP 10 * FROM #Results;
	--==============================
	-- Plot here?
	--==============================

	DROP TABLE IF EXISTS #Results;
END
GO