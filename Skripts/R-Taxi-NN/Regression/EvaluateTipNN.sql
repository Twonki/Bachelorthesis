--=============================================
-- Mein NN Ger�st f�r Taschengeld
--==============================================
USE Taxi2Bachelor;
GO

Exec TrainTipMediumNN @TrainingSize=10000;
GO
Exec EvaluateTipNN @ModelName="NNTipMedium";
