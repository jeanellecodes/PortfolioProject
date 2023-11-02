SELECT *
FROM PortfolioProject.dbo.CovidDeaths
order by 3, 4

--SELECT *
--FROM PortfolioProject.dbo.CovidVaccinations
--order by 3, 4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
order by 1, 2

-- Looking at Total Case vs Total Deaths
-- Shows the likelihood of dying if you contract covid  in your country
-- Error occured when doing the percentage b/c of the NULL values; CAST as FLOAT was used to convert the "Null"'s into integers; 

SELECT location, date, total_cases, total_deaths, CAST(total_deaths as float)/CAST(total_cases as float)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'
order by 1, 2

-- Looking at total cases vs population
-- Shows what percentage of population got covid

SELECT location, date, population, total_cases, CAST(total_cases as float)/(population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'
order by 1, 2


-- Looking countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX( CAST(total_cases as float))/(population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
Group by location, population
order by PercentPopulationInfected desc

--Showing the countries with highest death count per population
-- Used the where continent is not null clause; 
--b/c if the continent section is NULL, then it is in the location section
-- which gives us unwanted data

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
Group by location
order by TotalDeathCount desc



--Showing the continent w/ the highets death counts

SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
Group by continent
order by TotalDeathCount desc


--Global numbers
--nullif satement was used b/c error was returned "Divide by zero error encountered.
--Warning: Null value is eliminated by an aggregate or other SET operation."


--By date


SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/nullif(SUM(new_cases),0)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location = 'United States'
WHERE continent is not null
GROUP BY date
order by 1, 2

--in the world


SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/nullif(SUM(new_cases),0)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location = 'United States'
WHERE continent is not null
--GROUP BY date
order by 1, 2


-- join the two tables; as dea and as vax are aliases used
-- looking at total population vs vaccinations; 

--used partition by function so everytime it gets to a new location, the count will start over
-- can also is CONVERT(float, vax.new_vaccinations) instead of CAST

-- order by dea.location, dea.date gives the sum from adding the column before; adds up consecutivly; a rolling count

SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as dea
join PortfolioProject.dbo.CovidVaccinations as vax
	ON dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is not null
ORDER BY 2,3



-- Use CTE
--used the WITH clause to give the query a name so that it can be used in further calculations

WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as dea
join PortfolioProject.dbo.CovidVaccinations as vax
	ON dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac



-- Temp Table
--DROP table if making any alterations



DROP TABLE IF exists #PercentPopulationVacciated
Create Table #PercentPopulationVacciated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVacciated
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as dea
join PortfolioProject.dbo.CovidVaccinations as vax
	ON dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is not null
--ORDER BY 2,3


SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVacciated


--Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as dea
join PortfolioProject.dbo.CovidVaccinations as vax
	ON dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is not null
--ORDER BY 2,3