--1--
select match_id, player_name, team_name, num_wickets
from player, team, (select p.match_id, player_id, team_id, num_wickets
from player_match as p INNER JOIN (select match_id, bowler, count(bowler) as num_wickets from (
select b.match_id, bowler, b.over_id, b.ball_id, kind_out
from ball_by_ball as b INNER JOIN wicket_taken as w
on b.ball_id = w.ball_id and b.over_id = w.over_id and b.match_id=w.match_id and b.innings_no=w.innings_no
where kind_out=1 or kind_out=2 or kind_out=4 or kind_out=6 or kind_out=7 or kind_out=8
group by b.match_id, bowler, b.over_id, b.ball_id, kind_out, b.innings_no
) as foo
group by bowler, foo.match_id) as temp_table
ON p.match_id = temp_table.match_id AND p.player_id = temp_table.bowler where num_wickets>=5
order by num_wickets desc, player_id, team_id) as final
where player.player_id=final.player_id and team.team_id=final.team_id
order by num_wickets desc, player_name, team_name;

--2--
select player_name, num_matches from
player, (
select player_id, count(man_of_the_match) as num_matches from
(select * from
player_match as p INNER JOIN match as m ON
p.match_id = m.match_id and p.player_id = m.man_of_the_match and NOT p.team_id=m.match_winner) as temp
GROUP BY player_id) as temp1
where player.player_id = temp1.player_id
ORDER BY num_matches desc, player_name
LIMIT 3;

--3--
select player_name from
(select fielders,count(fielders) as num_catches
from wicket_taken as w JOIN match as m 
ON w.match_id=m.match_id
where kind_out=1 and (SELECT EXTRACT(YEAR FROM match_date)=2012)
group by fielders) as temp JOIN player on
temp.fielders = player.player_id
order by num_catches desc, player_name
limit 1;

--4--
SELECT season_year, r.player_name, num_matches FROM
(select temp1.season_year, purple_cap, count(temp1.match_id) as num_matches
from (select temp.match_id, season_year, player_id
from (
select match_id,(SELECT EXTRACT (YEAR FROM match_date)) as season_year
from match
group by season_year,match_id
order by season_year,match_id
)
as temp INNER JOIN player_match
ON temp.match_id = player_match.match_id) as temp1, (select season_year, purple_cap
from season) as temp2
where temp1.season_year=temp2.season_year and temp1.player_id=temp2.purple_cap
group by temp1.season_year, purple_cap
order by temp1.season_year) as l INNER JOIN player as r ON
l.purple_cap=r.player_id
ORDER BY season_year;

--5--
SELECT r.player_name FROM
(SELECT DISTINCT l.striker as player_id FROM
(SELECT l.match_id, l.team_id, r.striker, r.runs FROM
(SELECT match_id,
CASE
	WHEN team_1=match_winner THEN team_2
	WHEN team_2=match_winner THEN team_1
END team_id,
win_id
FROM match
WHERE (not (win_id=3 OR win_id=4))) AS l INNER JOIN
(SELECT l.match_id, l.team_batting, l.striker, SUM(l.runs_scored) as runs FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.team_batting, l.striker, r.runs_scored
FROM
ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))
) as l
GROUP BY l.match_id, l.team_batting, l.striker) as r
ON l.match_id=r.match_id AND l.team_id=r.team_batting AND r.runs>50) as l) as l INNER JOIN player as r
ON l.player_id=r.player_id
ORDER BY r.player_name;

