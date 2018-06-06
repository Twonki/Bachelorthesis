------------------------------------
-- Drop and Create the Model-Tables
------------------------------------

USE [Taxi2Bachelor]
GO

DROP Table if Exists [dbo].[tipAmount_models];
DROP Table if Exists [dbo].[tip_models];
DROP Table if Exists [dbo].[total_amounts_models];
GO

CREATE TABLE [dbo].[tipAmount_models](
	[id] [uniqueidentifier] NOT NULL,
	[model_name] [varchar](30) NOT NULL,
	[model] [varbinary](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[tipAmount_models] ADD  DEFAULT NEWID() FOR [id]
ALTER TABLE [dbo].[tipAmount_models] ADD  DEFAULT ('default model') FOR [model_name]
GO

CREATE TABLE [dbo].[total_amounts_models](
	[id] [uniqueidentifier] NOT NULL,
	[model_name] [varchar](30) NOT NULL,
	[model] [varbinary](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[total_amounts_models] ADD  DEFAULT NEWID() FOR [id]
ALTER TABLE [dbo].[total_amounts_models] ADD  DEFAULT ('default model') FOR [model_name]
GO

CREATE TABLE [dbo].[tip_models](
	[id] [uniqueidentifier] NOT NULL,
	[model_name] [varchar](30) NOT NULL,
	[model] [varbinary](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE  [dbo].[tip_models] ADD  DEFAULT NEWID() FOR [id]
ALTER TABLE  [dbo].[tip_models] ADD  DEFAULT ('default model') FOR [model_name]
GO