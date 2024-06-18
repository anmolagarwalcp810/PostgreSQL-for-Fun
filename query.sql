--PREAMBLE--
CREATE VIEW papers126 AS(
WITH RECURSIVE graph(paths) AS(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist
)
UNION
(SELECT paths||paperid2 FROM
graph,citationlist WHERE
paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT (SELECT paths[array_length(paths,1)])=126) AND (NOT paperid2=ANY(paths))
)
)SELECT DISTINCT paths[1] FROM graph WHERE (SELECT paths[array_length(paths,1)])=126
);
CREATE VIEW papers_graph AS
(WITH RECURSIVE graph(paths) AS(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist)
UNION
(SELECT paths||paperid2 FROM
citationlist, graph WHERE
paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths)))
) SELECT * FROM graph);


--1--
WITH RECURSIVE airportsFromAlbuquerque(x,y) AS
( 
( SELECT flights.destairportid, flights.carrier
  FROM flights
  WHERE flights.originairportid = 10140)
UNION
( SELECT flights.destairportid, flights.carrier
  FROM flights INNER JOIN airportsFromAlbuquerque
  ON flights.originairportid = airportsFromAlbuquerque.x AND flights.carrier=airportsFromAlbuquerque.y)
)
SELECT DISTINCT airports.city as name FROM airportsFromAlbuquerque INNER JOIN airports ON
airportsFromAlbuquerque.x = airports.airportid
order by airports.city;


--2--
WITH RECURSIVE airportsFromAlbuquerque(x,y) AS
( 
( SELECT flights.destairportid, flights.dayofweek
  FROM flights
  WHERE flights.originairportid = 10140)
UNION
( SELECT flights.destairportid, flights.dayofweek
  FROM flights INNER JOIN airportsFromAlbuquerque
  ON flights.originairportid = airportsFromAlbuquerque.x AND flights.dayofweek=airportsFromAlbuquerque.y)
)
SELECT DISTINCT airports.city as name FROM airportsFromAlbuquerque INNER JOIN airports ON
airportsFromAlbuquerque.x = airports.airportid
order by airports.city;


--3--
WITH RECURSIVE AirportsFromAlbuquerque(a,path) AS (
(SELECT flights.destairportid, ARRAY[flights.originairportid,flights.destairportid] FROM
flights WHERE flights.originairportid=10140)
UNION
(
SELECT flights.destairportid, AirportsFromAlbuquerque.path || flights.destairportid FROM
flights, AirportsFromAlbuquerque WHERE
flights.originairportid=AirportsFromAlbuquerque.a AND (NOT (flights.destairportid = ANY (AirportsFromAlbuquerque.path)))
)
) 
SELECT DISTINCT airports.city as name FROM
airports INNER JOIN (
SELECT AirportsFromAlbuquerque.* FROM AirportsFromAlbuquerque INNER JOIN (
SELECT a,count(*) FROM AirportsFromAlbuquerque
GROUP BY AirportsFromAlbuquerque.a
) as temp1 ON AirportsFromAlbuquerque.a=temp1.a AND temp1.count=1
) AS temp ON
temp.a = airports.airportid
order by airports.city;


--4--
WITH RECURSIVE A(path) AS (
(SELECT ARRAY[flights.originairportid,flights.destairportid] FROM flights)
UNION
(SELECT path || flights.destairportid 
FROM flights, A WHERE
flights.originairportid=(SELECT path[array_length(path,1)]) AND (NOT (SELECT path[1])=(SELECT path[array_length(path,1)])) AND 
((NOT (flights.destairportid=ANY(path))) OR flights.destairportid=(SELECT path[1]))
)
) SELECT max(array_length(path,1))-1 AS length FROM A WHERE ((SELECT path[1])=(SELECT path[array_length(path,1)])) AND 10140=ANY(path);


--5--
WITH RECURSIVE A(path) AS (
(SELECT ARRAY[flights.originairportid,flights.destairportid] FROM flights)
UNION
(SELECT path || flights.destairportid 
FROM flights, A WHERE
flights.originairportid=(SELECT path[array_length(path,1)]) AND (NOT (SELECT path[1])=(SELECT path[array_length(path,1)])) AND 
((NOT (flights.destairportid=ANY(path))) OR flights.destairportid=(SELECT path[1]))
)
) SELECT max(array_length(path,1))-1 AS length FROM A WHERE ((SELECT path[1])=(SELECT path[array_length(path,1)]));


