Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase Revenue
-- Needs a Minimum of ~10k Trainingssize to get full factors
--==============================

EXEC TrainRevenueFlatNN @TrainingSize=10000;
GO

--==============================
-- ShowMeTheResults
--==============================
--EXEC PredictRevenueNN @ModelName="NNRevenue";
EXEC EvaluateRevenueFlatNN @ModelName="NNRevenueFlat";
GO