--6--
SELECT l.season_year, l.team_name, l.rank FROM
(
SELECT l.season_year, l.team_name, l.num_players, 
RANK () OVER (
PARTITION BY l.season_year
ORDER BY l.num_players DESC, l.team_name
) rank
FROM
(SELECT l.season_year, r.team_name, l.num_players FROM
((SELECT l.season_year, l.team_id, count(*) as num_players
FROM
(SELECT DISTINCT season_year, team_id, player_id
FROM
(SELECT (SELECT EXTRACT (YEAR FROM match_date)) as season_year, match_id
FROM match) as l
INNER JOIN
(SELECT match_id, player_id, team_id
FROM player_match) AS r
ON
l.match_id = r.match_id) as l INNER JOIN player as r ON
l.player_id = r.player_id AND r.batting_hand=1 AND (NOT r.country_id=1)
GROUP BY l.season_year, l.team_id
)) as l INNER JOIN team as r ON
l.team_id = r.team_id) as l) as l
WHERE l.rank<=5
ORDER BY l.season_year, l.team_name;

--7--
select team_name from
(
select match_winner, count(match_winner) as co
from match
where (SELECT EXTRACT (YEAR FROM match_date)=2009)
group by match_winner
)
as temp INNER JOIN team
ON match_winner = team_id
ORDER BY co desc, team_name;

--8--
select l.team_name, r.player_name, l.runs
from (
select l.team_name, r.striker, r.runs
from team as l INNER JOIN
(
SELECT l.team_batting, r.striker, l.runs
FROM (
SELECT team_batting,max(runs) as runs from
(
SELECT team_batting, striker, sum(runs_scored) as runs from
(
SELECT m.match_id, ball.over_id, ball.ball_id, ball.innings_no, ball.team_batting, ball.striker, ball.runs_scored FROM
(select * from match
where (SELECT EXTRACT (YEAR FROM match_date)=2010)) as m INNER JOIN
(
SELECT ball.match_id, ball.over_id, ball.ball_id, ball.innings_no, ball.team_batting, ball.striker, bat.runs_scored FROM
ball_by_ball as ball INNER JOIN batsman_scored as bat
ON ball.match_id=bat.match_id and ball.over_id=bat.over_id and ball.ball_id=bat.ball_id and ball.innings_no=bat.innings_no and (not (ball.innings_no=3 or ball.innings_no=4))
) as ball
ON m.match_id = ball.match_id
)
as temp
group by team_batting,striker
)
as temp1
group by team_batting
) as l INNER JOIN
(
SELECT team_batting, striker, sum(runs_scored) as runs from
(
SELECT m.match_id, ball.over_id, ball.ball_id, ball.innings_no, ball.team_batting, ball.striker, ball.runs_scored FROM
(select * from match
where (SELECT EXTRACT (YEAR FROM match_date)=2010)) as m INNER JOIN
(
SELECT ball.match_id, ball.over_id, ball.ball_id, ball.innings_no, ball.team_batting, ball.striker, bat.runs_scored FROM
ball_by_ball as ball INNER JOIN batsman_scored as bat
ON ball.match_id=bat.match_id and ball.over_id=bat.over_id and ball.ball_id=bat.ball_id and ball.innings_no=bat.innings_no and (not (ball.innings_no=3 or ball.innings_no=4))
) as ball
ON m.match_id = ball.match_id
)
as temp
group by team_batting,striker
)
as r
ON l.team_batting = r.team_batting and l.runs=r.runs
) as r
on l.team_id = r.team_batting
) as l INNER JOIN player as r ON
l.striker=r.player_id
order by l.team_name, r.player_name;


