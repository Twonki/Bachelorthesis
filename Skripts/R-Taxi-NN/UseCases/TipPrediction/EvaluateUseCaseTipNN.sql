Use Taxi2Bachelor
GO

--==============================
-- Produce some NN's for UseCase Tip
--==============================

EXEC [TrainTipNN] @TrainingSize=10000000;
GO

--==============================
-- ShowMeTheResults
--==============================

EXEC EvaluateUseCaseTipNN @ModelName="NNTip";

EXEC SolveUseCaseTipNN @ModelName="NNTip", @distance=1.55,@PULocationID=155,@passengers=3; 