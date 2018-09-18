Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase Passengers #3 Issue 24
--==============================

EXEC TrainPassengersFlatNN @TrainingSize=1000000;
GO
--EXEC PredictPassengersNN @ModelName="NNPassengers";
--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluatePassengersFlatNN @ModelName="NNPassengersFlat";
