--=============================================
-- Mein NN Gerüst für Taschengeld
--==============================================
USE Taxi2Bachelor;
GO

Exec TrainTipMediumNN @TrainingSize=10000;
GO
Exec EvaluateTipNN @ModelName="NNTipMedium";
