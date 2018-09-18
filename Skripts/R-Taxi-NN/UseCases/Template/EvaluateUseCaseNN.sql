Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase XXX
--==============================
SELECT CURRENT_TIMESTAMP;
GO
EXEC TrainUseCaseNN @TrainingSize=1000000;
GO
SELECT CURRENT_TIMESTAMP;
GO
--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluateUseCaseNN @ModelName="NNUseCase";
