
----------------------------------------------
--    Lesson 5
--    Use predictive Model with R AND PLOT
----------------------------------------------

--faster cars
CREATE TABLE [dbo].[NewCarSpeed]([speed] [int] NOT NULL,
    [distance] [int]  NULL) ON [PRIMARY]
GO
INSERT [dbo].[NewCarSpeed] (speed)
VALUES (40),  (50),  (60), (70), (80), (90), (100)

-- get my speedmodel from the stored models
DECLARE @speedmodel varbinary(max) = (SELECT model FROM [dbo].[stopping_distance_models] WHERE model_name = 'latest model');
-- Use my speedmodel to do predict the stopping distances of the new speeds
EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
            current_model <- unserialize(as.raw(speedmodel)); #unfolds the model from binary
            new <- data.frame(NewCarData); # Curls my new Data
            predicted.distance <- rxPredict(current_model, new); #Uses my model on the data, rxPredict is package specific
            str(predicted.distance);# just to show me
            OutputDataSet <- cbind(new, ceiling(predicted.distance)); #Combine speed and distance for smarter output
            '
    , @input_data_1 = N' SELECT speed FROM [dbo].[NewCarSpeed] ' -- calls for 
    , @input_data_1_name = N'NewCarData'
    , @params = N'@speedmodel varbinary(max)' --Where are these even used???
    , @speedmodel = @speedmodel -- why do i not need to rename my variables??
WITH RESULT SETS (([new_speed] INT, [predicted_distance] INT)) --Name Stuff with usefull name and datatype


GO
-------------------------
-- Stuff that doesnt work
-------------------------

--DECLARE @speedmodel varbinary(max) = (SELECT model FROM [dbo].[stopping_distance_models] WHERE model_name = 'latest model');
DECLARE @speedmodel varbinary(max) = (select model from [dbo].[stopping_distance_models] where model_name = 'latest model');
EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
            current_model <- unserialize(as.raw(speedmodel));
            new <- data.frame(NewCarData);
            predicted.distance <- rxPredict(current_model, new);
            OutputDataSet <- cbind(new, ceiling(predicted.distance));
            '
    , @input_data_1 = N' SELECT [speed] FROM [dbo].[HugeTableofCarSpeeds] '
    , @input_data_1_name = N'NewCarData'
    , @parallel = 1
    , @params = N'@speedmodel varbinary(max)'
    , @speedmodel = @speedmodel
WITH RESULT SETS (([new_speed] INT, [predicted_distance] INT))


-- Plot 
GO
DECLARE @speedmodel varbinary(max) = (SELECT model FROM [dbo].[stopping_distance_models] WHERE model_name = 'latest model');
--DECLARE @speedmodel varbinary(max) = (select model from [dbo].[stopping_distance_models] where model_name = 'default model');
EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
            current_model <- unserialize(as.raw(speedmodel));
            new <- data.frame(NewCarData);
            predicted.distance <- rxPredict(current_model, new);
            OutputDataSet <- cbind(new, ceiling(predicted.distance));
            '
    , @input_data_1 = N' SELECT [speed] FROM [dbo].[HugeTableofCarSpeeds] '
    , @input_data_1_name = N'NewCarData'
    , @parallel = 1
    , @params = N'@speedmodel varbinary(max)'
    , @speedmodel = @speedmodel
WITH RESULT SETS (([new_speed] INT, [predicted_distance] INT))

---------------------
-- Plot ???
---------------------
Execute sp_execute_external_script
@language=N'R',
@script = N'
	imageDir <- ''C:\\Users\\Leonhard\\Documents\\SQL Server Management Studio\\R-Learning\\plots'';
	image_filename = tempfile(pattern = "plot_",tmpdir= imageDir, fileext = ".jpg")
	print(image_filename);
	jpeg(filename = image_filename , width = 600 , height = 800);
	print(plot(distance~speed, data=InputDataSet, xlab="Speed", ylab="Stopping distance", main= "1920 Car Safety"));
	abline(lm(distance~speed, data = InputDataSet));
	dev.off();
	OutputDataSet <- data.frame(data=readBin(file(image_filename, "rb"), what=raw(), n=1e6));
	'
	,@input_data_1 = N'SELECT speed, distance from [dbo].[CarSpeed]'
	WITH RESULT SETS ((plot varbinary(max)));
