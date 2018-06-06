USE [Taxi2Bachelor]
GO

/****** Object:  Table [dbo].[WeatherStations]    Script Date: 16.05.2018 10:23:13 ******/
DROP TABLE [dbo].[WeatherStations]
GO

/****** Object:  Table [dbo].[WeatherStations]    Script Date: 16.05.2018 10:23:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WeatherStations](
	[Station] [nvarchar](15) NOT NULL,
	[Longitude] [decimal](10, 6),
	[Latitude] [decimal](10, 6),
	[Elevation] [decimal](4, 2),
	[Name] [nvarchar](30),
 CONSTRAINT [PK_WeatherStations] PRIMARY KEY CLUSTERED 
(
	[Station] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


