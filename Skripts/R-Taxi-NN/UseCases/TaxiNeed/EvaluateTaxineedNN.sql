Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase Rides
-- Needs a Minimum of ~10k Trainingssize to get full factors
--==============================

EXEC TrainRidesNN @TrainingSize=500000;
GO

--==============================
-- ShowMeTheResults
--==============================
EXEC EvaluateRidesNN @ModelName="NNRides";
GO
