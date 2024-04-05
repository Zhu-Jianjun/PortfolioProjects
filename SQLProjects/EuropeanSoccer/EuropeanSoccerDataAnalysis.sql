USE EuropeanSoccer;

# https://www.kaggle.com/code/arvinthsss/european-football-dive-deep-sql/notebook
#1: Types of leagues
SELECT id, name FROM league
GROUP BY id, name;

#2: League vs Country 
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

#4: Players info.  
SELECT * FROM player;
SELECT * FROM player_attributes; 
/*
A column of 'positions' should be considered/added in player_attributes, s.t the player info. could be comparative based on the positions.
e.g., forward, center_forward, fullback, goalkeeper..., such that
CASE
	WHEN pa.position = 'forward' THEN MAX(pa.overall_rating)   #only one column could be placed after THEN  
    WHEN pa.position = 'forward' THEN pa.finishing
    ...
    ELSE 'others'
END AS
*/

SELECT 
	p.player_api_id AS Player_api_id,
    p.player_name AS Player_name,
    str_to_date(birthday, '%Y-%m-%d') AS Birthday,
    p.height AS Height,
    p.weight AS Weight,
    pa.overall_rating AS Max_rating,
    pa.potential AS Max_potential,
    pa.preferred_foot AS Preferred_foot,
    pa.attacking_work_rate AS Attacking_rate,
    pa.defensive_work_rate AS Defensive_rate
FROM player AS p
INNER JOIN player_attributes AS pa
ON p.player_api_id = pa.player_api_id;
    

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


#7: detailed match-by-match info. 
SELECT
    m.match_api_id,
    c.name AS countryname,
    l.name AS leaguename,
    m.season,
    DATE_FORMAT(m.date, '%d-%m-%Y') AS Date,
    m.stage,
    m.home_team_goal,
    m.away_team_goal,
    ht.team_long_name AS Home_Team_Long_Name,
    ht.team_short_name AS Home_Team_Short_Name,
    at.team_long_name AS Away_Team_Long_Name,
    at.team_short_name AS Away_Team_Short_Name,
    CASE
        WHEN m.home_team_goal > m.away_team_goal THEN ht.team_short_name
        WHEN m.home_team_goal < m.away_team_goal THEN at.team_short_name
        ELSE 'Tie'
    END AS Match_Winner
FROM
    matches m
JOIN 
    country c ON m.country_id = c.id
JOIN 
    league l ON c.id = l.country_id
JOIN 
    team AS ht ON m.home_team_api_id = ht.team_api_id
JOIN 
    team at ON m.away_team_api_id = at.team_api_id;
    

#8: Goals scored by home team vs away team Season on Season
SELECT
    ht_table.season,
    ht_table.leaguename,
    ht_table.HT_goals AS Home_Team_Goals,
    at_table.AT_goals AS Away_Team_Goals
FROM (
    SELECT
        m.season,
        l.name AS leaguename,
        SUM(m.home_team_goal) AS HT_goals
    FROM
        matches m
    JOIN league l ON m.country_id = l.country_id
    JOIN team ht ON m.home_team_api_id = ht.team_api_id
    GROUP BY m.season, l.name
) AS ht_table
JOIN (
    SELECT
        m.season,
        l.name AS leaguename,
        SUM(m.away_team_goal) AS AT_goals
    FROM
        matches m
    JOIN league l ON m.country_id = l.country_id
    JOIN team at ON m.away_team_api_id = at.team_api_id
    GROUP BY m.season, l.name
) AS at_table ON ht_table.leaguename = at_table.leaguename AND ht_table.season = at_table.season;


# alternatively
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


#9: Total Games played by team
SELECT 
    ht_season.season AS Season,
    ht_season.team AS Team,
    ht_season.home_games_played,
    at_season.away_games_played,
    (ht_season.home_games_played + at_season.away_games_played) AS Total_games_played_for_the_season
FROM (
    SELECT
        m.season AS season,
        ht.team_long_name AS team,
        COUNT(m.match_api_id) AS home_games_played
    FROM
        matches m
    INNER JOIN team ht ON m.home_team_api_id = ht.team_api_id
    GROUP BY m.season, ht.team_long_name
) AS ht_season
JOIN (
    SELECT
        m.season AS season,
        at.team_long_name AS team,
        COUNT(m.match_api_id) AS away_games_played
    FROM
        matches m
    INNER JOIN team at ON m.away_team_api_id = at.team_api_id
    GROUP BY m.season, at.team_long_name
) AS at_season ON ht_season.season = at_season.season AND ht_season.team = at_season.team;


#10: Matches won by Teams Season on Season
SELECT 
    season_results.season,
    season_results.match_winner,
    COUNT(season_results.match_winner) AS Number_of_Wins
FROM (
    SELECT
        m.season,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN ht.team_long_name
            WHEN m.home_team_goal < m.away_team_goal THEN at.team_long_name
            ELSE 'Tie'
        END AS Match_Winner
    FROM
        matchES m
    INNER JOIN team ht ON m.home_team_api_id = ht.team_api_id
    INNER JOIN team at ON m.away_team_api_id = at.team_api_id
) AS season_results
GROUP BY season_results.season, season_results.match_winner;


#11. Most Successful Teams compared for all seasons
SELECT 
    team,
    SUM(total_games) AS total_games,
    SUM(wins) AS wins,
    ROUND(100 * (SUM(wins) / SUM(total_games)), 2) AS win_percentage
FROM (
    SELECT
        Season,
        Team,
        SUM(home_games_played + away_games_played) as total_games,
        SUM(wins) as wins
    FROM (
        SELECT 
            a.season AS Season,
            a.team AS Team,
            COUNT(a.match_id) AS home_games_played,
            0 AS away_games_played,  -- Placeholder, actual count will be aggregated in UNION
            SUM(a.home_win) AS wins
        FROM (
            SELECT 
                m.match_api_id AS match_id,
                t.team_long_name AS team,
                m.season,
                CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END AS home_win
            FROM 
                matches m
            JOIN team t ON m.home_team_api_id = t.team_api_id
        ) a
        GROUP BY a.season, a.team
        UNION ALL
        SELECT 
            a.season AS Season,
            a.team AS Team,
            0 AS home_games_played,  -- Placeholder, actual count has been calculated above
            COUNT(a.match_id) AS away_games_played,
            SUM(a.away_win) AS wins
        FROM (
            SELECT 
                m.match_api_id AS match_id,
                t.team_long_name AS team,
                m.season,
                CASE WHEN m.home_team_goal < m.away_team_goal THEN 1 ELSE 0 END AS away_win
            FROM 
                matches m
            JOIN team t ON m.away_team_api_id = t.team_api_id
        ) a
        GROUP BY a.season, a.team
    ) total
    GROUP BY Season, Team
) results
GROUP BY team
ORDER BY win_percentage DESC;


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


