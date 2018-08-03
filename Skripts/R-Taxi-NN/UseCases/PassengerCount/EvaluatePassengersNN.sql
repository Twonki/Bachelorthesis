Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase Passengers #3 Issue 24
--==============================

EXEC TrainPassengersNN @TrainingSize=100000;
GO
--EXEC PredictPassengersNN @ModelName="NNPassengers";
--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluatePassengersNN @ModelName="NNPassengers";
