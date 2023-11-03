--Select Data that we are going to be using 

Select location, date, total_cases, new_cases, total_deaths,population
From Portfolio..CovidDeaths
Order by 1,2

--Looking for total cases vs total deaths

--Select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 
--From Portfolio..CovidDeaths
--Order by 1,2

-- got that error.

--Msg 8117, Level 16, State 1, Line 9
--Operand data type varchar is invalid for divide operator.

-- we are now solve it

ALTER TABLE Portfolio..CovidDeaths
ADD int_total_cases INT NULL,
    int_new_cases INT NULL,
    int_total_deaths INT NULL,
    int_population INT NULL;

	UPDATE Portfolio..CovidDeaths
SET int_total_cases = TRY_CONVERT(INT, total_cases),
    int_new_cases = TRY_CONVERT(INT, new_cases),
    int_total_deaths = TRY_CONVERT(INT, total_deaths),
    int_population = TRY_CONVERT(INT, population);

ALTER TABLE Portfolio..CovidDeaths
DROP COLUMN total_cases,
            new_cases,
            total_deaths,
            population;

EXEC sp_rename 'Portfolio..CovidDeaths.int_total_cases', 'total_cases', 'COLUMN';
EXEC sp_rename 'Portfolio..CovidDeaths.int_new_cases', 'new_cases', 'COLUMN';
EXEC sp_rename 'Portfolio..CovidDeaths.int_total_deaths', 'total_deaths', 'COLUMN';
EXEC sp_rename 'Portfolio..CovidDeaths.int_population', 'population', 'COLUMN';

--now columns are updated 

SELECT 
    location, 
    date, 
    int_total_cases, 
    int_new_cases, 
    int_total_deaths, 
    (CAST(int_total_deaths AS FLOAT) / NULLIF(CAST(int_total_cases AS FLOAT), 0)) * 100 AS death_per
FROM 
    Portfolio..CovidDeaths
ORDER BY 
    1, 2
-- Perform the function now we are going to check the specific country to check this ratio

--I set pak for pakistan
SELECT 
    location, 
    date, 
    int_total_cases, 
    int_new_cases, 
    int_total_deaths, 
    (CAST(int_total_deaths AS FLOAT) / NULLIF(CAST(int_total_cases AS FLOAT), 0)) * 100 AS death_per
FROM 
    Portfolio..CovidDeaths
where location like '%pak%'
ORDER BY 
    1, 2

-- now checking the population on covid case in percentage
SELECT 
    location, 
    date, 
    int_total_cases, 
    int_new_cases, 
	int_population
    int_total_deaths, 
    (CAST(int_total_cases AS FLOAT) / NULLIF(CAST(int_population AS FLOAT), 0)) * 100 AS got_covid
FROM 
    Portfolio..CovidDeaths
where location like '%states%'
ORDER BY 
    1, 2


--looking at countries with highest infestion rate
SELECT 
    location, 
    int_population,
    Max(int_total_cases) As Highest_infected_count,
	Max(CAST(int_total_cases AS FLOAT) / NULLIF(CAST(int_population AS FLOAT), 0)) * 100 AS got_covid


FROM 
    Portfolio..CovidDeaths
--where location like '%states%'
group by 
Location , int_population
ORDER BY Highest_infected_count desc


--looking at countries with highest death rate per population
SELECT 
    location, 
    Max(cast(int_total_deaths as int)) As Total_death_count
FROM 
    Portfolio..CovidDeaths
-- Uncomment the following line if you want to filter by locations containing 'states'
-- WHERE location LIKE '%states%'
where continent is not null
GROUP BY 
    location
ORDER BY 
    Total_death_count DESC



--looking at continent with highest death rate per population
SELECT 
    continent, 
    Max(cast(int_total_deaths as int)) As Total_death_count
FROM 
    Portfolio..CovidDeaths
-- Uncomment the following line if you want to filter by locations containing 'states'
-- WHERE location LIKE '%states%'
where continent is not null
GROUP BY 
    continent
ORDER BY 
    Total_death_count DESC



	--Global number



Select SUM(int_new_cases) as total_cases, SUM(cast(int_new_deaths as int)) as total_deaths, SUM(cast(int_new_deaths as int))/SUM(int_New_Cases)*100 as DeathPercentage
From Portfolio..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine




--ASLO JUST FOR REFRENCE YOU HAVE TO USE INT_ FOR POPULATION INFORNT BECAUSE IT NOT INT SO i CHANGE IT.
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 





















