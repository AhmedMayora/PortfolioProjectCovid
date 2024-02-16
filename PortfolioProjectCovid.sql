
-- SELECT ALL DATA

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- SELECT DATA THAT WE ARE GOING TO BE USING

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- LOOKUNG AT TOTAL CASES VS TOTAL DEATHS

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage --this creates and error as below
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

...............................................................................

---- Fix invalid datatype error, nvarchar is invalid [duplicate]

---- Step 1: Create a backup copy of the table just incase 

--SELECT * INTO PortfolioProject..CovidVaccinations_Backup
--FROM PortfolioProject..CovidVaccinations

---- Step 2: Add new numeric columns to the table

--ALTER TABLE PortfolioProject.dbo.CovidDeaths
--ADD total_cases_numeric NUMERIC(10,2),
--    total_deaths_numeric NUMERIC(10,2);

---- Step 3: Set the values of the new columns using TRY_CAST
--UPDATE PortfolioProject.dbo.CovidDeaths
--SET total_cases_numeric = TRY_CAST(total_cases AS NUMERIC(10,2)),
--    total_deaths_numeric = TRY_CAST(total_deaths AS NUMERIC(10,2));

---- Step 4: OPTIONAL! Drop the original nvarchar columns
--ALTER TABLE PortfolioProject.dbo.CovidDeaths
--DROP COLUMN total_cases,
--            total_deaths;

---- Step 5: OPTIONAL! Rename the new numeric columns to the original names
--EXEC sp_rename 'PortfolioProject.dbo.CovidDeaths.total_cases_numeric', 'total_cases', 'COLUMN';
--EXEC sp_rename 'PortfolioProject.dbo.CovidDeaths.total_deaths_numeric', 'total_deaths', 'COLUMN';


.......................................................................................................


-- LOOKING AT TOTAL CASES VS TOTAL DEATHS. SHOWS LIKELIHOOD OF DEATH IF YOU CONTRACT COVID IN A COUNTRY

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%kenya%' AND continent IS NOT NULL
ORDER BY 1,2

-- DEATH PER DAY PER COUNTRY IN AFRICA

SELECT date, continent, location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL and total_cases is not null and continent like '%africa%' and total_deaths is not null
ORDER BY 1

-- LOOKING AT TOTAL CASES VS POPULATION. SHOWS PERCENTAGE OF POP WITH COVID IN A PARTICULAR COUNTRY

SELECT location, date, population, total_cases, total_deaths, (total_cases/population)*100 AS CasesPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%kenya%' AND continent IS NOT NULL
ORDER BY 1,2

-- COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO THE POPULATION

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS HighestPercentageInfection 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
--AND location like '%kenya%'
GROUP BY location, population
ORDER BY 4 -- DESC

-- COUNTRIES WITH HIGHEST DEATH COUNT COMPARED TO THE POPULATION

SELECT location, population, MAX(total_deaths) AS HighestDeathCount --, MAX(total_deaths/population)*100 AS HighestPercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC


-- BREAK THINGS DOWN BY CONTINENT. SHOWING THE CONTINENT WITH THE HIGHEST DEATH COUNT

SELECT continent, MAX(total_deaths) AS HighestDeathCount, MAX(total_deaths/population)*100 AS HighestPercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 3 DESC

-- SPECIFIC TO A COUNTRY

SELECT location, population, MAX(total_deaths) AS HighestDeathCount, MAX(total_deaths/population)*100 AS HighestPercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--SPECIFIC TO A CONTINENT i.e. AFRICA

SELECT location, MAX(total_deaths) AS HighestDeathCount, MAX(total_deaths/population)*100 AS HighestPercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent like '%africa%' --NOT NULL
GROUP BY location
ORDER BY 2 DESC


-- GLOBAL NUMBERS - group by aggregate function

--SELECT SUM(new_cases) AS new_cases, 
--	   SUM(new_deaths) AS new_deaths,
--	   SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NOT NULL 
--	   AND new_cases !=0  -- had to dig deep on this
--ORDER BY 1,2


