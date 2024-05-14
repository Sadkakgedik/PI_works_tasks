-- Create the table if it doesn't exist
USE test;

WITH MedianData AS (
    SELECT 
        country,
        (
            IF(COUNT(*) % 2 = 1, 
                SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(daily_vaccinations ORDER BY daily_vaccinations), ',', (COUNT(*) + 1) / 2), ',', -1),
                (SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(daily_vaccinations ORDER BY daily_vaccinations), ',', COUNT(*) / 2), ',', -1) + 
                 SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(daily_vaccinations ORDER BY daily_vaccinations), ',', (COUNT(*) / 2) + 1), ',', -1)) / 2
            )
        ) AS median_daily_vaccinations
    FROM 
        country_vaccination_stats
    GROUP BY 
        country
),
FilledData AS (
    SELECT 
        t.country,
        t.date,
        IFNULL(t.daily_vaccinations, m.median_daily_vaccinations) AS daily_vaccinations,
        t.vaccines
    FROM 
        country_vaccination_stats t
    LEFT JOIN 
        MedianData m ON t.country = m.country
),
AllDates AS (
    SELECT DISTINCT date FROM country_vaccination_stats
),
AllCountries AS (
    SELECT DISTINCT country FROM country_vaccination_stats
),
CrossJoin AS (
    SELECT 
        AllCountries.country,
        AllDates.date
    FROM 
        AllCountries
    CROSS JOIN 
        AllDates
)
SELECT 
    CrossJoin.country,
    CrossJoin.date,
    COALESCE(FilledData.daily_vaccinations, 0) AS daily_vaccinations,
    FilledData.vaccines
FROM 
    CrossJoin
LEFT JOIN 
    FilledData ON CrossJoin.country = FilledData.country AND CrossJoin.date = FilledData.date
ORDER BY 
    CrossJoin.country, CrossJoin.date;
