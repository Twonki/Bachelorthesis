Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase Revenue
--==============================

EXEC TrainRevenueNN @TrainingSize=100000;
GO

--==============================
-- ShowMeTheResults
--==============================
EXEC PredictRevenueNN @ModelName="NNRevenue";
--EXEC EvaluateUseCaseNN @ModelName="NNUseCase";
