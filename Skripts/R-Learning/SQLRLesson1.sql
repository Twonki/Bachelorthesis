
-------------------------------------
-- Lesson 1   
-------------------------------------

CREATE TABLE RTestData ([col1] int not null) ON [PRIMARY]
INSERT INTO RTestData   VALUES (1);
INSERT INTO RTestData   VALUES (10);
INSERT INTO RTestData   VALUES (100) ;
GO

SELECT * FROM RTestData
GO

EXECUTE sp_execute_external_script
      @language = N'R' 
    , @script = N' OutputDataSet <- InputDataSet;' -- Hier steht mein GESAMTES Skript in einem Text
    , @input_data_1 = N' SELECT *  FROM RTestData;'
    WITH RESULT SETS (([NewColName] int NOT NULL)); --Optional für Benennung und Typisierung
GO
-- Next one is faulty, to show case Sensitivity and how an error looks like (Thanks ms)
EXECUTE sp_execute_external_script
  @language = N'R'
  , @script = N' SQL_out <- SQL_in;'
  , @input_data_1 = N' SELECT 12 as Col;'
  , @input_data_1_name  = N'SQL_In' -- Renaming Inout
  , @output_data_1_name =  N'SQL_Out' -- Renaming Output
 WITH RESULT SETS (([NewColName] int NOT NULL));
 -- now corrected
 EXECUTE sp_execute_external_script
  @language = N'R'
  , @script = N' SQL_Out <- SQL_In;'
  , @input_data_1 = N' SELECT 12 as Col;'
  , @input_data_1_name  = N'SQL_In' -- Renaming Inout
  , @output_data_1_name =  N'SQL_Out' -- Renaming Output
 WITH RESULT SETS (([NewColName] int NOT NULL));
 GO


 --Show how to use lokal variables and script with more than one row
 EXECUTE sp_execute_external_script
    @language = N'R'
   , @script = N' mytextvariable <- c("hello", " ", "world");
       OutputDataSet <- as.data.frame(mytextvariable);'
   , @input_data_1 = N' SELECT 1 as Temp1'
   WITH RESULT SETS (([Col1] char(20) NOT NULL));
GO
   