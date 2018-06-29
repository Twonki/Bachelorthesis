--------------------------------
-- Creates a NN to predict total amount of the taxiride
--------------------------------
USE Taxi2Bachelor;
GO
--Here only when no Model is ready
--Exec TrainAmountNN @TrainingSize ="10000";
GO
-- =============================================
-- Predict NN and Store Data in temporary Result-table
-- =============================================
DROP TABLE IF EXISTS #Results;
GO
Create Table #Results (
[ID] uniqueidentifier PRIMARY KEY NOT NULL, 
	[real_amount] float, 
	[RatecodeID] smallint,
	[trip_distance] float,
	[duration_in_minutes] float,
	[WetBulbTemp] real,
	[DryBulbTemp] real,
	[RelativeHumidity] smallint,
	[passenger_count] smallint,
	[Windspeed] smallint,
	[extra] real,
	[mta_tax] real,
	[PULocationID] smallint,
	[DOLocationID] smallint,
	[fare_amount] real, 
	[predicted_amount] float
);
GO
Insert into #Results 
Exec PredictAmountNN @Modelname = "NNTotalAmount";

DECLARE @realMean float;
SET @realMean = (SELECT AVG(real_amount) FROM #Results);

SELECT
	(SUM(POWER(real_amount - @realMean,2))) AS RSS,
	(SUM(POWER((real_amount - predicted_amount),2))) AS TSS,
	1- ((SUM(POWER((real_amount - predicted_amount),2)))/(SUM(POWER(real_amount - @realMean,2)))) as RQuadrat,
	sum(abs(real_amount-predicted_amount)) as miss_in_Dollar,
	sum(predicted_amount) as predicted_total_tip, 
	sum(real_amount) as real_tip
FROM #Results;
SELECT Top (100) abs(real_amount-predicted_amount) as miss_in_Dollar, predicted_amount as estTip, real_amount as realTip from #Results;
GO
DROP TABLE IF EXISTS #Results;
GO
