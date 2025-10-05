import os
import pandas as pd
from sqlalchemy import create_engine, text


DB_USER = "postgres"
DB_PASSWORD = "yourpassword"  
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "flight_analysis"  


DATA_PATH = 'data'
CSV_FILES = {
    'airports': 'Airports Data.csv',
    'flights': 'Flight Level Data.csv',
    'pnr_flights': 'PNR+Flight+Level+Data.csv',
    'pnr_remarks': 'PNR Remark Level Data.csv',
    'bags': 'Bag+Level+Data.csv',
    'flight_analysis': 'test_yourname.csv' 
}


TABLE_SCHEMAS = {
    'airports': """
        CREATE TABLE IF NOT EXISTS airports (
            airport_iata_code VARCHAR(10) PRIMARY KEY,
            iso_country_code VARCHAR(10)
        );
    """,
    'flights': """
        CREATE TABLE IF NOT EXISTS flights (
            flight_id SERIAL PRIMARY KEY, -- Added for easier joins
            company_id VARCHAR(5),
            flight_number INTEGER,
            scheduled_departure_date_local DATE,
            scheduled_departure_station_code VARCHAR(5),
            scheduled_arrival_station_code VARCHAR(5),
            scheduled_departure_datetime_local TIMESTAMP WITH TIME ZONE,
            scheduled_arrival_datetime_local TIMESTAMP WITH TIME ZONE,
            actual_departure_datetime_local TIMESTAMP WITH TIME ZONE,
            actual_arrival_datetime_local TIMESTAMP WITH TIME ZONE,
            total_seats INTEGER,
            fleet_type VARCHAR(20),
            carrier VARCHAR(20),
            scheduled_ground_time_minutes INTEGER,
            actual_ground_time_minutes INTEGER,
            minimum_turn_minutes INTEGER,
            UNIQUE (flight_number, scheduled_departure_datetime_local, scheduled_departure_station_code)
        );
    """,
    'pnr_flights': """
        CREATE TABLE IF NOT EXISTS pnr_flights (
            pnr_flight_id SERIAL PRIMARY KEY, -- Surrogate key
            company_id VARCHAR(5),
            flight_number INTEGER,
            scheduled_departure_date_local DATE,
            scheduled_departure_station_code VARCHAR(5),
            scheduled_arrival_station_code VARCHAR(5),
            record_locator VARCHAR(20),
            pnr_creation_date TIMESTAMP,
            total_pax INTEGER,
            is_child CHAR(1),
            basic_economy_ind INTEGER,
            is_stroller_user CHAR(1),
            lap_child_count INTEGER
        );
    """,
    'pnr_remarks': """
        CREATE TABLE IF NOT EXISTS pnr_remarks (
            remark_id SERIAL PRIMARY KEY, -- Surrogate key
            record_locator VARCHAR(20),
            pnr_creation_date TIMESTAMP,
            flight_number INTEGER,
            special_service_request VARCHAR(50)
        );
    """,
    'bags': """
        CREATE TABLE IF NOT EXISTS bags (
            bag_tag_unique_number VARCHAR(50) PRIMARY KEY,
            company_id VARCHAR(5),
            flight_number INTEGER,
            scheduled_departure_date_local DATE,
            scheduled_departure_station_code VARCHAR(5),
            scheduled_arrival_station_code VARCHAR(5),
            bag_tag_issue_date TIMESTAMP,
            bag_type VARCHAR(20)
        );
    """,
    'flight_analysis': """
        CREATE TABLE IF NOT EXISTS flight_analysis (
            analysis_id SERIAL PRIMARY KEY, -- Surrogate key
            flight_number INTEGER,
            scheduled_departure_datetime_local TIMESTAMP WITH TIME ZONE,
            scheduled_arrival_station_code VARCHAR(10),
            ground_time_pressure INTEGER,
            passenger_load_factor FLOAT,
            transfer_bag_ratio FLOAT,
            ssr_count INTEGER,
            hot_transfer INTEGER,
            child_count INTEGER,
            lap_child_count INTEGER,
            difficulty_score FLOAT,
            daily_difficulty_rank FLOAT,
            difficulty_class VARCHAR(20)
        );
    """
}

def main():
    """Main function to create and populate the database."""
    
    db_url = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    engine = create_engine(db_url)
    
    print(f"Connecting to database '{DB_NAME}'...")

    try:
        with engine.connect() as connection:
            print("Connection successful!")
            
            for table_name, schema in TABLE_SCHEMAS.items():
                print(f"Creating table '{table_name}'...")
                connection.execute(text(schema))
                connection.execute(text(f"TRUNCATE TABLE {table_name} RESTART IDENTITY CASCADE;"))
            
            connection.commit()
            print("\nAll tables created and cleared successfully.")

            for table_name, file_name in CSV_FILES.items():
                full_path = os.path.join(DATA_PATH, file_name)
                
                if not os.path.exists(full_path):
                    print(f"  Warning: File not found at '{full_path}'. Skipping table '{table_name}'.")
                    continue
                
                print(f"Loading data from '{file_name}' into '{table_name}'...")
                df = pd.read_csv(full_path)
                
                for col in df.columns:
                    if 'datetime' in col or '_date' in col:
                        df[col] = pd.to_datetime(df[col], errors='coerce')

               
                if table_name == 'flights':
                    key = ['flight_number', 'scheduled_departure_datetime_local', 'scheduled_departure_station_code']
                    df.drop_duplicates(subset=key, keep='first', inplace=True)
                    print(f"   -> Dropped duplicate rows from '{file_name}'.")
                
                if table_name == 'bags':
                    key = ['bag_tag_unique_number']
                    df.drop_duplicates(subset=key, keep='first', inplace=True)
                    print(f"   -> Dropped duplicate rows from '{file_name}'.")

                if table_name == 'flight_analysis':
                    
                    key = ['flight_number', 'scheduled_departure_datetime_local'] 
                    df.drop_duplicates(subset=key, keep='first', inplace=True)
                    print(f"   -> Dropped duplicate rows from '{file_name}'.")
              
                
                df.to_sql(
                    table_name,
                    con=engine,
                    if_exists='append',
                    index=False,
                    method='multi'
                )
                print(f" Data for '{table_name}' loaded successfully.")

    except Exception as e:
        print(f"\nAn error occurred: {e}")
    finally:
        print("\nScript finished.")

if _name_ == "_main_":
    main()