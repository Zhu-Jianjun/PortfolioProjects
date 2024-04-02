USE Covid19;

/*copy the tables from other schema */
CREATE TABLE Covid19.coviddeaths
SELECT * FROM PortfolioProjects.coviddeaths;

CREATE TABLE Covid19.covidvaccinations
SELECT * FROM PortfolioProjects.covidvaccinations;



-- Data Exploration
SELECT * FROM coviddeaths;
SELECT * FROM covidvaccinations;
SELECT COUNT(*) FROM coviddeaths;
SELECT COUNT(*) FROM covidvaccinations;
SELECT MAX(date), MIN(date) FROM coviddeaths;
SELECT MAX(date), MIN(date) FROM covidvaccinations;


-- Queries
#1: toal_cases vs total_deaths
SELECT 
	location,
	date,
	total_cases, 
    total_deaths,
   ROUND((total_deaths / total_cases), 3) AS death_rate
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY 1, 2, 3,4
HAVING location LIKE '%China%' AND date > '2023-01'
ORDER BY 2;

-- #2: which country has the highest infection rate
SELECT 
	location,
	population,
    MAX((total_cases / population)) AS infection_rate
FROM coviddeaths 
WHERE continent IS NOT NULL
GROUP BY 1,2
HAVING location LIKE '%CHINA%' OR location LIKE '%state%'
ORDER BY infection_rate DESC;

-- IF alos wanna show total_cases, then has to use an aggregate func. to it. For example, MAX(total_cases),
-- otherwise, it will return same locaiton since has to put total_cases in GROUP BY 


-- #3: which country has the highest death count per population
SELECT 
	location,
    MAX(cast(total_deaths AS SIGNED)) AS DeathCount -- cannot cast(... AS INT), has to use SIGNED
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathCount DESC;
 
-- NOT SURE WHY CANNOT FILTER OUT NULL continent?


-- #4: bring things down by continents
SELECT 
	continent,
    MAX(cast(total_deaths AS SIGNED)) AS DeathCount 
    -- cannot cast(... AS INT), has to use SIGNED
    -- if not cast to integer, then try to see the output, not ordered correctly
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathCount DESC;

-- #5: global numbers grouped by date
SELECT 
	date,
    SUM(new_cases),
    SUM(new_deaths)
FROM coviddeaths
GROUP BY date;


-- #6 join two tables on locations and date
SELECT * FROM coviddeaths;
SELECT * FROM covidvaccinations;

SELECT *
FROM coviddeaths AS cd
JOIN covidvaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date;

-- #7: total population vs total vaccinations
SELECT 
	cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations
FROM coviddeaths AS cd
JOIN covidvaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date;
    

-- #8: based on #7, show rolling count outputs
SELECT 
	cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    -- SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location) AS RollingNewVaccinated
    -- if stop here, the number in New_vaccinations won't have rolling count output. have to continue 
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingNewVaccinated
FROM coviddeaths AS cd
JOIN covidvaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date;


-- #9: since cannot directly use RollingNewVaccinated, have to use CTE or a temp table (acturally create a new table as temp table, not good)
-- check how to use CTE in the tutorial 
WITH PopvsvAC (location, date, population, new_vaccinations, RollingNewVaccinated) -- need to exactlly match # of columns in the following temp table
AS (
SELECT 
	cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    -- SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location) AS RollingNewVaccinated
    -- if stop here, the number in New_vaccinations won't have rolling count output. have to continue 
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingNewVaccinated
FROM coviddeaths AS cd
JOIN covidvaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date
)

SELECT *, RollingNewVaccinated / population
FROM PopvsvAC;
  

-- #10 better to create a VIEW for codes like above for future use
