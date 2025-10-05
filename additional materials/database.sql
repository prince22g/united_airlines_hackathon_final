-- -- This script creates the schema for the United Airlines Flight Difficulty project.
-- -- It includes tables for the raw data and a final table for the analysis results.

-- -- Drop tables if they already exist to ensure a clean setup
-- DROP TABLE IF EXISTS flight_difficulty_scores;
-- DROP TABLE IF EXISTS airports;
-- DROP TABLE IF EXISTS bags;
-- DROP TABLE IF EXISTS pnr_remarks;
-- DROP TABLE IF EXISTS pnr_flights;
-- DROP TABLE IF EXISTS flights;

-- -- Table 1: Raw Flight Level Data
-- -- Stores the core operational details for each flight.
-- CREATE TABLE flights (
--     company_id VARCHAR(5),
--     flight_number INTEGER,
--     scheduled_departure_date_local DATE,
--     scheduled_departure_station_code VARCHAR(5),
--     scheduled_arrival_station_code VARCHAR(5),
--     scheduled_departure_datetime_local TIMESTAMP,
--     scheduled_arrival_datetime_local TIMESTAMP,
--     actual_departure_datetime_local TIMESTAMP,
--     actual_arrival_datetime_local TIMESTAMP,
--     total_seats INTEGER,
--     fleet_type VARCHAR(50),
--     carrier VARCHAR(20),
--     scheduled_ground_time_minutes INTEGER,
--     actual_ground_time_minutes INTEGER,
--     minimum_turn_minutes INTEGER
-- );

-- -- Table 2: Raw PNR (Passenger Name Record) Flight Data
-- -- Stores passenger information linked to a specific flight.
-- CREATE TABLE pnr_flights (
--     company_id VARCHAR(5),
--     flight_number INTEGER,
--     scheduled_departure_date_local DATE,
--     scheduled_departure_station_code VARCHAR(5),
--     scheduled_arrival_station_code VARCHAR(5),
--     record_locator VARCHAR(10),
--     pnr_creation_date DATE,
--     total_pax INTEGER,
--     is_child VARCHAR(1),
--     basic_economy_ind INTEGER,
--     is_stroller_user VARCHAR(1),
--     lap_child_count INTEGER
-- );

-- -- Table 3: Raw PNR Remarks Data
-- -- Stores special service requests (SSRs) linked to a PNR.
-- CREATE TABLE pnr_remarks (
--     record_locator VARCHAR(10),
--     pnr_creation_date DATE,
--     flight_number INTEGER,
--     special_service_request VARCHAR(255)
-- );

-- -- Table 4: Raw Baggage Level Data
-- -- Stores details for each individual bag.
-- CREATE TABLE bags (
--     company_id VARCHAR(5),
--     flight_number INTEGER,
--     scheduled_departure_date_local DATE,
--     scheduled_departure_station_code VARCHAR(5),
--     scheduled_arrival_station_code VARCHAR(5),
--     bag_tag_unique_number VARCHAR(50),
--     bag_tag_issue_date TIMESTAMP,
--     bag_type VARCHAR(50)
-- );

-- -- Table 5: Airport Information
-- -- A lookup table for airport codes and countries.
-- CREATE TABLE airports (
--     airport_iata_code VARCHAR(5),
--     iso_country_code VARCHAR(5)
-- );

-- -- Table 6: Final Analysis Output
-- -- This table will store the results of your Python analysis.
-- -- It is designed to be cleared and re-populated each time the analysis is run.
-- CREATE TABLE flight_difficulty_scores (
--     flight_number INTEGER,
--     scheduled_departure_datetime_local TIMESTAMP,
--     scheduled_arrival_station_code VARCHAR(5),
--     ground_time_pressure REAL,
--     passenger_load_factor REAL,
--     transfer_bag_ratio REAL,
--     ssr_count REAL,
--     hot_transfer REAL,
--     child_count REAL,
--     lap_child_count REAL,
--     difficulty_score REAL,
--     daily_difficulty_rank INTEGER,
--     difficulty_class VARCHAR(20)
-- );

-- -- A primary key could be added to flight_difficulty_scores for better indexing
-- -- ALTER TABLE flight_difficulty_scores ADD PRIMARY KEY (flight_number, scheduled_departure_datetime_local);

-- ALTER TABLE flight_difficulty_scores ALTER COLUMN daily_difficulty_rank TYPE REAL;
-- This script creates a relational schema for the United Airlines Flight Difficulty project.
-- It uses primary and foreign keys to enforce data integrity and define relationships.

