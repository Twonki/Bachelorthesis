-------------------------------------
-- Lesson 2   
-------------------------------------
 
 --Always use Dataframes, 
 -- Stored Procedures need to return a dataframe, all other objecttypes are not supported
 -- there are many options to convert objects to dataframes


 /*    
CREATE TABLE RTestData ([col1] int not null) ON [PRIMARY]
INSERT INTO RTestData   VALUES (1);
INSERT INTO RTestData   VALUES (10);
INSERT INTO RTestData   VALUES (100) ;
GO
*/
 
 -- Same as in Lesson 1
   EXECUTE sp_execute_external_script
       @language = N'R'
     , @script = N' mytextvariable <- c("hello", " ", "world");
       OutputDataSet <- as.data.frame(mytextvariable);'
     , @input_data_1 = N' '; -- Always need for Input Data, here Empty
	 
--Example 2
-- Same Data, but different dataframe. (constructor is moved)
EXECUTE sp_execute_external_script
        @language = N'R'
      , @script = N' OutputDataSet<- data.frame(c("hello"), " ", c("world"));'
      , @input_data_1 = N'  ';
	  
	  
-- calling str() shows structure (=Datatype) of the object in the messages Tab
EXECUTE sp_execute_external_script
        @language = N'R'
      , @script = N' mytextvariable <- c("hello", " ", "world");
      OutputDataSet <- as.data.frame(mytextvariable);
      str(OutputDataSet);'
      , @input_data_1 = N'  '
;
-- str can be called about anywhere, and is very usefull to debug
EXECUTE sp_execute_external_script
  @language = N'R', 
  @script = N' OutputDataSet <- data.frame(c("hello"), " ", c("world"));
    str(OutputDataSet);' , 
  @input_data_1 = N'  ';
  
-- example for matrix-multiplication
-- multiplying matrix with array works, shows that there is a implicit type conversion 
  EXECUTE sp_execute_external_script
    @language = N'R'
    , @script = N'
        x <- as.matrix(InputDataSet); # Vector with 3 Values
        y <- array(12:15); # Array with 4 Values from 12 to 15
    OutputDataSet <- as.data.frame(x %*% y); # Creates a 4x3 Matrix'
    , @input_data_1 = N' SELECT [Col1]  from RTestData;'
    WITH RESULT SETS (([Col1] int, [Col2] int, [Col3] int, Col4 int));
	
-- Multypling now has 2 vektors of the same dimension
-- this makes one value of the inner product of the matrix
execute sp_execute_external_script
   @language = N'R'
   , @script = N'
        x <- as.matrix(InputDataSet);
        y <- array(12:14);
   OutputDataSet <- as.data.frame(y %*% x); # Changed Y and X'
   , @input_data_1 = N' SELECT [Col1]  from RTestData;'
 WITH RESULT SETS (([Col1] int ));
   
   
   --merge and mulitply columns
 -- Combines the vector and the array to a list of vectors
   EXECUTE sp_execute_external_script
    @language = N'R'
    , @script = N'
               df1 <- as.data.frame( array(1:6) );
               df2 <- as.data.frame( c( InputDataSet , df1 ));
			   str(df2);
               OutputDataSet <- df2'
    , @input_data_1 = N' SELECT [Col1]  from RTestData;'
    WITH RESULT SETS (( [Col2] int not null, [Col3] int not null ));
	
/* Exa,ple that oyu need to cast because of different Types in SQLServer and R
 No need for me, i don't have Adventureworks
	SELECT ReportingDate
         , CAST(ModelRegion as varchar(50)) as ProductSeries
         , Amount
           FROM [AdventureWorksDW2014].[dbo].[vTimeSeries]
           WHERE [ModelRegion] = 'M200 Europe'
           ORDER BY ReportingDate ASC
*/