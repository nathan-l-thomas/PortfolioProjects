SELECT
    cd.location,
    cd.date,
    cd.total_cases,
    cd.total_deaths,
    cd.population
FROM CovidDeaths as cd
WHERE cd.continent IS NOT NULL
ORDER BY location, date

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID-19
SELECT
    cd.location,
    cd.date,
    cd.total_cases,
    cd.total_deaths,
    ROUND((total_deaths/total_cases)*100, 2) as death_percentatge
FROM CovidDeaths as cd
WHERE location = 'United States'
ORDER BY location, date

-- Total Cases vs Population
-- Shows what percentage has contracted COVID-19
SELECT
    cd.location,
    cd.date,
    cd.total_cases,
    cd.population,
    ROUND((cd.total_cases/cd.population)*100, 2) as infected_population_percentatge
FROM CovidDeaths as cd
WHERE location = 'United States'
ORDER BY location, date

-- Looking at countries with Highest Infection Rate compared to Population
SELECT cd.location,
       cd.population,
       MAX(cd.total_cases) as highest_infection_count,
       MAX(ROUND((cd.total_cases/cd.population)*100, 2)) as hightest_infected_percentage
FROM CovidDeaths as cd
WHERE cd.continent IS NOT NULL
GROUP BY location, population
ORDER BY hightest_infected_percentage DESC

-- Showing countries with Highest Death Count per Population
SELECT cd.location,
       MAX(CAST(cd.total_deaths AS BIGINT)) as total_death_count
FROM CovidDeaths as cd
WHERE cd.continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Breaking things down by continent
-- Showing continents with Highest Death Count
SELECT cd.location,
       MAX(CAST(cd.total_deaths AS INT)) AS total_death_count
FROM CovidDeaths as cd
WHERE cd.continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Global numbers by day
SELECT
    date,
    SUM(cd.new_cases) AS running_total_cases,
    SUM(CAST(cd.new_deaths AS BIGINT)) as running_total_deaths,
    ROUND(SUM(CAST(cd.new_deaths AS BIGINT))/SUM(cd.new_cases)*100,2) as death_percentage
FROM CovidDeaths AS cd
WHERE cd.continent IS NOT NULL
GROUP BY date
ORDER BY date

-- Total global cases
SELECT
    SUM(cd.new_cases) AS running_total_cases,
    SUM(CAST(cd.new_deaths AS BIGINT)) as running_total_deaths,
    ROUND(SUM(CAST(cd.new_deaths AS BIGINT))/SUM(cd.new_cases)*100,2) as death_percentage
FROM CovidDeaths AS cd
WHERE cd.continent IS NOT NULL

-- Bringing in vaccinations
-- Total Population vs Vaccinations
SELECT cd.continent,
       cd.location,
       cd.date,
       cd.population,
       cv.new_vaccinations,
       SUM(CAST(cv.new_vaccinations AS BIGINT))
           OVER (PARTITION BY cd.location
               ORDER BY cd.location, cd.date) as rolling_people_vaccinated
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date

-- Using a CTE to calculate rolling percentage of people vaccinated by country
WITH PopulationvsVaccinations (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
    AS
(
    SELECT cd.continent,
       cd.location,
       cd.date,
       cd.population,
       cv.new_vaccinations,
       SUM(CAST(cv.new_vaccinations AS BIGINT))
           OVER (PARTITION BY cd.location
               ORDER BY cd.location, cd.date) as rolling_people_vaccinated
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT *,
       ROUND((rolling_people_vaccinated/population)*100,2) as percent_population_vaccinated
FROM PopulationvsVaccinations


-- Using a Temp Table
DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date date,
    population numeric,
    new_vaccinations numeric,
    rolling_people_vaccinated numeric
)
INSERT INTO #percent_population_vaccinated
SELECT cd.continent,
       cd.location,
       cd.date,
       cd.population,
       cv.new_vaccinations,
       SUM(CAST(cv.new_vaccinations AS BIGINT))
           OVER (PARTITION BY cd.location
               ORDER BY cd.location, cd.date) as rolling_people_vaccinated
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, ROUND((rolling_people_vaccinated/population)*100,2) as percent_population_vaccinated
FROM #percent_population_vaccinated


-- Creating view to store data for later visualizations
CREATE VIEW percent_population_vaccinated AS
    SELECT cd.continent,
       cd.location,
       cd.date,
       cd.population,
       cv.new_vaccinations,
       SUM(CAST(cv.new_vaccinations AS BIGINT))
           OVER (PARTITION BY cd.location
               ORDER BY cd.location, cd.date) as rolling_people_vaccinated
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *
FROM percent_population_vaccinated