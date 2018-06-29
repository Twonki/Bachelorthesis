--=============================================
-- Mein NN Gerüst für Taschengeld
--==============================================
USE Taxi2Bachelor;
GO

Exec EvaluateTipNN @ModelName="NNTipSmall";
Exec EvaluateTipNN @ModelName="NNTipMedium";
Exec EvaluateTipNN @ModelName="NNTipBig";

/*
-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================

DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
	[real_tip_amount] float,
	[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[predicted_tip_amount] float
);
GO
Insert into #Results 
Exec [PredictTipNN] @Modelname = "NNTipBig";

---------------------------
-- Show me the Test Results
---------------------------
GO
DECLARE @realMean float;
SET @realMean = (SELECT AVG(real_tip_amount) FROM #Results);

SELECT
	(SUM(POWER(real_tip_amount - @realMean,2))) AS RSS,
	(SUM(POWER((real_tip_amount - predicted_tip_amount),2))) AS TSS,
	1- ((SUM(POWER((real_tip_amount - predicted_tip_amount),2)))/(SUM(POWER(real_tip_amount - @realMean,2)))) as RQuadrat,
	sum(abs(real_tip_amount-predicted_tip_amount)) as miss_in_Dollar,
	sum(predicted_tip_amount) as predicted_total_tip, 
	sum(real_tip_amount) as real_tip
FROM #Results;

SELECT Top (20) abs(real_tip_amount-predicted_tip_amount) as miss_in_Dollar, predicted_tip_amount as estTip, real_tip_amount as realTip from #Results;
GO
DROP TABLE IF EXISTS #Results;
GO
*/