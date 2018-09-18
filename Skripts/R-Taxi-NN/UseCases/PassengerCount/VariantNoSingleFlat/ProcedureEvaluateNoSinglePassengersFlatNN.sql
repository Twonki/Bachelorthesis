--=========================================================================================
-- Procedure to Evaluate the Prediction
-- This is for UseCase Passengers #3 Issue 24
-- A Temporary Resulttable is created and filled by PredictPassengers
-- Fitting Summarization is done on the Temporary Table and outputtet
-- Outputs: Total Hits and Total Misses
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS EvaluateNoSinglePassengersFlatNN
GO
CREATE PROCEDURE EvaluateNoSinglePassengersFlatNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		[real_Passengers] smallint,
		[PULocationID] smallint, 
		[Date] date,
		[Hour] smallint,
		[Rate] smallint,
		[predicted_Passengers] smallint
	);
	INSERT INTO #Results 
		EXEC [PredictNoSinglePassengersFlatNN] @Modelname = "NNNoSinglePassengersFlat";
	DECLARE @Total bigint;
	SET @Total = (SELECT Count(*) FROM #Results);

	SELECT Count(*) AS total_misses, @Total as total_results,1-(Count(*)/CONVERT(float,@Total)) as accuracy  FROM #Results WHERE [real_Passengers] != [predicted_Passengers];
	SELECT TOP(10) * FROM #Results;
	--Lookup for R^2 in RegressionModels

	--==============================
	-- Plot here?
	--==============================

	DROP TABLE IF EXISTS #Results;
END
GO