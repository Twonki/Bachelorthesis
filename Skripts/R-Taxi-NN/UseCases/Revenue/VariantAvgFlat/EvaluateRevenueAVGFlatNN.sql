Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase Revenue
-- Needs a Minimum of ~10k Trainingssize to get full factors
--==============================

--EXEC TrainRevenueAVGFlatNN @TrainingSize=1000000;
GO

--==============================
-- ShowMeTheResults
--==============================
EXEC EvaluateRevenueAVGFlatNN @ModelName="NNRevenueAVGFlat";
GO