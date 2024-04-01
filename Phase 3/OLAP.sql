-- Part 1. Standard OLAP operations
-- a
-- Drill down from Year to Month
SELECT d.Year, d.Month, SUM(f.totalCases_change) AS monthly_cases, 
SUM(f.recovery_change) AS monthly_recovery, SUM(f.death_change) AS monthly_deaths
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
SELECT d.Year, SUM(f.totalCases_change) AS anually_cases, 
SUM(f.recovery_change) AS anually_recovery, SUM(f.death_change) AS anually_deaths
FROM Facttable f
JOIN Datedimension d ON f.DateID = d.DateID
GROUP BY d.Year
ORDER BY d.Year;



-- b. Slice
-- Select data for Ontario
SELECT p.prname AS province, d.date, f.totalCases_change as weekly_cases, 
f.recovery_change as weekly_recovery, f.death_change as weekly_death
FROM Facttable f
JOIN Datedimension d ON f.DateID = d.DateID
JOIN provincedimension p ON f.province = p.province
WHERE f.province = 'ON';

-- c. Dice (creating a sub-cube)
-- Filter for a specific province and year
SELECT d.year, p.prname, d.month,SUM(f.totalCases_change) AS mothly_cases,
SUM(f.recovery_change) AS monthly_recovery, SUM(f.death_change) AS monthly_deaths
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
WHERE p.prname = 'British Columbia' AND d.year = 2021
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
SELECT p.prname AS province, d.year, SUM(f.totalCases_change) AS anually_cases, 
SUM(f.recovery_change) AS anually_resolved, SUM(f.death_change) AS anually_deaths
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
WHERE p.prname IN ('Ontario', 'Quebec') AND d.year BETWEEN 2021 AND 2022
GROUP BY p.prname, d.year
ORDER BY p.prname, d.year;


--d. Combining OLAP operations

-- Explore data during different time periods, for different provinces
SELECT p.prname AS province, d.year, SUM(f.totalCases_change) AS anually_cases,
SUM(f.recovery_change) AS anually_resolved, SUM(f.death_change) AS anually_deaths
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname, d.year
ORDER BY p.prname, d.year;

-- Compare vaccination rates between provinces
SELECT p.prname AS province, 
CAST((SUM(v.partial_change) - SUM(v.fully_change)) AS FLOAT)/SUM(v.partial_change) AS partial_rate,
CAST((SUM(v.fully_change) - SUM(v.booster_change)) AS FLOAT)/SUM(v.partial_change) AS fully_rate,
CAST(SUM(v.booster_change) AS FLOAT)/SUM(v.partial_change) AS booster_rate 
FROM FactTable f
JOIN VaccinationDimension v ON f.vacID = v.vacID
JOIN ProvinceDimension p ON f.province = p.province
GROUP BY p.prname
ORDER BY p.prname;


-- Explore trends in COVID-19 metrics over time
SELECT d.year, d.month, SUM(f.totalCases_change) AS mothly_cases,
SUM(f.recovery_change) AS monthly_recovery, SUM(f.death_change) AS monthly_deaths
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY d.year, d.month
ORDER BY d.year, 
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

-- Contrast COVID-19 metrics between provinces
SELECT p.prname AS province, SUM(f.totalCases_change) AS total_cases,
SUM(f.recovery_change) AS total_recovery, SUM(f.death_change) AS total_deaths
FROM FactTable f
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname
ORDER BY total_cases DESC;

--Part 2. Explorative operations

-- a. Iceberg queries

-- Find the five provinces with the highest total death numbers
SELECT p.prname AS province, SUM(f.death_change) AS total_death
FROM FactTable f
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname
ORDER BY total_death DESC
LIMIT 5;

-- b. Windowing queries

-- Display the ranking of provinces based on total cases, ordered by year
SELECT p.prname AS province, d.year, SUM(f.totalcases_change) AS total_casess,
RANK() OVER (PARTITION BY d.year ORDER BY SUM(f.totalcases_change) DESC) AS death_rank
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
GROUP BY p.prname, d.year
ORDER BY d.year, death_rank;

-- c. Using the Window clause

-- Compare the total recovery in Quebec in 2022 to the previous and next years
SELECT d.year, SUM(f.totalcases_change) AS total_cases,
LAG(SUM(f.totalcases_change), 1) OVER (ORDER BY d.year) AS prev_year_cases,
LEAD(SUM(f.totalcases_change), 1) OVER (ORDER BY d.year) AS next_year_cases
FROM FactTable f
JOIN DateDimension d ON f.dateID = d.dateID
JOIN ProvinceDimension p ON f.province = p.province
JOIN COVID19MetricsDimension c ON f.covidID = c.covidID
WHERE p.prname = 'Quebec'
GROUP BY d.year
ORDER BY d.year;