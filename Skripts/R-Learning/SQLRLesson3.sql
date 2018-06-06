
-------------------------------------
-- Lesson 3
-- R Functions   
-------------------------------------

-- Generate rnd numers with r
--as.data.frame(rnorm(100, mean = 50, sd = 3));

-- Using this in sql
-- Give 100 random numbers with a mean of 50 and standard-derivation of 3EXEC sp_execute_external_script
      @language = N'R'
    , @script = N'
         OutputDataSet <- as.data.frame(rnorm(100, mean = 50, sd =3));'
    , @input_data_1 = N'   ;'
      WITH RESULT SETS (([Density] float NOT NULL));

GO
--make a real SQL-Procedure with my Random Numbers
--This Wraps R Code in native SQL Stuff
CREATE PROCEDURE MyRNorm (@param1 int, @param2 int, @param3 int)
AS
    EXEC sp_execute_external_script
		  @language = N'R'
		, @script = N'
			 OutputDataSet <- as.data.frame(rnorm(mynumbers, mymean, mysd));'
		, @input_data_1 = N'   ;'
		, @params = N' @mynumbers int, @mymean int, @mysd int'
		, @mynumbers = @param1
		, @mymean = @param2
		, @mysd = @param3
	WITH RESULT SETS (([Density] float NOT NULL));
GO
-- Use my new Procedure (Does exactly the same as first script)
EXEC MyRNorm @param1 = 100,@param2 = 50, @param3 = 3
GO	
-- Troubleshooting with R calling utils library
EXECUTE sp_execute_external_script
      @language = N'R'
    , @script = N'
        library(utils);
        mymemory <- memory.limit();
        OutputDataSet <- as.data.frame(mymemory);'
    , @input_data_1 = N' ;'
WITH RESULT SETS (([Col1] int not null));
