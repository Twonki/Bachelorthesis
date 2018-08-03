Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase #2
--==============================

EXEC TrainWaitSecondsNN @TrainingSize=100000;
GO
--EXEC PredictUseCaseWaitNN @ModelName="NNWait";
--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluateUseCaseWaitSecondsNN @ModelName="NNWaitSeconds";