--6--
WITH RECURSIVE A(path) AS (
(SELECT ARRAY[flights.originairportid,flights.destairportid] FROM
flights, airports AS a1, airports AS a2 WHERE
a1.airportid=flights.originairportid AND a2.airportid=flights.destairportid AND a1.state <> a2.state)
UNION
(SELECT path||flights.destairportid
FROM flights, airports as a1, airports as a2,A WHERE
a1.airportid=flights.originairportid AND a2.airportid=flights.destairportid AND a1.state <> a2.state AND
flights.originairportid=(SELECT path[array_length(path,1)]) AND (NOT flights.destairportid=ANY(path))
)
)
SELECT count(*) as count FROM
(SELECT A.* FROM A, airports AS a1, airports AS a2 WHERE 
(a1.airportid = (SELECT path[1]) AND a2.airportid=(SELECT path[array_length(path,1)])) AND ((SELECT lower(a1.city))='albuquerque' AND (SELECT lower(a2.city))='chicago')
) as temp;


--7--
WITH RECURSIVE A(path) AS (
(SELECT ARRAY[flights.originairportid,flights.destairportid] FROM
flights, airports AS a1, airports AS a2 WHERE
a1.airportid=flights.originairportid AND a2.airportid=flights.destairportid AND a1.state <> a2.state)
UNION
(SELECT path||flights.destairportid
FROM flights, airports as a1, airports as a2,A WHERE
a1.airportid=flights.originairportid AND a2.airportid=flights.destairportid AND a1.state <> a2.state AND
flights.originairportid=(SELECT path[array_length(path,1)]) AND (NOT flights.destairportid=ANY(path))
)
)
SELECT count(*) AS count FROM
(SELECT temp.* FROM 
(SELECT A.* FROM A, airports AS a1, airports AS a2 WHERE 
(a1.airportid = (SELECT path[1]) AND a2.airportid=(SELECT path[array_length(path,1)])) AND ((SELECT lower(a1.city))='albuquerque' AND (SELECT lower(a2.city))='chicago')
) as temp, airports WHERE 
(SELECT lower(airports.city))='washington' AND airports.airportid=ANY(path)) as temp
;


--8--
WITH RECURSIVE A(path) AS
(
(SELECT ARRAY[flights.originairportid,flights.destairportid]
FROM flights
)
UNION
(SELECT path||flights.destairportid
FROM flights, A WHERE
flights.originairportid=(SELECT path[array_length(path,1)]) AND (NOT flights.destairportid=ANY(path))
)
)
SELECT a1.city as name1, a2.city as name2 FROM
(SELECT DISTINCT a1.airportid as i1, a2.airportid as i2 FROM
airports as a1, airports as a2 WHERE
a1.airportid <> a2.airportid
EXCEPT
SELECT DISTINCT a1.airportid, a2.airportid FROM 
A, airports as a1, airports as a2 WHERE
(a1.airportid = (SELECT path[1]) AND a2.airportid = (SELECT path[array_length(path,1)]))) as temp, airports as a1, airports as a2
WHERE a1.airportid=i1 AND a2.airportid=i2
ORDER BY a1.city, a2.city
;


--9--
SELECT days AS day, delay FROM
(SELECT temp.days, COALESCE(delay,0) as delay FROM
(SELECT temp2.days, temp.delay FROM
(SELECT days FROM generate_series(1,31) as temp2(days)) as temp2 LEFT OUTER JOIN
(SELECT dayofmonth as day, sum(delay) as delay FROM
(SELECT *,departuredelay+arrivaldelay as delay FROM
flights WHERE
originairportid=10140) as temp
GROUP BY dayofmonth) as temp ON
temp2.days=temp.day) as temp) as temp
ORDER BY delay, days;


--10--
SELECT i1 AS name FROM
(SELECT i1, count(*) as count FROM
(SELECT a1.city as i1, a2.city as i2 FROM
flights, airports AS a1, airports AS a2 WHERE
a1.airportid = flights.originairportid AND a2.airportid=flights.destairportid AND a1.state=a2.state AND (SELECT lower(a1.state)='new york')) as temp
GROUP BY i1) as temp
WHERE temp.count=(SELECT count(*) FROM (SELECT DISTINCT city FROM airports WHERE (SELECT lower(state)='new york')) as temp2)-1
ORDER BY i1;