-- Drop tables if they already exist, using CASCADE to remove dependent objects like foreign keys.
DROP TABLE IF EXISTS flight_difficulty_scores;
DROP TABLE IF EXISTS pnr_remarks;
DROP TABLE IF EXISTS bags;
DROP TABLE IF EXISTS pnr_flights;
DROP TABLE IF EXISTS airports;
DROP TABLE IF EXISTS flights;

-- Table 1: Raw Flight Level Data
-- The central "parent" table. Each flight gets a unique, auto-incrementing ID.
CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY, -- Unique integer ID for each flight
    company_id VARCHAR(5),
    flight_number INTEGER,
    scheduled_departure_date_local DATE,
    scheduled_departure_station_code VARCHAR(5),
    scheduled_arrival_station_code VARCHAR(5),
    scheduled_departure_datetime_local TIMESTAMP,
    scheduled_arrival_datetime_local TIMESTAMP,
    actual_departure_datetime_local TIMESTAMP,
    actual_arrival_datetime_local TIMESTAMP,
    total_seats INTEGER,
    fleet_type VARCHAR(50),
    carrier VARCHAR(20),
    scheduled_ground_time_minutes INTEGER,
    actual_ground_time_minutes INTEGER,
    minimum_turn_minutes INTEGER,
    -- Add a unique constraint on the natural key to prevent duplicate flight entries
    UNIQUE (flight_number, scheduled_departure_datetime_local)
);

-- Table 2: Raw PNR (Passenger Name Record) Flight Data
-- Each row is a passenger record, linked to a flight via a foreign key.
CREATE TABLE pnr_flights (
    pnr_flight_id SERIAL PRIMARY KEY, -- Unique ID for each passenger-flight entry
    flight_id INTEGER REFERENCES flights(flight_id), -- Foreign key linking to the flights table
    company_id VARCHAR(5),
    flight_number INTEGER,
    scheduled_departure_date_local DATE,
    scheduled_departure_station_code VARCHAR(5),
    scheduled_arrival_station_code VARCHAR(5),
    record_locator VARCHAR(10),
    pnr_creation_date DATE,
    total_pax INTEGER,
    is_child VARCHAR(1),
    basic_economy_ind INTEGER,
    is_stroller_user VARCHAR(1),
    lap_child_count INTEGER
);

-- Table 3: Raw PNR Remarks Data
-- Each row is a special service request, linked to a specific passenger on a flight.
CREATE TABLE pnr_remarks (
    remark_id SERIAL PRIMARY KEY, -- Unique ID for each remark
    pnr_flight_id INTEGER REFERENCES pnr_flights(pnr_flight_id), -- Foreign key linking to the pnr_flights table
    record_locator VARCHAR(10),
    pnr_creation_date DATE,
    flight_number INTEGER,
    special_service_request VARCHAR(255)
);

-- Table 4: Raw Baggage Level Data
-- Each row is a bag, linked to a flight via a foreign key.
CREATE TABLE bags (
    bag_id SERIAL PRIMARY KEY, -- Unique ID for each bag
    flight_id INTEGER REFERENCES flights(flight_id), -- Foreign key linking to the flights table
    company_id VARCHAR(5),
    flight_number INTEGER,
    scheduled_departure_date_local DATE,
    scheduled_departure_station_code VARCHAR(5),
    scheduled_arrival_station_code VARCHAR(5),
    bag_tag_unique_number VARCHAR(50),
    bag_tag_issue_date TIMESTAMP,
    bag_type VARCHAR(50)
);

-- Table 5: Airport Information
-- A lookup table for airport codes.
CREATE TABLE airports (
    airport_iata_code VARCHAR(5) PRIMARY KEY, -- The airport code is the unique identifier
    iso_country_code VARCHAR(5)
);

-- Table 6: Final Analysis Output
-- This table stores the results, also linked back to the original flight.
CREATE TABLE flight_difficulty_scores (
    score_id SERIAL PRIMARY KEY, -- Unique ID for each score entry
    flight_id INTEGER REFERENCES flights(flight_id), -- Foreign key linking back to the original flight
    flight_number INTEGER,
    scheduled_departure_datetime_local TIMESTAMP,
    scheduled_arrival_station_code VARCHAR(5),
    ground_time_pressure REAL,
    passenger_load_factor REAL,
    transfer_bag_ratio REAL,
    ssr_count REAL,
    hot_transfer REAL,
    child_count REAL,
    lap_child_count REAL,
    difficulty_score REAL,
    daily_difficulty_rank REAL, -- Set to REAL to accept float values like '297.0'
    difficulty_class VARCHAR(20)
);