--9--
SELECT l.team_name, l.opponent_team_name, l.number_of_sixes FROM
(
SELECT l.match_id, l.innings_no, l.team_name, r.team_name as opponent_team_name, l.number_of_sixes FROM
(
SELECT l.match_id, l.innings_no, r.team_name, l.team_bowling, l.number_of_sixes FROM
(
SELECT l.match_id, l.innings_no, l.team_batting, l.team_bowling, count(*) as number_of_sixes FROM
(
SELECT m.match_id, ball.over_id, ball.ball_id, ball.innings_no, ball.team_batting, ball.team_bowling, ball.runs_scored FROM
(select * from match
where (SELECT EXTRACT (YEAR FROM match_date)=2008)) as m INNER JOIN
(
SELECT ball.match_id, ball.over_id, ball.ball_id, ball.innings_no, ball.team_batting, ball.team_bowling, bat.runs_scored FROM
ball_by_ball as ball INNER JOIN batsman_scored as bat
ON ball.match_id=bat.match_id and ball.over_id=bat.over_id and ball.ball_id=bat.ball_id and ball.innings_no=bat.innings_no and (not (ball.innings_no=3 or ball.innings_no=4))
) as ball
ON m.match_id = ball.match_id
) as l
WHERE l.runs_scored=6
group by l.match_id, l.innings_no, l.team_batting, l.team_bowling
) as l INNER JOIN team as r
ON l.team_batting=r.team_id
) as l INNER JOIN team as r
ON l.team_bowling=r.team_id
ORDER BY l.number_of_sixes desc, l.team_name, opponent_team_name
LIMIT 3
) as l;


--10--
SELECT r.bowling_skill, l.player_name, round(l.batting_avg,2) as batting_avg FROM
(SELECT * FROM
(SELECT l.bowling_skill, l.player_name, l.batting_avg, RANK () OVER(
PARTITION BY bowling_skill
ORDER BY batting_avg DESC, l.player_name) 
FROM
(SELECT r.player_name, l.bowling_skill, l.batting_avg FROM
(SELECT l.*, r.batting_avg FROM
(SELECT l.* FROM
(SELECT l.bowler, l.wickets, r.bowling_skill FROM
(SELECT bowler, count(*) as wickets FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.bowler, kind_out FROM
ball_by_ball as l INNER JOIN wicket_taken as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))
AND (kind_out=1 OR kind_out=2 OR kind_out=4 OR kind_out=6 OR kind_out=7 OR kind_out=8)) as l
GROUP BY bowler) as l INNER JOIN player as r
ON l.bowler=r.player_id) as l INNER JOIN (SELECT bowling_skill, avg(wickets) as avg_wickets FROM
(SELECT l.bowler, l.wickets, r.bowling_skill FROM
(SELECT bowler, count(*) as wickets FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.bowler, kind_out FROM
ball_by_ball as l INNER JOIN wicket_taken as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))
AND (kind_out=1 OR kind_out=2 OR kind_out=4 OR kind_out=6 OR kind_out=7 OR kind_out=8)) as l
GROUP BY bowler) as l INNER JOIN player as r
ON l.bowler=r.player_id) AS l
GROUP BY bowling_skill) as r
ON l.bowling_skill=r.bowling_skill AND l.wickets>r.avg_wickets) as l INNER JOIN
(SELECT l.striker, cast(runs as decimal)/r.matches as batting_avg FROM
(SELECT l.striker, SUM(l.runs_scored) as runs FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.striker, r.runs_scored FROM
ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))) as l
GROUP BY l.striker) as l INNER JOIN
(SELECT l.striker, count(*) as matches FROM
(SELECT DISTINCT l.striker, match_id FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.striker, r.runs_scored FROM
ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))) as l
) as l
GROUP BY l.striker) as r
ON l.striker=r.striker) as r
ON l.bowler=r.striker) as l INNER JOIN player as r
ON l.bowler=r.player_id) as l) AS l WHERE rank=1) as l INNER JOIN bowling_style as r
ON l.bowling_skill=r.bowling_id
ORDER BY r.bowling_skill;