--11--
WITH RECURSIVE A(delay,path) AS(
(SELECT flights.departuredelay+flights.arrivaldelay, ARRAY[flights.originairportid,flights.destairportid] FROM flights
)
UNION
(SELECT flights.departuredelay+flights.arrivaldelay, path||flights.destairportid FROM
flights, A WHERE
flights.originairportid=(SELECT path[array_length(path,1)]) AND (path[1] <> path[array_length(path,1)]) AND
((NOT flights.destairportid=ANY(path)) OR flights.destairportid=path[1]) AND (flights.departuredelay+flights.arrivaldelay)>=delay
)
)
SELECT DISTINCT a1.city as name1, a2.city as name2 FROM A, airports AS a1, airports AS a2 WHERE
a1.airportid=path[1] AND a2.airportid=path[array_length(path,1)]
ORDER BY a1.city, a2.city;


--12--
WITH RECURSIVE graph(paths) AS(
(SELECT ARRAY[a1.authorid,a2.authorid] FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid
)
UNION
(SELECT paths||a2.authorid FROM
graph, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
)
)
SELECT authorid, COALESCE(length,-1) as length FROM
(SELECT temp2.authorid as authorid, temp.length as length FROM
(SELECT authorid FROM authordetails) as temp2 LEFT OUTER JOIN
(SELECT author2 as authorid, min(length)-1 as length FROM
(SELECT paths[array_length(paths,1)] AS author2, paths, array_length(paths,1) AS length FROM
(SELECT DISTINCT * FROM graph WHERE paths[1]=1235) AS temp) AS temp
GROUP BY author2) as temp ON
temp.authorid=temp2.authorid) as temp
WHERE authorid<>1235
ORDER BY length DESC, authorid;


--13--
WITH RECURSIVE graph(paths) AS(
(SELECT ARRAY[a1.authorid,a2.authorid] FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND (a2.age>35 OR a2.authorid=2826) 
AND a1.authorid=1558
)
UNION
(SELECT paths||a2.authorid FROM
graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
AND (SELECT paths[array_length(paths,1)])<>2826 AND ((SELECT paths[array_length(paths,1)])=a1.authorid) AND ((a2.age>35 AND a1.gender<>a2.gender) OR a2.authorid=2826)
)
)
SELECT
CASE 
	WHEN count=0 THEN 
	(SELECT CASE
		WHEN count=0 THEN -1
		ELSE 0
	END FROM
	(
	WITH RECURSIVE graph1(paths) AS(
	(SELECT ARRAY[a1.authorid,a2.authorid] FROM
	authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND a1.authorid=1558
	)
	UNION
	(SELECT paths||a2.authorid FROM
	graph1, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
	AND (SELECT paths[array_length(paths,1)])<>2826
	)
	)
	SELECT count(*) FROM graph1 WHERE (SELECT paths[1])=1558 AND (SELECT paths[array_length(paths,1)]=2826)
	
	) as temp1
	)
	ELSE count
END 
FROM
(SELECT count(*) as count FROM
(SELECT * FROM graph) as temp
WHERE (SELECT paths[1])=1558 AND (SELECT paths[array_length(paths,1)])=2826) as temp;


--14--
WITH RECURSIVE graph(own_papers,paths) AS(
(SELECT 
CASE 
WHEN a2.authorid=102 THEN ARRAY[]::integer[]
ELSE ARRAY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid) 
END
,ARRAY[a1.authorid,a2.authorid] FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND a1.authorid=704
)
UNION
(SELECT  
CASE 
WHEN a2.authorid=102 THEN own_papers
ELSE ARRAY(SELECT DISTINCT element FROM unnest(own_papers || ARRAY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) AS temp2(element))
END
, paths||a2.authorid FROM
graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT (SELECT paths[array_length(paths,1)])=102) 
AND (NOT a2.authorid=ANY(paths))
)
)
SELECT
CASE 
	WHEN count=0 THEN 
	(SELECT CASE
		WHEN count=0 THEN -1
		ELSE 0
	END FROM
	(
	WITH RECURSIVE graph1(paths) AS(
	(SELECT ARRAY[a1.authorid,a2.authorid] FROM
	authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid
	)
	UNION
	(SELECT paths||a2.authorid FROM
	graph1, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
	)
	)
	SELECT count(*) FROM graph1 WHERE (SELECT paths[1])=704 AND (SELECT paths[array_length(paths,1)]=102)
	
	) as temp1
	)
	ELSE count
END 
FROM
(SELECT count(*) FROM
(SELECT * FROM graph WHERE (((SELECT paths[array_length(paths,1)]=102) AND (ARRAY(SELECT * FROM papers126) && own_papers)) OR (paths[2]=102)) ) AS temp) AS temp;


