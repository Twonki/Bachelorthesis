USE Taxi2Bachelor;
GO
-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================
DROP PROCEDURE IF EXISTS EvaluateRatioNN;
GO
CREATE PROCEDURE EvaluateRatioNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results (
		[RealRate] smallInt,
		[ID] uniqueidentifier, 
		[PredictedRate] smallint)
	Insert into #Results 
	Exec [PredictRatioNN] @Modelname = @ModelName;
	SELECT count(*) as totalMiss from #Results WHERE RealRate!=PredictedRate;
	SELECT Top(20) abs(RealRate-PredictedRate) as miss,RealRate, PredictedRate,ID from #Results;
	DROP TABLE IF EXISTS #Results;
END
GO