--11--
SELECT * FROM
(SELECT r.season_year, l.player_name, l.num_wickets, l.runs FROM
(SELECT l.season_id, r.player_name, l.total_wickets as num_wickets, l.runs
FROM
(SELECT l.*, r.total_wickets FROM
(SELECT l.*, r.total_matches FROM
(SELECT * FROM
(SELECT l.season_id, l.striker, sum(l.runs) as runs FROM
(SELECT r.season_id, l.match_id, l.striker, l.runs FROM
(SELECT l.match_id, l.striker, sum(l.runs_scored) as runs FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.striker, r.runs_scored FROM
ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))
) as l
GROUP BY l.match_id, l.striker) as l INNER JOIN match as r
ON l.match_id=r.match_id) as l
GROUP BY l.season_id, l.striker) as l
WHERE l.runs>=150) as l INNER JOIN (SELECT * FROM
(SELECT l.season_id, l.player_id, count(*) as total_matches FROM
(SELECT r.season_id, l.match_id, l.player_id FROM
player_match as l INNER JOIN match as r
ON l.match_id=r.match_id) as l
GROUP BY l.season_id, l.player_id) as l
WHERE l.total_matches>=10) as r
ON l.season_id=r.season_id AND l.striker=r.player_id) as l INNER JOIN (SELECT * FROM
(SELECT l.season_id, l.bowler, sum(l.total_wickets) as total_wickets FROM
(SELECT r.season_id, l.match_id, l.bowler, l.total_wickets FROM
(SELECT l.match_id, l.bowler, count(*) as total_wickets FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.bowler, r.kind_out
FROM
ball_by_ball as l INNER JOIN wicket_taken as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND
(r.kind_out=1 OR r.kind_out=2 OR r.kind_out=4 OR r.kind_out=6 OR r.kind_out=7 OR r.kind_out=8) AND (NOT (l.innings_no=3 OR l.innings_no=4))
) as l
GROUP BY l.match_id, l.bowler) AS l INNER JOIN match as r
ON l.match_id = r.match_id) as l
GROUP BY l.season_id, l.bowler) as l
WHERE l.total_wickets>=5) as r
ON l.season_id=r.season_id AND l.striker=r.bowler) as l INNER JOIN (SELECT player_id, player_name FROM
player
WHERE player.batting_hand=1) as r
ON l.striker=r.player_id) as l INNER JOIN season as r
ON l.season_id = r.season_id) as l
ORDER BY l.num_wickets DESC, l.runs DESC, l.player_name;

--12--
SELECT l.match_id, l.player_name, l.team_name, l.wickets AS num_wickets, r.season_year FROM
(SELECT * FROM
(SELECT *, RANK () OVER(
ORDER BY wickets DESC, player_name, match_id
) FROM
(SELECT l.season_id, l.match_id, r.team_name, l.player_name, l.wickets FROM
(SELECT r.season_id, l.* FROM
(SELECT l.match_id,l.team_bowling, r.player_name, l.wickets FROM
(SELECT l.match_id,l.team_bowling, l.bowler, count(*) as wickets FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.team_bowling, l.bowler FROM
ball_by_ball as l INNER JOIN wicket_taken as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))
AND (kind_out=1 OR kind_out=2 OR kind_out=4 OR kind_out=6 OR kind_out=7 OR kind_out=8)) as l
GROUP BY l.match_id,l.team_bowling, l.bowler) as l INNER JOIN player as r
ON l.bowler=r.player_id) as l INNER JOIN match as r
ON l.match_id=r.match_id) as l INNER JOIN team as r
ON l.team_bowling=r.team_id)
 as l) as l WHERE rank=1) AS l INNER JOIN season as r
ON l.season_id=r.season_id;

--13--
SELECT player_name FROM
(SELECT player_id, count_seasons FROM
(SELECT player_id, COUNT(*) as count_seasons FROM
(SELECT DISTINCT season_id, player_id
FROM
(SELECT season_id, match_id
FROM match) as l INNER JOIN (SELECT match_id, player_id
FROM player_match) as r
ON l.match_id=r.match_id) AS l
GROUP BY player_id) as l
WHERE count_seasons = (SELECT max(count_seasons) FROM
(SELECT player_id, COUNT(*) as count_seasons FROM
(SELECT DISTINCT season_id, player_id
FROM
(SELECT season_id, match_id
FROM match) as l INNER JOIN (SELECT match_id, player_id
FROM player_match) as r
ON l.match_id=r.match_id) AS l
GROUP BY player_id) as l)) as l INNER JOIN player as r
ON l.player_id=r.player_id
ORDER BY player_name;

