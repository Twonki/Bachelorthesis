--=========================================================================================
-- Creates NN to estimate DropOff-Location
-- Only takes "good" Parameters which are predictable, such as time, locations and distance
--=========================================================================================
USE Taxi2Bachelor;
GO
-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================
DROP PROCEDURE IF EXISTS EvaluateDONN;
GO
CREATE PROCEDURE EvaluateDONN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		[RealDOLocation] smallint,
		[ID] uniqueidentifier PRIMARY KEY NOT NULL, 	
		[PredictedDOLocation] smallint
		)
	Insert into #Results 
	EXEC PredictDONN @ModelName=@ModelName;
	SELECT COUNT(*) as totalmisses FROM #Results WHERE RealDOLocation!=PredictedDOLocation;
	SELECT TOP(50) * FROM #Results;
	DROP TABLE IF EXISTS #Results;
END
GO