Select * 
from portfolioproject..CovidDeaths
where continent is not null
order by 3,4


--select data we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from portfolioproject..CovidDeaths
where continent is not null
order by 1,2
--looking at total cases vs total deaths
--shows the likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)*100 AS DeathPercentage
from portfolioproject..CovidDeaths
where location like '%Asia%'
and continent is not null
order by 1,2

--looking at Total cases vs Population
--shows what percentage of population got covid
select location, date, population, total_cases, CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)*100 AS PercentagePopulationInfected
from portfolioproject..CovidDeaths
where location like '%Asia%'
and continent is not null
order by 1,2

--looking at countries with highest infection rate compared to population

select location, population, MAX(total_cases) AS HighestInfectioncCount , MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0))*100 AS PercentagePopulationInfected
from portfolioproject..CovidDeaths
--where location like '%Asia%'
where continent is not null
Group by location, population
order by PercentagePopulationInfected desc

--showing countries with highest death counmt per population

select location, MAX(CAST(total_deaths AS INT)) AS TotaldeathCount
from portfolioproject..CovidDeaths
--where location like '%Asia%'
where continent is not null
Group by location
order by TotaldeathCount desc


--LET'S BREAK THINGS DOWN BY CONTINENT

select continent, MAX(CAST(total_deaths AS INT)) AS TotaldeathCount
from portfolioproject..CovidDeaths
--where location like '%Asia%'
where continent is not null
Group by continent
order by TotaldeathCount desc

--showing continents with highest death count per population

select continent, MAX(CAST(total_deaths AS INT)) AS TotaldeathCount
from portfolioproject..CovidDeaths
--where location like '%Asia%'
where continent is not null
Group by continent
order by TotaldeathCount desc

--Global Numbers

select SUM(CAST(new_cases AS INT)) as total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, 
SUM(CAST(new_deaths AS INT))/ SUM(NULLIF(CAST(total_cases AS FLOAT), 0))*100 AS DeathPercentage
from portfolioproject..CovidDeaths
--where location like '%Asia%'
where continent is not null
order by 1,2


-- Looking at Total Population Vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, COALESCE(NULLIF(vac.new_vaccinations, ''),NULL) AS new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject..Coviddeaths dea
join portfolioproject..CovidVacccinations vac
      on dea.location = vac.location
	  and dea.date = vac.date
where dea.continent is not null
order by 2,3 

--use CTE

with popvsvac(continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, COALESCE(NULLIF(vac.new_vaccinations, ''),NULL) AS new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject..Coviddeaths dea
join portfolioproject..CovidVacccinations vac
      on dea.location = vac.location
	  and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (COALESCE(NULLIF(rollingpeoplevaccinated, ''),NULL)/NULLIF(CAST(population AS FLOAT), 0))*100
from popvsvac

-- Temp Table

drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population nvarchar(255),
new_vaccinations nvarchar(255),
rollingpeoplevaccinated nvarchar(255)
)

insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population, COALESCE(NULLIF(vac.new_vaccinations, ''),NULL) AS new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject..Coviddeaths dea
join portfolioproject..CovidVacccinations vac
      on dea.location = vac.location
	  and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (COALESCE(NULLIF(rollingpeoplevaccinated, ''),NULL)/NULLIF(CAST(population AS FLOAT), 0))*100
from #percentpopulationvaccinated


--creating view to store data for later visualizations

IF OBJECT_ID('dbo.percentpopulationvaccinated', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.percentpopulationvaccinated;
END;
GO -- This separates the batches

create view percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, COALESCE(NULLIF(vac.new_vaccinations, ''),NULL) AS new_vaccinations,
SUM(CONVERT(FLOAT,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject..Coviddeaths dea
join portfolioproject..CovidVacccinations vac
      on dea.location = vac.location
	  and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * 
from percentpopulationvaccinated