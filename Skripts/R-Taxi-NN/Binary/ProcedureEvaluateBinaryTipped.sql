--=========================================================================================
-- Creates NN to estimate Tip given 
-- Only takes "NN" Parameters which are predictable, such as time, locations and distance
--=========================================================================================
USE Taxi2Bachelor;
GO
-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================
DROP PROCEDURE IF EXISTS EvaluateBinaryTippedNN
GO
CREATE PROCEDURE EvaluateBinaryTippedNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		[real_tipped] smallint,
		[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
		[predicted_tip] smallint
	);
	Insert into #Results 
		Exec [PredictBinaryTippedNN] @Modelname = "NNBinaryTippedMedium";

	SELECT Count(*) as total_misses FROM #Results WHERE real_tipped != predicted_tip;
	SELECT TOP(10) * FROM #Results;
DROP TABLE IF EXISTS #Results;
END
GO