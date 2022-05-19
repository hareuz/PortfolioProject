/* Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS 'CasesVSdeaths'
FROM vax_data
ORDER BY 1, 2

SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS 'likelihood'
FROM death_data
WHERE location LIKE ('%Pakis%')
ORDER BY 1, 2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT  location, total_cases, population, (total_cases/population)*100 AS populationInfected
FROM death_data
ORDER BY location

-- Countries with Highest Infection Rate compared to Population
SELECT  location, population, MAX(total_cases) AS highestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM death_data
GROUP BY location, population
ORDER BY location

-- Countries with Highest Death Count per Population

SELECT  location, population,  MAX(CAST(total_deaths AS INT)) AS totaldeathcount
FROM death_data
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY totaldeathcount DESC

SELECT * FROM [Portfolio project]..death_data
order BY 1, 2
 


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS ContinentalDeaths FROM [Portfolio project]..death_data
WHERE continent is NOT NULL
GROUP BY continent 
ORDER BY ContinentalDeaths DESC


--Global Numbers
SELECT date, SUM(new_cases) as totalcases, SUM(CAST(new_deaths AS INT)) AS totalcases, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as deathsPERcases
FROM [Portfolio project]..death_data
WHERE continent is NOT NULL
GROUP BY date
ORDER BY date


-- Total Population vs Vaccinations 

SELECT dea.location, dea.continent, dea.date, dea.population, vaxx.new_vaccinations
, SUM(CAST(vaxx.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.Date) AS Rollingpeoplevaxx
FROM [Portfolio project]..vaxx_data vaxx
Join [Portfolio project]..death_data dea
	ON vaxx.location = dea.location
	AND vaxx.date = dea.date
	WHERE dea.continent IS NOT NULL
Order by 1,2,3

--CTE (Common Table Expression) This is a temperory table
WITH Popvsvaxx(continent, location, date, population, new_vaccinations, Rollingpeoplevaxx)
AS (
SELECT  dea.continent, dea.location, dea.date, dea.population, vaxx.new_vaccinations
, SUM(CAST(vaxx.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.Date) AS Rollingpeoplevaxx
FROM [Portfolio project]..vaxx_data vaxx
Join [Portfolio project]..death_data dea
	ON vaxx.location = dea.location
	AND vaxx.date = dea.date
	WHERE dea.continent IS NOT NULL
--Order by 1,2,3
)
SELECT *, (Rollingpeoplevaxx/population)*100 FROM Popvsvaxx

--Temperory Table
DROP TABLE if exists #PercentagePopulationVaxxed
CREATE TABLE #PercentagePopulationVaxxed
(
Continent varchar(225),
Locaion varchar(225),
Date datetime,
Population numeric,
new_vaccinations numeric,
Rollingpeoplevaxx numeric
)
INSERT INTO #PercentagePopulationVaxxed
SELECT dea.location, dea.continent, dea.date, dea.population, vaxx.new_vaccinations
, SUM(CAST(vaxx.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.Date) AS Rollingpeoplevaxx
FROM [Portfolio project]..vaxx_data vaxx
Join [Portfolio project]..death_data dea
	ON vaxx.location = dea.location
	AND vaxx.date = dea.date
	WHERE dea.continent IS NOT NULL
Order by 1,2,3
SELECT *, (rollingpeoplevaxx/population)*100 AS PercentagePopulationVaxx
FROM #PercentagePopulationVaxxed

-- View for vizualization

CREATE VIEW PercentagePopulationVaxxed AS 
SELECT dea.location, dea.continent, dea.date, dea.population, vaxx.new_vaccinations
, SUM(CAST(vaxx.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.Date) AS Rollingpeoplevaxx
FROM [Portfolio project]..vaxx_data vaxx
Join [Portfolio project]..death_data dea
	ON vaxx.location = dea.location
	AND vaxx.date = dea.date
	WHERE dea.continent IS NOT NULL
--Order by 1,2,3
