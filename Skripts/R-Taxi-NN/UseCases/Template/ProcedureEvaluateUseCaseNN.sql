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

	SELECT Count(*) AS total_misses FROM #Results WHERE real_Placeholder != predicted_Placeholder;
	SELECT TOP(10) * FROM #Results;
	--Lookup for R^2 in RegressionModels

	--==============================
	-- Plot here?
	--==============================

	DROP TABLE IF EXISTS #Results;
END
GO