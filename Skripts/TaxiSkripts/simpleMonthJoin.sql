USE Taxi2Bachelor
GO

--Simple Grouping of Trips by Month 
-- later deprecated because the datepart is not exact enough
Select count(*) as trips, datepart(Month,pickup_datetime) as month 
from greenData where datepart(year,pickup_datetime)=2017 
group by datepart(month, pickup_datetime)
GO
Select avg(TMAX) as avgMaxTmp, avg(AWND) as avgWind, Datepart(Month,DATE) as month 
from WeatherData 
Group by DATEPART(month, DATE)
GO

--Grouping Trips by Day with different approach
-- i guess this is much better
Select count(*) as trips, CONVERT(date,pickup_datetime) as date_ 
from greenData where datepart(year,pickup_datetime)=2017 
group by CONVERT(date, pickup_datetime)
GO

--Grouping Trips by Hour 
--Woorks good (and fast), for use in later copy+paste
(Select count(*) as trips, DATEADD(hour,DATEDIFF(hour,0,yellowData.[pickup_datetime]),0) as hour_ 
		from yellowData 
		where datepart(year,pickup_datetime)=2017 
		group by DATEADD(hour,DATEDIFF(hour,0,yellowData.[pickup_datetime]),0) )
GO

--Grouping Trips by Hour whilst keeping day
--Works, but takes long time (Maybe there is a better Solution?)
(Select count(*) as trips, DATEADD(hour,DATEDIFF(hour,0,yellowData.[pickup_datetime]),0) as hour_ , DATEADD(day,DATEDIFF(day,0,yellowData.[pickup_datetime]),0) as day_
		from yellowData 
		where datepart(year,pickup_datetime)=2017 
		group by DATEADD(day,DATEDIFF(day,0,yellowData.[pickup_datetime]),0),DATEADD(hour,DATEDIFF(hour,0,yellowData.[pickup_datetime]),0) )
GO

-- Grouping Trips by Hour whilst keeping day, approach 2
-- group by order is muy importante
-- For Copy and paste
Select count(*) as trips, CONVERT(date,pickup_datetime) as date_,DATEPART(Hour, pickup_datetime) as hour_
from greenData where datepart(year,pickup_datetime)=2017 
group by CONVERT(date, pickup_datetime), DATEPART(Hour, pickup_datetime)
ORDER BY date_,hour_
GO


-- Group weather and trips by month and join it
-- first for easy green data
Select trips, avgMaxTmp,avgWind,g.month_ from 
	(Select count(*) as trips, datepart(Month,pickup_datetime) as month_ from greenData where datepart(year,pickup_datetime)=2017 group by datepart(month, pickup_datetime)) AS g JOIN (Select avg(TMAX) as avgMaxTmp, avg(AWND) as avgWind, Datepart(Month,DATE) as month_ from WeatherData Group by DATEPART(month, DATE)) AS W
	ON g.month_ = w.month_
	ORDER BY g.month_
GO


--Group Weather and trips by month and join it
-- for rich yellowTaxi data
Select trips, avgMaxTmp,avgWind,y.month_ from 
		(Select count(*) as trips, datepart(Month,pickup_datetime) as month_ 
		from yellowData 
		where datepart(year,pickup_datetime)=2017 
		group by datepart(month, pickup_datetime)) 
		AS y
	JOIN 
		(Select avg(TMAX) as avgMaxTmp, avg(AWND) as avgWind, Datepart(Month,DATE) as month_ 
		from WeatherData 
		Group by DATEPART(month, DATE)) 
		AS w
	ON y.month_ = w.month_
	ORDER BY y.month_
GO
-- Group Weather and trips by day and join it
-- for rich yellowTaxi data
Select trips, avgMaxTmp,avgWind,y.day_ from 
		(Select count(*) as trips, DATEADD(day,DATEDIFF(Day,0,yellowData.[pickup_datetime]),0) as day_ 
		from yellowData 
		where datepart(year,pickup_datetime)=2017 
		group by DATEADD(day,DATEDIFF(day,0,yellowData.[pickup_datetime]),0) )
		AS y
	JOIN 
		(Select avg(TMAX) as avgMaxTmp, avg(AWND) as avgWind, DATEADD(day,DATEDIFF(day,0,DATE),0) as day_
		from WeatherData 
		Group by DATEADD(DAY,DATEDIFF(DAY,0,DATE),0))
		AS w
	ON y.day_ = w.day_
	ORDER BY y.day_
GO

--Group Weather and trips by hour and join it
-- for rich yellowTaxi data
-- tricky, because weather doesn't have hours
Select trips, avgMaxTmp,avgWind,y.date_,y.hour_ from 
		(Select count(*) as trips, CONVERT(date,pickup_datetime) as date_,DATEPART(Hour, pickup_datetime) as hour_
		from greenData where datepart(year,pickup_datetime)=2017 
		group by CONVERT(date, pickup_datetime), DATEPART(Hour, pickup_datetime))
		AS y
	JOIN 
		(Select avg(TMAX) as avgMaxTmp, avg(AWND) as avgWind, CONVERT(DATE,WeatherData.DATE) as date_
		from WeatherData 
		Group by CONVERT(DATE,WeatherData.Date))
		AS w
		--next line is the Reason for splitting the dateTime
	ON y.date_ = w.date_
	ORDER BY y.date_,y.hour_
GO

