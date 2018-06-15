use Taxi2Bachelor
GO

DROP TABLE IF Exists Models
CREATE TABLE Models(
	[id] [uniqueidentifier] NOT NULL,
	[model_name] [varchar](30) NOT NULL,
	[model] [varbinary](max) NOT NULL,
	[timest] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE Models ADD  DEFAULT NEWID() FOR [id]
ALTER TABLE Models ADD  DEFAULT ('unnamed model') FOR [model_name]
GO

INSERT INTO Models
SELECT * FROM NNAmountModel;
