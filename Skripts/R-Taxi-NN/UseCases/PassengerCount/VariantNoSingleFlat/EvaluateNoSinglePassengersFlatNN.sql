Use Taxi2Bachelor
GO
--==============================
-- Produce some NN's for UseCase Passengers #3 Issue 24
--==============================
SELECT CURRENT_TIMESTAMP;
GO
EXEC [TrainNoSinglePassengersFlatNN] @TrainingSize=10000;
GO
--EXEC PredictPassengersNN @ModelName="NNPassengers";
--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluateNoSinglePassengersFlatNN @ModelName=NNNoSinglePassengersFlat;
GO
SELECT CURRENT_TIMESTAMP;
GO
/*
EXEC [TrainNoSinglePassengersFlatNN] @TrainingSize=5000;
GO
SELECT CURRENT_TIMESTAMP;
GO
EXEC EvaluateNoSinglePassengersFlatNN @ModelName=NNNoSinglePassengersFlat;
GO
EXEC [TrainNoSinglePassengersFlatNN] @TrainingSize=10000;
GO
SELECT CURRENT_TIMESTAMP;
GO
EXEC EvaluateNoSinglePassengersFlatNN @ModelName=NNNoSinglePassen
gersFlat;
GO
EXEC [TrainNoSinglePassengersFlatNN] @TrainingSize=50000;
GO
SELECT CURRENT_TIMESTAMP;
GO
EXEC EvaluateNoSinglePassengersFlatNN @ModelName=NNNoSinglePassengersFlat;
*/