/* Queries: 
1. https://www.kaggle.com/code/dimarudov/data-analysis-using-sql
2. https://www.kaggle.com/code/arvinthsss/european-football-dive-deep-sql/comments#appreciation
3. https://www.kaggle.com/code/averageali/sql-analyzing-football-data/notebook
*/


# from https://www.kaggle.com/code/arvinthsss/european-football-dive-deep-sql/comments#appreciation
#1: Types of leagues
SELECT id, name FROM league
GROUP BY id, name;

#2: League vs Country Name
SELECT * FROM country;
SELECT league.id, league.name AS leagur_name, country.name AS country_name
FROM league
INNER JOIN country
ON league.id = country.id;

#3: Teams associated with the leagues 
SHOW COLUMNS FROM Team;
SHOW COLUMNS FROM league;
SHOW COLUMNS FROM matches;

SELECT Team.team_long_name, Team.team_short_name, league.name, league.country_id, country.name
FROM matches
INNER JOIN Team
ON matches.home_team_api_id = Team.team_api_id
INNER JOIN league
ON matches.league_id = league.id
INNER JOIN country
ON league.country_id = country.id;

#4: Players info.  only these two tables, 
SELECT * FROM player;
SELECT * FROM player_attributes;

#5: Home Team Info.
SELECT match_api_id, home_team_api_id, home_team_goal, team_long_name, team_short_name
FROM matches
INNER JOIN Team
ON matches.home_team_api_id = Team.team_api_id
ORDER BY match_api_id;

#6: Away Team Info.
SELECT * FROM matches;
SELECT match_api_id, away_team_api_id, away_team_goal, team_long_name 
FROM matches
INNER JOIN Team
ON matches.away_team_api_id = Team.team_api_id
ORDER BY match_api_id;

# the following are too complex at this moment 3/5/2024
#7: detailed match-by-match info. 
#8: Goals scored by home team vs away team Season on Season
#9: Total Games played by team

#10: Matches won by Teams Season on Season
WITH matchestest AS
(
SELECT
matches.season,
matches.league_id,
SUM(matches.home_team_goal) AS home_goals,
SUM(matches.away_team_goal) AS away_goals
FROM matches
GROUP BY
matches.season,
matches.league_id
)
SELECT
matchestest.season,
league.name AS league_name,
matchestest.home_goals,
matchestest.away_goals
FROM
matchestest
INNER JOIN
league ON matchestest.league_id = league.id;


# from https://www.kaggle.com/code/dimarudov/data-analysis-using-sql
#11: a specific country (league) detailed matches
SELECT 
	matches.id, country.name, League.name AS league_name, season, stage, 
    date, TeamA.team_long_name AS home_team, TeamB.team_long_name AS away_team, home_team_goal, away_team_goal                                        
FROM matches
INNER JOIN country on country.id = matches.country_id
INNER JOIN league on league.id = matches.league_id
LEFT JOIN Team AS TeamA on TeamA.team_api_id = matches.home_team_api_id
LEFT JOIN Team AS TeamB on TeamB.team_api_id = matches.away_team_api_id
WHERE country.name = 'Spain'
ORDER by date;


#12:  check the info. at the country-league-season level.
SELECT 
	country.name, league.name AS league_name, season, count(distinct stage) AS number_of_stages,
	count(distinct TeamA.team_long_name) AS number_of_teams, avg(home_team_goal) AS avg_home_team_scors, 
	avg(away_team_goal) AS avg_away_team_goals, avg(home_team_goal-away_team_goal) AS avg_goal_dif, 
	avg(home_team_goal+away_team_goal) AS avg_goals, sum(home_team_goal+away_team_goal) AS total_goals                                       
FROM matches
INNER JOIN country on country.id = matches.country_id
INNER JOIN league on league.id = matches.league_id
LEFT JOIN Team AS TeamA on TeamA.team_api_id = matches.home_team_api_id
LEFT JOIN Team AS TeamB on TeamB.team_api_id = matches.away_team_api_id
WHERE country.name in ('Spain', 'Germany', 'France', 'Italy', 'England')
GROUP BY country.name, league.name, season
HAVING count(distinct stage) > 10
ORDER BY country.name, league.name, season DESC;

#13: 
SELECT 
CASE
	WHEN ROUND(height)<165 then 165
	WHEN ROUND(height)>195 then 195
	ELSE ROUND(height)
END AS calc_height, 
COUNT(height) AS distribution, (avg(PA_Grouped.avg_overall_rating)) AS avg_overall_rating,
(avg(PA_Grouped.avg_potential)) AS avg_potential, AVG(weight) AS avg_weight 
FROM player
LEFT JOIN (SELECT player_attributes.player_api_id, 
				  avg(Player_Attributes.overall_rating) AS avg_overall_rating,
				  avg(Player_Attributes.potential) AS avg_potential  
			FROM player_attributes
			GROUP BY player_attributes.player_api_id) AS PA_Grouped 
ON player.player_api_id = PA_Grouped.player_api_id
GROUP BY calc_height
ORDER BY calc_height;


