/* 

Eksploracja danych o Covid-19 pozyskanych z: https://ourworldindata.org/covid-deaths
U¿yte umiejêtnoœci: Joins, CTE, Temp Table, Funkcje agreguj¹ce, Zmiana typów danych oraz 
tworzenie Views.

*/


SELECT * 
FROM project1..CovidDeaths
where continent is not null
order by 3, 4



-- Wybieram dane, których bêdê u¿ywaæ


SELECT location, date, total_cases, new_cases, total_deaths,  population
FROM project1..CovidDeaths
where continent is not null
order by 1, 2


-- Wszystkie przypadki vs Wszystkie zgony
-- Pokazuje prawdopodobieñstwo œmierci w przypadku zara¿enia siê Covid-19 w Polsce


SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathToCases
FROM project1..CovidDeaths
where location = 'Poland'
and continent is not null
order by 1, 2


-- Wszytskie przypadki vs Populacja
-- Ukazuje jaki procent populacji by³a zara¿ona wirusem


SELECT location, date, population, total_cases, (total_cases/population)*100 as CasesToPopulation
FROM project1..CovidDeaths
--where location = 'Poland'
where continent is not null
order by 1, 2


-- Wyszukuje kraje z najwy¿szym odsetkiem zara¿enie populacji


SELECT location, population, max(total_cases) as highestInfectionCount, MAX((total_cases/population))*100 as CasesToPopulation
FROM project1..CovidDeaths
--where location = 'Poland'
GROUP BY location, population
order by 4 desc


-- Wyszukuje kraje z najwiêkszym procentem zgonów na populacje


SELECT location, population, max(cast(total_deaths as int)) as highestDeathCount, MAX((total_deaths/population))*100 as DeathsVsPopulation
FROM project1..CovidDeaths
where continent is not NULL
GROUP BY location, population
order by 3 desc


--Pokazuje kontynenty z najwiêksz¹ iloœci¹ zgonów oraz najwiêkszym procentem zgonów vs populacja


SELECT continent, max(cast(total_deaths as int)) as highestDeathCount, MAX((total_deaths/population))*100 as DeathsVsPopulation
FROM project1..CovidDeaths
where continent is not NULL
GROUP BY continent
order by DeathsVsPopulation desc


-- LICZBY OGÓLNOŒWIATOWE


SELECT date, sum(new_cases) as RollingCountOfCases, sum(cast(new_deaths as int)) RollingCountOfDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathToCases
FROM project1..CovidDeaths
--where location = 'Poland'
where new_cases > 0
and continent is not null
group by date --, total_deaths, total_cases
order by 1, 2


--POPULACJA VS SZCZEPIENIA
--PARTITION BY 


select DEA.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date)
AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from project1..CovidVaccinations vac
join project1..CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null
order by 1, 2, 3


---U¿yjê CTE do wykoania obliczenia: (RollingPeopleVaccinated/population)*100

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeapleVaccinated)
as
(
select DEA.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, 
dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from project1..CovidVaccinations vac
join project1..CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null
--order by 2, 3
)
Select *, (RollingPeapleVaccinated/population)*100 as PercOfVacc
from PopvsVac


-- Z POMOC¥ TEMP TABLE


DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
select DEA.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, 
dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from project1..CovidVaccinations vac
join project1..CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null
--order by 2, 3

Select *, (RollingPeopleVaccinated/population)*100 as PercOfVacc
from #PercentPopulationVaccinated


-- Tworzenie VIEW aby zarchiwizowaæ dane do dalszej wizualizacji

create view PercentPopulationVaccinated AS
Select DEA.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, 
dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from project1..CovidVaccinations vac
join project1..CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null


SELECT *
FROM PercentPopulationVaccinated