--15--
SELECT count(*) FROM
(SELECT * FROM
(WITH RECURSIVE citation_path(paths,citations) AS
(
(SELECT ARRAY[a1.authorid,a2.authorid],
(WITH RECURSIVE graph(paths) AS
(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist WHERE (NOT paperid1=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
UNION
(SELECT paths||paperid2 FROM graph,citationlist WHERE paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths)))
)) 
SELECT SUM(count) FROM
(SELECT count(*),paths[array_length(paths,1)] AS paper FROM
(SELECT * FROM graph WHERE (SELECT paths[array_length(paths,1)])=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) as temp
GROUP BY paths[array_length(paths,1)]) as temp)
FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND a1.authorid=1745
)
UNION
(SELECT paths||a2.authorid,  
(WITH RECURSIVE graph(paths) AS
(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist WHERE (NOT paperid1=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
UNION
(SELECT paths||paperid2 FROM graph,citationlist WHERE paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths)))
)) 
SELECT SUM(count) FROM
(SELECT count(*),paths[array_length(paths,1)] AS paper FROM
(SELECT * FROM graph WHERE (SELECT paths[array_length(paths,1)])=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) as temp
GROUP BY paths[array_length(paths,1)]) as temp)
FROM
citation_path, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths)) AND
(NOT (SELECT paths[array_length(paths,1)])=456) AND 
((
citations < (WITH RECURSIVE graph(paths) AS
(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist WHERE (NOT paperid1=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
UNION
(SELECT paths||paperid2 FROM graph,citationlist WHERE paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths)))
)) 
SELECT SUM(count) FROM
(SELECT count(*),paths[array_length(paths,1)] AS paper FROM
(SELECT * FROM graph WHERE (SELECT paths[array_length(paths,1)])=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) as temp
GROUP BY paths[array_length(paths,1)]) as temp)
) OR a2.authorid=456)
)
) SELECT * FROM citation_path) as temp1
UNION
(WITH RECURSIVE citation_path(paths,citations) AS
(
(SELECT ARRAY[a1.authorid,a2.authorid],
(WITH RECURSIVE graph(paths) AS
(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist WHERE (NOT paperid1=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
UNION
(SELECT paths||paperid2 FROM graph,citationlist WHERE paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths)))
)) 
SELECT SUM(count) FROM
(SELECT count(*),paths[array_length(paths,1)] AS paper FROM
(SELECT * FROM graph WHERE (SELECT paths[array_length(paths,1)])=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) as temp
GROUP BY paths[array_length(paths,1)]) as temp)
FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND a1.authorid=1745
)
UNION
(SELECT paths||a2.authorid,  
(WITH RECURSIVE graph(paths) AS
(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist WHERE (NOT paperid1=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
UNION
(SELECT paths||paperid2 FROM graph,citationlist WHERE paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths)))
)) 
SELECT SUM(count) FROM
(SELECT count(*),paths[array_length(paths,1)] AS paper FROM
(SELECT * FROM graph WHERE (SELECT paths[array_length(paths,1)])=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) as temp
GROUP BY paths[array_length(paths,1)]) as temp)
FROM
citation_path, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths)) AND
(NOT (SELECT paths[array_length(paths,1)])=456) AND 
((
citations > (WITH RECURSIVE graph(paths) AS
(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist WHERE (NOT paperid1=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
UNION
(SELECT paths||paperid2 FROM graph,citationlist WHERE paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths)))
)) 
SELECT SUM(count) FROM
(SELECT count(*),paths[array_length(paths,1)] AS paper FROM
(SELECT * FROM graph WHERE (SELECT paths[array_length(paths,1)])=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) as temp
GROUP BY paths[array_length(paths,1)]) as temp)
) OR a2.authorid=456)
)
) SELECT * FROM citation_path)
) as temp WHERE (SELECT paths[array_length(paths,1)]=456);