--14--
SELECT l.season_year, l.match_id, l.team_name FROM
(SELECT *, RANK () OVER
(PARTITION BY season_year
ORDER BY l.number_of_batsmen DESC, l.team_name, l.match_id
) as rank
FROM
(SELECT r.season_year, l.match_id, l.team_name, l.number_of_batsmen FROM
(SELECT l.season_id, l.match_id, r.team_name, l.number_of_batsmen FROM
(SELECT l.season_id, l.match_id, l.match_winner, count(*) as number_of_batsmen
FROM
(SELECT l.season_id, l.match_id, l.match_winner, r.striker, r.runs
FROM match as l INNER JOIN 
(SELECT l.match_id, l.team_batting, l.striker, sum(l.runs_scored) as runs FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.team_batting, l.striker, r.runs_scored
FROM
ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 AND l.innings_no=4))) as l
GROUP BY l.match_id, l.team_batting, l.striker
HAVING sum(l.runs_scored)>=50) as r
ON l.match_id=r.match_id AND l.match_winner=r.team_batting) as l
GROUP BY l.season_id, l.match_id, l.match_winner) as l INNER JOIN team as r
ON l.match_winner=r.team_id) AS l INNER JOIN season as r
ON l.season_id=r.season_id) as l
) as l
WHERE rank<=3
ORDER BY season_year,rank;

--15--
SELECT r.season_year, l.top_batsman, l.max_runs, l.top_bowler, l.max_wickets FROM
(SELECT l.*, r.top_bowler, r.max_wickets FROM
(SELECT season_id, player_name as top_batsman, runs as max_runs FROM
(SELECT *,
RANK () OVER(
PARTITION BY season_id
ORDER BY player_name
) rank1 FROM
(SELECT l.season_id, r.player_name, l.runs FROM
(SELECT * FROM
(SELECT *,
RANK () OVER(
PARTITION BY season_id
ORDER BY runs DESC
) rank FROM
(SELECT season_id, striker, sum(runs) as runs FROM
(SELECT r.season_id, l.match_id, l.striker, l.runs FROM
(SELECT l.match_id, l.striker, sum(l.runs_scored) as runs FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.striker, r.runs_scored
FROM ball_by_ball as l INNER JOIN batsman_scored as r
ON  l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 AND l.innings_no=4)))
AS l
GROUP BY l.match_id, l.striker) as l INNER JOIN match as r
ON l.match_id=r.match_id) AS l
GROUP BY season_id, striker) as l) as l WHERE rank=2) as l INNER JOIN player as r
ON l.striker=r.player_id) as l) as l WHERE rank1=1) as l INNER JOIN
(SELECT l.season_id, l.player_name as top_bowler, l.wickets as max_wickets FROM
(SELECT *,  
RANK () OVER(
PARTITION BY season_id
ORDER BY player_name
) rank1
FROM
(SELECT l.season_id, r.player_name, l.wickets FROM
(SELECT * FROM
(SELECT *, 
RANK () OVER(
PARTITION BY season_id
ORDER BY wickets DESC
) rank FROM
(SELECT season_id, bowler, sum(wickets) as wickets FROM
(SELECT season_id, l.* FROM
(SELECT l.match_id, l.bowler, count(*) as wickets FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.bowler
FROM ball_by_ball as l INNER JOIN wicket_taken as r
ON  l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 AND l.innings_no=4))
AND (r.kind_out=1 OR r.kind_out=2 OR r.kind_out=4 OR r.kind_out=6 OR r.kind_out=7 OR r.kind_out=8)
) as l
GROUP BY l.match_id, l.bowler) as l INNER JOIN match as r
ON l.match_id=r.match_id) as l
GROUP BY season_id, bowler) as l) as l WHERE rank=2) as l INNER JOIN player as r
ON l.bowler=r.player_id) as l) AS l
WHERE rank1=1) as r
ON l.season_id=r.season_id) as l INNER JOIN season as r
ON l.season_id=r.season_id;

