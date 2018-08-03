Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase XXX
--==============================

--EXEC TrainUseCaseNN @TrainingSize=1000000;
GO

--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluateUseCaseNN @ModelName="NNUseCase";
