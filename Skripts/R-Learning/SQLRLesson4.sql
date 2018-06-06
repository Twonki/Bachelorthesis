----------------------------------------------
--    Lesson 4 
--    Create a predictive Model with R 
----------------------------------------------

-- Table for Training Data
--imports from some sample data in R or SQL-R libraries
CREATE TABLE CarSpeed ([speed] int not null, [distance] int not null)
INSERT INTO CarSpeed
EXEC sp_execute_external_script
        @language = N'R'
        , @script = N'car_speed <- cars;'
        , @input_data_1 = N''
        , @output_data_1_name = N'car_speed'
		
GO
-- library(help="datasets") in R prompt to check what basic datasets are there

--Linear regression Model
DROP PROCEDURE IF EXISTS generate_linear_model;
GO
CREATE PROCEDURE generate_linear_model
AS
BEGIN
    EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'lrmodel <- rxLinMod(formula = distance ~ speed, data = CarsData) ; #rxLinMod is function from R (Look to my sheet)
        trained_model <- data.frame(payload = as.raw(serialize(lrmodel, connection=NULL))); #Trains the model'
    , @input_data_1 = N'SELECT [speed], [distance] FROM CarSpeed' 
    , @input_data_1_name = N'CarsData' --Rename my CarsSpeed Table (Whyever we would do that?)
    , @output_data_1_name = N'trained_model'
    WITH RESULT SETS ((model varbinary(max)));
END;
GO

--Store the Result somewhere
CREATE TABLE stopping_distance_models (
    model_name varchar(30) not null default('default model') primary key,
    model varbinary(max) not null);
GO
-- Run only once because you primary identifier
INSERT INTO stopping_distance_models (model)
EXEC generate_linear_model;
GO
-- show me
Select * from stopping_distance_models;
-- run in a way to have a more precise identifier to run twice etc. 
UPDATE stopping_distance_models
SET model_name = 'rxLinMod ' + format(getdate(), 'yyyy.MM.HH.mm', 'en-gb')
WHERE model_name = 'default model'
-- show me again
Select * from stopping_distance_models;

-- Last Stuff is 1 Batch
-- output of different dataframes
DECLARE @model varbinary(max), @modelname varchar(30)
EXEC sp_execute_external_script
    @language = N'R'
    , @script = N'
        speedmodel <- rxLinMod(distance ~ speed, CarsData)
        modelbin <- serialize(speedmodel, NULL)
        OutputDataSet <- data.frame(coefficients(speedmodel));'
    , @input_data_1 = N'SELECT [speed], [distance] FROM CarSpeed'
    , @input_data_1_name = N'CarsData'
    , @params = N'@modelbin varbinary(max) OUTPUT'
    , @modelbin = @model OUTPUT
    WITH RESULT SETS (([Coefficient] float not null));

-- Save the generated model
INSERT INTO [dbo].[stopping_distance_models] (model_name, model)
VALUES ('latest model', @model)