--16--
SELECT team_name FROM
(SELECT r.team_name, l.num_matches FROM
(select match_winner, count(*) as num_matches FROM
(select * from match
WHERE (team_1=(select team_id FROM
team
WHERE team_name='Royal Challengers Bangalore')
OR team_2=(select team_id FROM
team
WHERE team_name='Royal Challengers Bangalore')) AND (NOT match_winner=(select team_id FROM
team
WHERE team_name='Royal Challengers Bangalore'))
AND (SELECT EXTRACT (YEAR FROM match_date)=2008)) as l
GROUP BY match_winner) as l INNER JOIN team as r
ON l.match_winner=r.team_id) as l
ORDER BY num_matches desc, team_name;

--17--
SELECT l.team_name, player_name, count FROM
(SELECT *, rank () over(
PARTITION BY team_name
ORDER BY player_name) rank FROM
(SELECT l.team_name, r.player_name, l.count
FROM
(SELECT r.team_name, l.player_id, l.count
FROM
(SELECT l.team_id, r.player_id, l.count
FROM 
(SELECT team_id, max(count) as count FROM
(SELECT l.team_id, l.man_of_the_match as player_id, count(*) as count FROM
(SELECT l.match_id, r.team_id, l.man_of_the_match FROM
match as l INNER JOIN player_match as r
ON l.match_id=r.match_id AND l.man_of_the_match=r.player_id) as l
GROUP BY l.team_id, player_id) as l
GROUP BY team_id) AS l INNER JOIN
(SELECT l.team_id, l.man_of_the_match as player_id, count(*) as count FROM
(SELECT l.match_id, r.team_id, l.man_of_the_match FROM
match as l INNER JOIN player_match as r
ON l.match_id=r.match_id AND l.man_of_the_match=r.player_id) as l
GROUP BY l.team_id, player_id) as r
ON l.team_id=r.team_id AND l.count=r.count) as l INNER JOIN team as r
ON l.team_id=r.team_id) as l INNER JOIN player as r
ON l.player_id=r.player_id) as l) as l
WHERE rank=1
ORDER BY team_name;

--18--
SELECT player_name FROM
(SELECT *, RANK () OVER(
ORDER BY count DESC, player_name) rank FROM
(SELECT r.player_name, l.count FROM
(SELECT l.* FROM
(SELECT bowler, count(*) as count FROM
(select DISTINCT * from
(select l.match_id, l.over_id, l.bowler, sum(runs_scored) as runs FROM
(select l.match_id, l.over_id, l.ball_id, l.innings_no, l.bowler, r.runs_scored FROM
ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no) as l
GROUP BY l.match_id, l.over_id, l.bowler
ORDER BY l.match_id, l.over_id) as l
WHERE runs>20) as l
GROUP BY bowler) as l INNER JOIN (SELECT player_id,count FROM
(SELECT player_id, count(*) FROM
(select DISTINCT team_id, player_id FROM
(select match_id, player_id ,team_id
FROM player_match) as l
ORDER BY team_id, player_id) as l
GROUP BY player_id) as l
WHERE count>=3) as r
ON l.bowler=r.player_id) as l INNER JOIN player as r
ON l.bowler=r.player_id) as l) as l WHERE rank<=5;

--19--
SELECT r.team_name, l.avg_runs FROM
(SELECT l.team_batting, round(avg(runs),2) as avg_runs FROM
(SELECT l.* FROM
(SELECT match_id, team_batting, sum(runs_scored) as runs FROM
(select l.match_id, l.over_id, l.ball_id, l.innings_no, l.team_batting, r.runs_scored
FROM ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))) as l
GROUP BY match_id, team_batting) as l INNER JOIN match as r
ON l.match_id=r.match_id AND (SELECT EXTRACT (YEAR FROM r.match_date)=2010)) AS l
GROUP BY team_batting) as l INNER JOIN team as r
ON l.team_batting=r.team_id
ORDER BY r.team_name;

