--Enable external script validation
--show me configurations
sp_configure
--allow scripts
EXEC sp_configure 'external scripts enabled',1
RECONFIGURE WITH OVERRIDE
EXEC sp_configure 'Show Advanced Options',1
GO
RECONFIGURE
GO
EXEC sp_configure 'Ad Hoc Distributed Queries',1
GO
RECONFIGURE
GO
--now restart 