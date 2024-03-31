-- Drill down from Year to Month
SELECT d.Year, d.Month, SUM(f.resolved) AS total_resolved, SUM(f.Death) AS total_deaths
FROM Fact f
JOIN Date d ON f.DateID = d.DateID
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;