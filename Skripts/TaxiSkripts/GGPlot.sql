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
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;
	str(df);
	chart <- ggplot(data=df, aes(x=wet, y=dry)) +geom_point();
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
	,@input_data_1 = N'SELECT [HOURLYDRYBULBTEMPC] as dry,[HOURLYWETBULBTEMPC] as wet from [dbo].[WeatherData]'
	WITH RESULT SETS ((plot varbinary(max)));

GO

Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot2.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;
	str(df);
	chart <- ggplot(data=df, aes(x=DO, y=PU)) +geom_point();
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
	,@input_data_1 = N'
		SELECT TOP (10000) 
			[DOLocationID] as DO,
			[PULocationID] as PU,
			duration_in_minutes as time
		FROM yellowSample; 
	'
	WITH RESULT SETS ((plot varbinary(max)));
GO


Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot3.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;
	str(df);
	chart <- ggplot(data=df, aes(x=time, y=cost)) + geom_point()+ theme_bw() + ggtitle("Cost of a Taxidrive by time")+ facet_wrap(~rate);
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
,@input_data_1 = N'
	SELECT TOP (100) 
		[total_amount] as cost,
		[tip_amount] as tip,
		[duration_in_minutes] as time,
		[trip_distance] as distance,
		[RatecodeID] as rate
	FROM yellowSample; 
'
WITH RESULT SETS ((plot varbinary(max)));


Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot4.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;

	chart <- ggplot(data=df, aes(x=cost, y=time, fill=rate)) + geom_density(alpha=0.4)+ ggtitle("Taxicost Density Chart")+ labs(x="Cost",y="Density",fill="Rate")+theme_bw()+theme(title=element_text(size=16, color="blue3"));
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
,@input_data_1 = N'
	SELECT TOP (100) 
		[total_amount] as cost,
		[tip_amount] as tip,
		[duration_in_minutes] as time,
		[trip_distance] as distance,
		[RatecodeID] as rate
	FROM yellowSample; 
'
WITH RESULT SETS ((plot varbinary(max)));



Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot5.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;

	chart <- (ggplot(data=df)  
		+ geom_point(aes(y=cost, x=date, colour="yellow"))
		+ geom_point(aes(y=tip, x=date, colour="green2"))
		+ geom_smooth(aes(y=cost, x=date, colour="brown"))
		+ geom_smooth(aes(y=tip, x=date, colour="green"))
		+ ggtitle("Taxicost and Tips by Date")
		+ labs(x="Date",y="Cost in Dollar")
		+theme_bw()
		+theme(title=element_text(size=16, color="blue3"))  );
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
,@input_data_1 = N'
	SELECT TOP (1000) 
		[total_amount] as cost,
		[tip_amount] as tip,
		[duration_in_minutes] as time,
		[trip_distance] as distance,
		[RatecodeID] as rate,
		CONVERT(DATE,[pickup_datetime]) as date
	FROM yellowSample; 
'
WITH RESULT SETS ((plot varbinary(max)));




Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot6.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;

	chart <- (ggplot(data=df)  
		+ geom_smooth(aes(y=distance, x=date, colour="yellow"))
		+ geom_smooth(aes(y=time, x=date, colour="red"))
		+ geom_smooth(aes(y=cost, x=date, colour="brown"))
		+ geom_smooth(aes(y=tip, x=date, colour="green"))
		+ ggtitle("Different Attributes over Time")
		+ labs(x="Date",y="Various")
		+theme_bw()
		+theme(title=element_text(size=16, color="blue3"))  );
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
,@input_data_1 = N'
	SELECT TOP (1000) 
		[total_amount] as cost,
		[tip_amount] as tip,
		[duration_in_minutes] as time,
		[trip_distance] as distance,
		[RatecodeID] as rate,
		CONVERT(DATE,[pickup_datetime]) as date
	FROM yellowSample; 
'
WITH RESULT SETS ((plot varbinary(max)));



Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot7.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;

	chart <- (ggplot(data=df)  
		+ geom_smooth(aes(y=distance, x=time, colour="yellow"))
		+ geom_smooth(aes(y=cost, x=time, colour="brown"), se= FALSE) 
		+ theme(legend.position = "bottom") 
		+ guides(colour = guide_legend(nrow = 1, override.aes = list(size = 3)))
		+ geom_smooth(aes(y=tip, x=time, colour="green"))
		+ ggtitle("Different Attributes over Time")
		+ labs(x="Date",y="Various")
		+theme_bw()
		+theme(title=element_text(size=16, color="blue3"))  );
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
,@input_data_1 = N'
	SELECT TOP (1000) 
		[total_amount] as cost,
		[tip_amount] as tip,
		[duration_in_minutes] as time,
		[trip_distance] as distance,
		[RatecodeID] as rate,
		CONVERT(DATE,[pickup_datetime]) as date
	FROM yellowSample; 
'
WITH RESULT SETS ((plot varbinary(max)));



Execute sp_execute_external_script
@language=N'R',
@script = N'
	# ONLY WORKED IN TMP FOLDER!!!
	library(ggplot2);
	library(tidyverse);
	image_filename="C:\\tmp\\ggtestplot8.jpg";	
	jpeg(filename = image_filename , width = 1200 , height = 1000);

	df <- InputDataSet;

	chart <- (ggplot(data=df)  
		+ geom_smooth(aes(y=cost, x=date, color=rate))
		+ geom_smooth(aes(y=tip, x=date, color=rate))
		+ ggtitle("Cost over Time")
		+ labs(x="Date",y="Cost")
		+theme_bw()
		+theme(title=element_text(size=16, color="blue3"))  );
	print(chart);
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
,@input_data_1 = N'
	SELECT  
		[total_amount] as cost,
		[tip_amount] as tip,
		[duration_in_minutes] as time,
		[trip_distance] as distance,
		[RatecodeID] as rate,
		CONVERT(DATE,[pickup_datetime]) as date
	FROM yellowSample; 
'
WITH RESULT SETS ((plot varbinary(max)));