--16--
SELECT authorid FROM
(SELECT authorid, COALESCE(number_of_authors,0) AS number_of_authors FROM
(SELECT authordetails.authorid, number_of_authors FROM
(SELECT authorid, array_length(authors,1) AS number_of_authors FROM
(SELECT temp1.authorid, ARRAY(
SELECT * FROM (SELECT * FROM unnest(temp1.all_authors) EXCEPT SELECT * FROM unnest(temp2.same_paper_authors)) AS temp3) AS authors FROM
(SELECT authorid, authors AS all_authors FROM
(SELECT authorid, ARRAY(SELECT DISTINCT temp2.authorid FROM
(SELECT DISTINCT paths[array_length(paths,1)] as paper_cited FROM
(WITH RECURSIVE graph(paths) AS(
(SELECT ARRAY[paperid1,paperid2] FROM citationlist WHERE paperid1=ANY(SELECT paperid FROM authorpaperlist WHERE authorpaperlist.authorid=authordetails.authorid))
UNION
(SELECT paths||paperid2 FROM graph,citationlist WHERE paperid1=(SELECT paths[array_length(paths,1)]) AND (NOT paperid2=ANY(paths))
))SELECT * FROM graph) AS temp) AS temp1 INNER JOIN authorpaperlist AS temp2 ON
temp1.paper_cited=temp2.paperid AND (NOT authordetails.authorid=temp2.authorid)) AS authors FROM
authordetails) AS temp WHERE array_length(authors,1)>0) AS temp1 INNER JOIN 
(SELECT authorid, ARRAY(SELECT authorpaperlist.authorid FROM authorpaperlist WHERE authorpaperlist.paperid=ANY(SELECT paperid FROM authorpaperlist WHERE
authorpaperlist.authorid=authordetails.authorid) AND authorpaperlist.authorid <> authordetails.authorid) AS same_paper_authors FROM
authordetails) AS temp2 ON
temp1.authorid=temp2.authorid) AS temp) AS temp RIGHT OUTER JOIN authordetails ON
temp.authorid=authordetails.authorid) AS temp) AS temp
ORDER BY number_of_authors DESC, authorid
LIMIT 10;


--17--
SELECT authorid FROM
(SELECT authorid, COALESCE(sum,0) AS sum FROM
(SELECT authorid,
(SELECT SUM(count) FROM
(SELECT neighbours, count(*) as count FROM
(SELECT DISTINCT neighbours, paperid, paths[1] AS cited_by FROM
(SELECT DISTINCT neighbours, paperid FROM 
(SELECT DISTINCT paths[4] AS neighbours FROM
(WITH RECURSIVE graph(paths) AS(
(SELECT ARRAY[a1.authorid,a2.authorid] FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND a1.authorid=authordetails.authorid
)
UNION
(SELECT paths||a2.authorid FROM
graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
AND array_length(paths,1)<=4
)
) SELECT * FROM graph WHERE array_length(paths,1)=4 AND (NOT paths[4]=ANY(SELECT paths[array_length(paths,1)] FROM graph WHERE array_length(paths,1)<4))) AS temp)
 AS temp1 INNER JOIN authorpaperlist ON
neighbours=authorid) as temp1 INNER JOIN papers_graph ON
(SELECT paths[array_length(paths,1)])=paperid) AS temp
GROUP BY neighbours) AS temp) FROM
authordetails) AS temp) AS temp
ORDER BY sum DESC, authorid
LIMIT 10;


--18--
WITH RECURSIVE graph(paths) AS(
(SELECT ARRAY[a1.authorid,a2.authorid] FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid
)
UNION
(SELECT paths||a2.authorid FROM
graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
)
)
SELECT
CASE 
	WHEN count=0 THEN 
	(SELECT CASE
		WHEN count=0 THEN -1
		ELSE 0
	END FROM
	(
	WITH RECURSIVE graph1(paths) AS(
	(SELECT ARRAY[a1.authorid,a2.authorid] FROM
	authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid
	)
	UNION
	(SELECT paths||a2.authorid FROM
	graph1, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
	)
	)
	SELECT count(*) FROM graph1 WHERE (SELECT paths[1])=3552 AND (SELECT paths[array_length(paths,1)]=321)
	
	) as temp1
	)
	ELSE count
END 
FROM
(SELECT count(*) as count FROM
(SELECT DISTINCT * FROM graph WHERE (SELECT paths[1])=3552 AND (SELECT paths[array_length(paths,1)])=321 AND (1436=ANY(paths) OR 562=ANY(paths) OR 921=ANY(paths)))
as temp) as temp;


