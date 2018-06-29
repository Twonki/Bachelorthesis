USE Taxi2Bachelor
GO

--==================================
-- Train some DO NN's
--==================================

EXEC [TrainDOMediumNN] @TrainingSize=10000;
GO
--==================================
-- Evaluate some DO NN's
--==================================
EXEC EvaluateDONN @ModelName="NNDOMedium";