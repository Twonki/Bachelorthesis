Use Taxi2Bachelor
GO
--==============================
-- Produce some Binary Tipped NN
--==============================

--EXEC TrainBinaryTippedMediumNN @TrainingSize=1000000;
GO

--==============================
-- Check them
--==============================

EXEC EvaluateBinaryTippedNN @ModelName="NNBinaryTippedMedium";