--19--
WITH RECURSIVE graph(cities,own_papers,cited_papers,paths) AS(
(SELECT 
ARRAY[a2.city]
,
ARRAY(
SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid
), 
ARRAY(
SELECT DISTINCT paperid2 FROM
(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid) AS temp1 INNER JOIN citationlist ON
citationlist.paperid1=temp1.paperid 
),
ARRAY[a1.authorid,a2.authorid]
FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND a1.authorid=3552
)
UNION
(SELECT 
cities || a2.city
,
ARRAY(SELECT DISTINCT element FROM unnest(own_papers || ARRAY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) AS temp3(element)),
ARRAY(SELECT DISTINCT element FROM unnest(cited_papers || ARRAY(SELECT DISTINCT paperid2 FROM
(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid) AS temp1 INNER JOIN citationlist ON
citationlist.paperid1=temp1.paperid)) AS temp3(element)),
paths||a2.authorid
FROM
graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT (SELECT paths[array_length(paths,1)])=321) AND (NOT a2.authorid=ANY(paths)) AND
(((NOT (own_papers && (ARRAY(
SELECT DISTINCT paperid2 FROM
(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid) AS temp1 INNER JOIN citationlist ON
citationlist.paperid1=temp1.paperid 
)))) AND (NOT a2.city=ANY(cities)) AND (NOT (ARRAY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid) && cited_papers))
) 
OR a2.authorid=321)
)
)
SELECT
CASE 
	WHEN count=0 THEN 
	(SELECT CASE
		WHEN count=0 THEN -1
		ELSE 0
	END FROM
	(
	WITH RECURSIVE graph(paths) AS(
	(SELECT ARRAY[a1.authorid,a2.authorid] FROM
	authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid
	)
	UNION
	(SELECT paths||a2.authorid FROM
	graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
	)
	)
	SELECT count(*) FROM graph WHERE (SELECT paths[1])=3552 AND (SELECT paths[array_length(paths,1)]=321)
	
	) as temp1
	)
	ELSE count
END 
FROM
(SELECT count(*) as count FROM
(SELECT * FROM graph) as temp
WHERE (SELECT paths[1])=3552 AND (SELECT paths[array_length(paths,1)])=321) as temp;


--20--
WITH RECURSIVE graph(own_papers,cited_papers,paths) AS(
(SELECT 
ARRAY(
SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid
), 
ARRAY(
SELECT papers_graph.paths[array_length(papers_graph.paths,1)] FROM papers_graph WHERE (SELECT papers_graph.paths[1]=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
),
ARRAY[a1.authorid,a2.authorid]
FROM
authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid AND a1.authorid=3552
)
UNION
(SELECT
ARRAY(SELECT DISTINCT element FROM unnest(own_papers || ARRAY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) AS temp3(element)),
ARRAY(SELECT DISTINCT element FROM unnest(cited_papers || ARRAY(SELECT papers_graph.paths[array_length(papers_graph.paths,1)] FROM papers_graph WHERE (SELECT papers_graph.paths[1]=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))))
 AS temp3(element)),
paths||a2.authorid
FROM
graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT (SELECT paths[array_length(paths,1)])=321) AND (NOT a2.authorid=ANY(paths)) AND
(((NOT (own_papers && (ARRAY(
SELECT papers_graph.paths[array_length(papers_graph.paths,1)] FROM papers_graph WHERE (SELECT papers_graph.paths[1]=ANY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid))
)))) AND (NOT (ARRAY(SELECT paperid FROM authorpaperlist WHERE authorid=a2.authorid)) && cited_papers)) OR a2.authorid=321)
))
SELECT
CASE 
	WHEN count=0 THEN 
	(SELECT CASE
		WHEN count=0 THEN -1
		ELSE 0
	END FROM
	(
	WITH RECURSIVE graph(paths) AS(
	(SELECT ARRAY[a1.authorid,a2.authorid] FROM
	authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE a1.authorid=a3.authorid AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND a1.authorid<>a2.authorid
	)
	UNION
	(SELECT paths||a2.authorid FROM
	graph, authordetails AS a1, authordetails AS a2, authorpaperlist AS a3, authorpaperlist AS a4
	WHERE ((SELECT paths[array_length(paths,1)])=a3.authorid) AND a2.authorid=a4.authorid AND a3.paperid=a4.paperid AND (NOT a2.authorid=ANY(paths))
	)
	)
	SELECT count(*) FROM graph WHERE (SELECT paths[1])=3552 AND (SELECT paths[array_length(paths,1)]=321)
	
	) as temp1
	)
	ELSE count
END 
FROM
(SELECT count(*) as count FROM
(SELECT * FROM graph) as temp
WHERE (SELECT paths[1])=3552 AND (SELECT paths[array_length(paths,1)])=321) as temp;


--21--



--22--



--CLEANUP--
DROP VIEW papers126;
DROP VIEW papers_graph;
