Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase XXX
--==============================

--EXEC TrainWaitNN @TrainingSize=100000;
GO
--EXEC PredictUseCaseWaitNN @ModelName="NNWait";
--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluateUseCaseWaitNN @ModelName="NNWait";
