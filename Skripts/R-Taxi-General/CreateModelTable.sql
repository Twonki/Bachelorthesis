USE [Taxi2Bachelor]
GO

/****** Object:  Table [dbo].[total_amounts_models]    Script Date: 30.05.2018 09:12:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tipAmount_models](
	[model_name] [varchar](30) NOT NULL,
	[model] [varbinary](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[model_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[tipAmount_models] ADD  DEFAULT ('default model') FOR [model_name]
GO


