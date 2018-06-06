--First Steps with R
--Hello world and basic stuff from MS Doc

--This is Hello world, to check if R-Services work fine
EXEC sp_execute_external_script
	@language =N'R',
	@script=N'OutputDataSet <- InputDataSet',
	@input_data_1 =N'SELECT 1 AS hello'
	WITH RESULT SETS (([hello] int not null))
GO