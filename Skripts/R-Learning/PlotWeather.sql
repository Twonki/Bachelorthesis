-------------------------
-- these scripts produce some simple plots about mlGreenData
-- Plots are stored in C:/tmp
-------------------------

USE Taxi2Bachelor
GO

---------------------
-- Simple Plot in Tmpfolder
-- shown is the correlation of wet and dry bulbtemperature
-- WORKES ONLY IN TMPFOLDER
---------------------
Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	image_filename="C:\\tmp\\testplot1.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);
	print(plot(wet~dry, data=InputDataSet, xlab="drytmp", ylab="wettmp", main= "Correlation of wet and dry tmp"));
	abline(lm(wet~dry, data = InputDataSet));
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
	,@input_data_1 = N'SELECT [HOURLYDRYBULBTEMPC] as dry,[HOURLYWETBULBTEMPC] as wet from [dbo].[WeatherData]'
	WITH RESULT SETS ((plot varbinary(max)));


---------------------
-- Different Simple Plot in Tmpfolder
-- shown are the count of drives as a normal graph
-- WORKED ONLY IN TMPFOLDER
---------------------
Execute sp_execute_external_script
@language=N'R',
@script = N'
	image_filename="C:\\tmp\\testplot2.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);
	print(plot(fahrten ~ date_, data=InputDataSet,type="o", col="black",xlab="Datum",ylab="Anzahl der Fahrten"), main="Verlauf des Fahrtenaufkommens");
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
	,@input_data_1 = N'SELECT Count(*) AS fahrten, SUM(total_amount) as totalAmount, AVG(DryBulbTemp) AS avgTmp, CONVERT(DATE, pickup_datetime) AS date_ from mlGreenData GROUP BY CONVERT(DATE, pickup_datetime) ORDER BY date_ ASC'
	,@input_data_1_name=N'InputDataSet'
	WITH RESULT SETS ((plot varbinary(max)));


---------------------
-- Different Simple Plot in Tmpfolder
-- Shows ... everything about given Dataset
-- WORKED ONLY IN TMPFOLDER
---------------------
Execute sp_execute_external_script
@language=N'R',
@script = N'
	df<- InputDataSet;
	image_filename="C:\\tmp\\testplot3.jpg";	
	jpeg(filename = image_filename , width = 2400 , height = 2400);
	print(plot(df, main="Überblick"));
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
	,@input_data_1 = N'SELECT Count(*) AS fahrten, SUM(total_amount) as totalAmount, AVG(DryBulbTemp) AS avgTmp, CONVERT(DATE, pickup_datetime) AS date_ from mlGreenData GROUP BY CONVERT(DATE, pickup_datetime) ORDER BY date_ ASC'
	,@input_data_1_name=N'InputDataSet'
	WITH RESULT SETS ((plot varbinary(max)));

---------------------------------
-- Plot, and store in temporary Plot DB
-- This is no real visualisation without help
---------------------------------
Drop table if exists #plots
GO
Create table #plots (
	id int IDENTITY(1,1) PRIMARY KEY,
	plot varbinary(max) not null
	)
GO
DROP PROCEDURE IF EXISTS easy_weather_plot;
GO
CREATE PROCEDURE easy_weather_plot
AS
BEGIN
EXEC sp_execute_external_script	
	@language=N'R'
	,@script=N' df <- inputDataSet;
		image_file=tempfile()
		#image_file="C:\\Users\\Leonhard\\Desktop\\TestPlot.jpeg"
		jpeg(filename=image_file, width=500, height=500);
		#hist(df$Values);
		plot(wet~dry, data=inputDataSet, xlab="drytmp", ylab="wettmp", main= "Correlation of wet and dry tmp")
		dev.off();
		OutputDataset <- data.frame(data=readBin(file(image_file,"rb"),what=raw(),n=1e6));
		'
	,@input_data_1 = N'SELECT [HOURLYDRYBULBTEMPC] as dry,[HOURLYWETBULBTEMPC] as wet from [dbo].[WeatherData]'
	,@input_data_1_name=N'inputDataSet'
	,@output_data_1_name=N'OutputDataset'
	WITH RESULT SETS ((plot varbinary(max)));
END

Insert into #plots (plot)
exec easy_weather_plot
GO
SELECT * FROM #plots;

-------------
-- Legacy Dirs which didn#t work
-------------
--	#imageDir <- "C:\\Users\\Leonhard\\Documents\\SQL Server Management Studio\\R-Learning";
--	#image_filename = tempfile(pattern = "plot_",tmpdir= imageDir, fileext = ".jpg")
--	#image_filename = "C:\\Users\\Leonhard\\Desktop\\plot1.jpg"
--	#image_filename = tempfile();