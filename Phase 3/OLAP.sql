-- Part 1. Standard OLAP operations
-- a

SELECT * FROM FACTTABLE;
-- Drill down from Year to Month
SELECT d.Year, d.Month, SUM(f.resolved) AS total_resolved, SUM(f.Death) AS total_deaths
FROM Facttable f
JOIN Datedimension d ON f.DateID = d.DateID
GROUP BY d.Year, d.Month
ORDER BY d.Year,
CASE d.Month
            WHEN 'January' THEN 1
            WHEN 'February' THEN 2
            WHEN 'March' THEN 3
            WHEN 'April' THEN 4
            WHEN 'May' THEN 5
            WHEN 'June' THEN 6
            WHEN 'July' THEN 7
            WHEN 'August' THEN 8
            WHEN 'September' THEN 9
            WHEN 'October' THEN 10
            WHEN 'November' THEN 11
            WHEN 'December' THEN 12
            ELSE 99 -- Default, in case of unexpected values
         END;


-- Roll up from Month to Year
SELECT d.Year, SUM(f.resolved) AS total_resolved, SUM(f.Death) AS total_deaths
FROM Facttable f
JOIN Datedimension d ON f.DateID = d.DateID
GROUP BY d.Year
ORDER BY d.Year;



-- b. Slice
-- Select data for Ontario
SELECT p.prname AS province, d.date, f.resolved, f.Death
FROM Facttable f
JOIN Datedimension d ON f.DateID = d.DateID
JOIN provincedimension p ON f.province = p.province
WHERE f.province = 'ON';

-- c. Dice (creating a sub-cube)
-- Filter for a specific province and year
SELECT d.year, p.prname, d.month, SUM(f.resolved) AS total_resolved, SUM(f.death) AS total_deaths
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
WHERE p.prname = 'British Columbia' AND d.year = 2022
GROUP BY d.year,p.prname, d.month
ORDER BY CASE d.Month
            WHEN 'January' THEN 1
            WHEN 'February' THEN 2
            WHEN 'March' THEN 3
            WHEN 'April' THEN 4
            WHEN 'May' THEN 5
            WHEN 'June' THEN 6
            WHEN 'July' THEN 7
            WHEN 'August' THEN 8
            WHEN 'September' THEN 9
            WHEN 'October' THEN 10
            WHEN 'November' THEN 11
            WHEN 'December' THEN 12
            ELSE 99 -- Default, in case of unexpected values
         END;

-- Filter for multiple provinces and a year range
SELECT p.prname AS province, d.year, SUM(f.resolved) AS total_resolved, SUM(f.death) AS total_deaths
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
WHERE p.prname IN ('Ontario', 'Quebec') AND d.year BETWEEN 2021 AND 2022
GROUP BY p.prname, d.year
ORDER BY p.prname, d.year;

--d. Combining OLAP operations

-- Explore data during different time periods, for different provinces
SELECT p.prname AS province, d.year, SUM(f.resolved) AS total_resolved, SUM(f.death) AS total_deaths
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname, d.year
ORDER BY p.prname, d.year;

-- Compare vaccination rates between provinces
SELECT p.prname AS province, 
CAST((SUM(v.partial) - SUM(v.fully)) AS FLOAT)/SUM(v.partial) AS partial_rate,
CAST((SUM(v.fully) - SUM(v.booster)) AS FLOAT)/SUM(v.partial) AS fully_rate,
CAST(SUM(v.booster) AS FLOAT)/SUM(v.partial) AS booster_rate 
FROM FactTable f
JOIN VaccinationDimension v ON f.vacID = v.vacID
JOIN ProvinceDimension p ON f.province = p.province
GROUP BY p.prname
ORDER BY p.prname;


-- Explore trends in COVID-19 metrics over time
SELECT d.year, d.month, SUM(c.totalCases) AS total_cases, SUM(c.numDeaths) AS total_deaths, SUM(c.recovery) AS total_recoveries
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- Contrast COVID-19 metrics between provinces
SELECT p.prname AS province, SUM(c.totalCases) AS total_cases, SUM(c.numDeaths) AS total_deaths, SUM(c.recovery) AS total_recoveries
FROM FactTable f
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname
ORDER BY total_cases DESC;

--Part 2. Explorative operations

-- a. Iceberg queries

-- Find the five provinces with the highest total cases
SELECT p.prname AS province, SUM(c.totalCases) AS total_cases
FROM FactTable f
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname
ORDER BY total_cases DESC
LIMIT 5;

-- b. Windowing queries

-- Display the ranking of provinces based on total deaths, ordered by year
SELECT p.prname AS province, d.year, SUM(c.numDeaths) AS total_deaths,
RANK() OVER (PARTITION BY d.year ORDER BY SUM(c.numDeaths) DESC) AS death_rank
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname, d.year
ORDER BY d.year, death_rank;

-- c. Using the Window clause

-- Compare the total cases in Ontario in 2022 to the previous and next years
SELECT d.year, SUM(c.totalCases) AS total_cases,
LAG(SUM(c.totalCases), 1) OVER (ORDER BY d.year) AS prev_year_cases,
LEAD(SUM(c.totalCases), 1) OVER (ORDER BY d.year) AS next_year_cases
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
WHERE p.prname = 'Ontario'
GROUP BY d.year
ORDER BY d.year;