SELECT MAX(total_cases) AS total_cases, 
	   MAX(total_deaths) AS total_deaths,
	   MAX(total_deaths)/MAX(total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
	   AND new_cases !=0  -- had to dig deep on this
ORDER BY 1,2

--GLOBAL NUMBERS PER DAY

SELECT date, SUM(new_cases) AS new_cases, 
	   SUM(new_deaths) AS new_deaths,
	   SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
	   AND new_cases !=0  -- had to dig deep on this
GROUP BY date
ORDER BY 1 

-- JOIN THE TWO TABLES

SELECT *
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date

-- LOOKING AT TOTAL POPULATION VS VACCINATION

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date
WHERE Deaths.continent IS NOT NULL
ORDER BY 2, 3

-- AGGREGATE THE NEW VACCINATION PER LOCATION

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,
SUM(CAST(Vacc.new_vaccinations as bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS AggPerLocation
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date
WHERE Deaths.continent IS NOT NULL 
ORDER BY 2, 3

-- TOTAL POPULATION VS VACCINATION. CAN BE DONE USING CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, AggPerLocation)
AS
(
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,
SUM(CAST(Vacc.new_vaccinations as bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS AggPerLocation
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date
WHERE Deaths.continent IS NOT NULL
)
SELECT *, (AggPerLocation/population)*100 AS VacPercentageAgainstPop
FROM PopVsVac


-- TOTAL POPULATION VS VACCINATION. CAN BE DONE USING TEMP TABLES

DROP TABLE IF EXISTS #PercentagePopVaccinated
CREATE TABLE #PercentagePopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
AggPerLocation numeric
)
INSERT INTO #PercentagePopVaccinated
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,
SUM(CAST(Vacc.new_vaccinations as bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS AggPerLocation
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date
WHERE Deaths.continent IS NOT NULL
ORDER BY 2, 3

SELECT *, (AggPerLocation/population)*100 AS VacPercentageAgainstPop
FROM #PercentagePopVaccinated


-- CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATION

-- VACCINATION NUMBERS PER LOCATION PER DAY

CREATE VIEW VacPercentageAgainstPop AS
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,
SUM(CAST(Vacc.new_vaccinations as bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS AggPerLocation
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date
WHERE Deaths.continent IS NOT NULL 


SELECT *
FROM VacPercentageAgainstPop


-- LOOKING AT TOTAL CASES VS TOTAL DEATHS. SHOWS LIKELIHOOD OF DEATH IF YOU CONTRACT COVID IN A COUNTRY

CREATE VIEW DeathOnInfectionRateKenya AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%kenya%' AND continent IS NOT NULL

-- LOOKUNG AT TOTAL CASES VS TOTAL DEATHS: DEATH PERCENTAGE PER COUNTRY

CREATE VIEW DeathPercentageCountry AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

-- DEATH PER DAY PER COUNTRY IN AFRICA

CREATE VIEW DeathPercentagePerCountryInAfrica AS
SELECT date, continent, location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL and total_cases is not null and continent like '%africa%' and total_deaths is not null

-- DEATH PER DAY PER COUNTRY IN EUROPE

CREATE VIEW DeathPercentagePerCountryInEurope AS
SELECT date, continent, location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL and total_cases is not null and continent like '%europe%' and total_deaths is not null

-- DEATH PER DAY PER COUNTRY IN ASIA

CREATE VIEW DeathPercentagePerCountryInAsia AS
SELECT date, continent, location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL and total_cases is not null and continent like '%asia%' and total_deaths is not null


-- LOOKING AT TOTAL CASES VS POPULATION. SHOWS PERCENTAGE OF POP WITH COVID IN A PARTICULAR COUNTRY

CREATE VIEW PercentageOfInfectionKenya AS 
SELECT location, date, population, total_cases, total_deaths, (total_cases/population)*100 AS CasesPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%kenya%' AND continent IS NOT NULL


-- COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO THE POPULATION

CREATE VIEW HighestInfectionToPop AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS HighestPercentageInfection 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location, population


-- COUNTRIES WITH HIGHEST DEATH COUNT COMPARED TO THE POPULATION

CREATE VIEW HighestDeathCount AS
SELECT location, population, MAX(total_deaths) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population


-- BREAK THINGS DOWN BY CONTINENT. SHOWING THE CONTINENT WITH THE HIGHEST DEATH COUNT

CREATE VIEW HighestDeathCountContinent AS
SELECT continent, MAX(total_deaths) AS HighestDeathCount, MAX(total_deaths/population)*100 AS HighestPercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent

-- SPECIFIC TO A COUNTRY

CREATE VIEW HighestDeathCountry AS
SELECT location, population, MAX(total_deaths) AS HighestDeathCount, MAX(total_deaths/population)*100 AS HighestPercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

--SPECIFIC TO A CONTINENT i.e. AFRICA

CREATE VIEW AfricaHighestDeath AS
SELECT location, MAX(total_deaths) AS HighestDeathCount, MAX(total_deaths/population)*100 AS HighestPercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent like '%africa%' --NOT NULL
GROUP BY location


CREATE VIEW DeathPercentageGlobal AS
SELECT MAX(total_cases) AS total_cases, 
	   MAX(total_deaths) AS total_deaths,
	   MAX(total_deaths)/MAX(total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND new_cases != 0  


--GLOBAL NUMBERS PER DAY

CREATE VIEW GlobalDeathPerDay AS
SELECT date, SUM(new_cases) AS new_cases, 
	   SUM(new_deaths) AS new_deaths,
	   SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
	   AND new_cases != 0 
GROUP BY date


-- JOIN THE TWO TABLES

SELECT *
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date

-- LOOKING AT TOTAL POPULATION VS VACCINATION

CREATE VIEW PopVaccOnTwoTables AS
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations
FROM PortfolioProject..CovidDeaths AS Deaths
JOIN PortfolioProject..CovidVaccinations AS Vacc
	ON Deaths.location = Vacc.location
	AND Deaths.date = Vacc.date
WHERE Deaths.continent IS NOT NULL

SELECT *
FROM information_schema.tables;