--20--
SELECT player_name as player_names FROM
(SELECT *, RANK () OVER(
ORDER BY count DESC, player_name) FROM
(SELECT r.player_name, count FROM
(SELECT player_out, count(*) FROM
(SELECT match_id, over_id, ball_id, player_out, innings_no
FROM wicket_taken
WHERE over_id=1 AND (NOT (innings_no=3 OR innings_no=4))) AS l
GROUP BY player_out) as l INNER JOIN player as r
ON l.player_out=r.player_id) as l) AS l WHERE rank<=10;

--21--
SELECT match_id, team_1_name, team_2_name, match_winner_name, number_of_boundaries FROM
(SELECT *, RANK () OVER(
	ORDER BY number_of_boundaries, match_winner_name, team_1_name, team_2_name
) FROM
(SELECT l.match_id, l.team_1_name, l.team_2_name, r.team_name as match_winner_name, l.boundaries as number_of_boundaries FROM
(SELECT l.match_id, l.team_1_name, r.team_name as team_2_name, l.match_winner, l.boundaries FROM
(SELECT l.match_id, r.team_name as team_1_name, l.team_2, l.match_winner, l.boundaries FROM
(SELECT l.match_id, r.team_1, r.team_2, r.match_winner, l.boundaries FROM
(SELECT match_id, innings_no, team_batting, team_bowling, count(*) as boundaries FROM
(SELECT * FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.team_batting, l.team_bowling, r.runs_scored
FROM ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (l.innings_no=2)) AS l
WHERE (runs_scored=4 OR runs_scored=6)) AS l
GROUP BY match_id, innings_no, team_batting, team_bowling) as l INNER JOIN match AS r
ON l.match_id=r.match_id AND l.team_batting=r.match_winner) as l INNER JOIN team AS r
ON l.team_1 = r.team_id) AS l INNER JOIN team AS r
ON l.team_2=r.team_id) AS l INNER JOIN team AS r
ON l.match_winner=r.team_id) as l) AS l WHERE rank<=3;

--22--
SELECT country_name FROM
(SELECT l.*, r.country_id FROM
(SELECT * FROM
(SELECT *, RANK () OVER(
ORDER BY bowling_avg,player_name)
FROM
(SELECT l.*, r.player_name FROM
(SELECT l.bowler, cast(l.runs as decimal)/r.wickets as bowling_avg
FROM (SELECT l.bowler, sum(runs_scored) as runs
FROM (SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.bowler, r.runs_scored
FROM ball_by_ball as l INNER JOIN batsman_scored as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))) as l
GROUP BY bowler) as l INNER JOIN
(SELECT * FROM
(SELECT bowler, count(*) as wickets FROM
(SELECT l.match_id, l.over_id, l.ball_id, l.innings_no, l.bowler, r.kind_out
FROM ball_by_ball as l INNER JOIN wicket_taken as r
ON l.match_id=r.match_id AND l.over_id=r.over_id AND l.ball_id=r.ball_id AND l.innings_no=r.innings_no AND (NOT (l.innings_no=3 OR l.innings_no=4))
AND (kind_out=1 OR kind_out=2 OR kind_out=4 OR kind_out=6 OR kind_out=7 OR kind_out=8)) as l
GROUP BY bowler) as l WHERE NOT wickets=0) as r
ON l.bowler=r.bowler) as l INNER JOIN player as r
ON l.bowler=r.player_id) as l) as l WHERE rank<=3) as l INNER JOIN player as r
ON l.bowler=r.player_id) as l INNER JOIN country as r
ON l.country_id=r.country_id;
