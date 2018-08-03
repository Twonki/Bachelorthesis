--=========================================================================================
-- Procedure to Evaluate the Prediction
-- A Temporary Resulttable is created and filled by PredictUseCaseTip
-- Fitting Summarization is done on the Temporary Table and outputtet
-- Outputs: First 10 Predicted Values, R^2 Score of Model for TestData
--=========================================================================================
USE Taxi2Bachelor;
GO
DROP PROCEDURE IF EXISTS EvaluateUseCaseTipNN
GO
CREATE PROCEDURE EvaluateUseCaseTipNN
@ModelName varchar(max)
AS
BEGIN
	DROP TABLE IF EXISTS #Results;
	Create Table #Results(
		[distance] float,
		[PULocationID] smallint,
		[passengerCount] smallint,
		[real_tip_amount] float,
		[predicted_tip_amount] float);
	INSERT INTO #Results 
		EXEC [PredictUseCaseTipNN] @Modelname = "NNTip";
	
	SELECT TOP(10) * FROM #Results;

	DECLARE @realMean float;
	SET @realMean = (SELECT AVG(real_tip_amount) FROM #Results);

	SELECT
		(SUM(POWER(real_tip_amount - @realMean,2))) AS RSS,
		(SUM(POWER((real_tip_amount - predicted_tip_amount),2))) AS TSS,
		1- ((SUM(POWER((real_tip_amount - predicted_tip_amount),2)))/(SUM(POWER(real_tip_amount - @realMean,2)))) as RQuadrat,
		sum(abs(real_tip_amount-predicted_tip_amount)) as miss_in_Dollar,
		sum(predicted_tip_amount) as predicted_total_tip, 
		sum(real_tip_amount) as real_tip
	FROM #Results;

	--==============================
	-- Plot here?
	--==============================


Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\NNTipMiss.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;

	chart <- ggplot(data=df, aes(x=cost, y=time, fill=rate)) + geom_density(alpha=0.4)+ ggtitle("Tip-Prediction")+ labs(x="Cost",y="Density")+theme_bw()+theme(title=element_text(size=16, color="blue3"));
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
,@input_data_1 = N'
	SELECT  
		[real_tip_amount]
		[predicted_tip_amount]
	FROM #Results; 
'
WITH RESULT SETS ((plot varbinary(max)));


	DROP TABLE IF EXISTS #Results;
END
GO