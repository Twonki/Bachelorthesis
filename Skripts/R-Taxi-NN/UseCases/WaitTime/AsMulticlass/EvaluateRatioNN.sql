USE Taxi2Bachelor
GO

--==================================
-- Train some Ratio NN's
--==================================

--EXEC TrainRatioSmallNN @TrainingSize=10000;
--EXEC TrainRatioMediumNN @TrainingSize=10000;
--EXEC TrainRatioBigNN @TrainingSize=10000;
GO
--==================================
-- Evaluate some Ratio NN's
--==================================
EXEC EvaluateRatioNN @ModelName="NNRatioSmall";
EXEC EvaluateRatioNN @ModelName="NNRatioMedium";
EXEC EvaluateRatioNN @ModelName="NNRatioBig";