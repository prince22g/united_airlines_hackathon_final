SELECT
    -- Calculate the average delay in minutes for all flights.
    -- EXTRACT(EPOCH FROM ...) gets the total seconds, which we divide by 60.
    AVG(EXTRACT(EPOCH FROM (actual_departure_datetime_local - scheduled_departure_datetime_local)) / 60) AS average_delay_minutes,

    -- Calculate the percentage of flights that departed late.
    -- The FILTER clause is an efficient way to count only rows that meet a condition.
    (COUNT(*) FILTER (WHERE actual_departure_datetime_local > scheduled_departure_datetime_local) * 100.0 / COUNT(*)) AS percentage_late_flights
FROM
    flights
WHERE
    scheduled_departure_station_code = 'ORD';


SELECT
    COUNT(*) AS flights_with_insufficient_ground_time
FROM
    flights
WHERE
    scheduled_ground_time_minutes < minimum_turn_minutes
    AND scheduled_departure_station_code = 'ORD';

WITH BagCounts AS (
    -- First, count the number of 'Transfer' and 'Origin' bags for each flight.
    SELECT
        flight_number,
        scheduled_departure_date_local,
        COUNT(*) FILTER (WHERE bag_type = 'Transfer') AS transfer_bags,
        COUNT(*) FILTER (WHERE bag_type = 'Origin') AS checked_bags
    FROM
        bags
    WHERE
        scheduled_departure_station_code = 'ORD'
    GROUP BY
        flight_number,
        scheduled_departure_date_local
),
BagRatios AS (
    -- Next, calculate the ratio for each flight, avoiding division by zero.
    SELECT
        CASE
            WHEN checked_bags > 0 THEN transfer_bags::REAL / checked_bags
            ELSE 0
        END AS transfer_to_checked_ratio
    FROM
        BagCounts
)
-- Finally, calculate the average of all the individual flight ratios.
SELECT
    AVG(transfer_to_checked_ratio) AS average_transfer_ratio
FROM
    BagRatios;

SELECT
    flight_number,
    scheduled_departure_datetime_local,
    scheduled_arrival_station_code,
    difficulty_score,
    daily_difficulty_rank,
    difficulty_class
FROM
    flight_difficulty_scores
WHERE
    -- Filter for a specific day's departures
    DATE(scheduled_departure_datetime_local) = '2025-08-11'
    AND difficulty_class = 'Difficult'
ORDER BY
    daily_difficulty_rank; -- Order by the daily rank

SELECT
    scheduled_arrival_station_code,
    COUNT(*) AS count_of_difficult_flights
FROM
    flight_difficulty_scores
WHERE
    difficulty_class = 'Difficult'
GROUP BY
    scheduled_arrival_station_code
ORDER BY
    count_of_difficult_flights DESC
LIMIT 10;

SELECT
    'Difficult STL Flights' AS category,
    AVG(ground_time_pressure) AS avg_ground_time_pressure,
    AVG(transfer_bag_ratio) AS avg_transfer_bag_ratio
FROM
    flight_difficulty_scores
WHERE
    scheduled_arrival_station_code = 'STL'
    AND difficulty_class = 'Difficult'

UNION ALL

SELECT
    'All ORD Departures' AS category,
    AVG(ground_time_pressure) AS avg_ground_time_pressure,
    AVG(transfer_bag_ratio) AS avg_transfer_bag_ratio
FROM
    flight_difficulty_scores;