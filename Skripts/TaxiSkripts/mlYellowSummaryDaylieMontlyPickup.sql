USE Taxi2Bachelor;
GO
Select  AVG(tmp._count) as avg_Fahrten_proStunde,SUM(tmp._count) as total_Fahrten, tmp.pickup as pickup
	from (Select count(*)as _count, Convert(Date, pickup_datetime) as _date,PULocationID as pickup, DatePart(HOUR, pickup_datetime) as daytime from mlYellowData group by PULocationID, Convert(DATE,pickup_datetime),DATEPART(HOUR,pickup_datetime)) AS tmp
Group BY tmp.pickup
ORDER BY tmp.pickup ASC
;
Select  AVG(tmp._count) as avg_Fahrten_proStunde,SUM(tmp._count) as total_Fahrten, tmp._date 
	from (Select count(*)as _count, Convert(Date, pickup_datetime) as _date,PULocationID as pickup, DatePart(HOUR, pickup_datetime) as daytime from mlYellowData group by PULocationID, Convert(DATE,pickup_datetime),DATEPART(HOUR,pickup_datetime)) AS tmp
Group BY tmp._date
ORDER BY tmp._date ASC
;
Select  AVG(tmp._count) as avg_Fahrten_proStunde,SUM(tmp._count) as total_Fahrten, tmp.daytime 
	from (Select count(*)as _count, Convert(Date, pickup_datetime) as _date,PULocationID as pickup, DatePart(HOUR, pickup_datetime) as daytime from mlYellowData group by PULocationID, Convert(DATE,pickup_datetime),DATEPART(HOUR,pickup_datetime)) AS tmp
Group BY tmp.daytime
ORDER BY tmp.daytime ASC
;