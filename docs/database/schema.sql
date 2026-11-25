-- Taxi Fare Prediction: database schema
-- PostgreSQL

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('passenger', 'dispatcher', 'admin')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    vehicle_class VARCHAR(40) NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0)
);

CREATE TABLE tariffs (
    tariff_id SERIAL PRIMARY KEY,
    tariff_name VARCHAR(60) NOT NULL,
    base_fare NUMERIC(10, 2) NOT NULL CHECK (base_fare >= 0),
    price_per_km NUMERIC(10, 2) NOT NULL CHECK (price_per_km >= 0),
    price_per_minute NUMERIC(10, 2) NOT NULL CHECK (price_per_minute >= 0)
);

CREATE TABLE fare_factors (
    factor_id SERIAL PRIMARY KEY,
    factor_name VARCHAR(60) NOT NULL UNIQUE,
    description TEXT
);

-- DFD data store D1: Trips
CREATE TABLE trips (
    trip_id SERIAL PRIMARY KEY,
    passenger_id INTEGER NOT NULL REFERENCES users(user_id),
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(vehicle_id),
    tariff_id INTEGER NOT NULL REFERENCES tariffs(tariff_id),
    origin VARCHAR(150) NOT NULL,
    destination VARCHAR(150) NOT NULL,
    distance_km NUMERIC(8, 2) NOT NULL CHECK (distance_km >= 0),
    duration_min NUMERIC(8, 2) NOT NULL CHECK (duration_min >= 0),
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- DFD data store D3: Prediction history (model version is recorded here)
CREATE TABLE predictions (
    prediction_id SERIAL PRIMARY KEY,
    trip_id INTEGER NOT NULL REFERENCES trips(trip_id),
    predicted_fare NUMERIC(10, 2) NOT NULL CHECK (predicted_fare >= 0),
    model_version VARCHAR(40) NOT NULL,
    predicted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Junction table: implements the M:N relationship between trips and fare factors
CREATE TABLE trip_factors (
    trip_id INTEGER NOT NULL REFERENCES trips(trip_id) ON DELETE CASCADE,
    factor_id INTEGER NOT NULL REFERENCES fare_factors(factor_id),
    factor_value VARCHAR(100) NOT NULL,
    PRIMARY KEY (trip_id, factor_id)
);

-- Sample data: 3-5 rows per table
INSERT INTO users (full_name, role) VALUES
('Aruzhan S.', 'passenger'),
('Dias K.', 'passenger'),
('Miras T.', 'dispatcher');

INSERT INTO vehicles (vehicle_class, capacity) VALUES
('Economy', 4),
('Comfort', 4),
('Van', 6);

INSERT INTO tariffs (tariff_name, base_fare, price_per_km, price_per_minute) VALUES
('Economy', 500.00, 90.00, 20.00),
('Comfort', 800.00, 120.00, 25.00),
('Van', 1000.00, 150.00, 30.00);

INSERT INTO fare_factors (factor_name, description) VALUES
('traffic', 'Traffic congestion level'),
('weather', 'Weather conditions'),
('peak_hour', 'High-demand time period');

INSERT INTO trips
(passenger_id, vehicle_id, tariff_id, origin, destination, distance_km, duration_min)
VALUES
(1, 1, 1, 'Abay Avenue', 'Dostyk Avenue', 5.20, 18),
(2, 2, 2, 'Airport', 'City Center', 18.50, 35),
(1, 1, 1, 'Mega Center', 'Central Park', 7.30, 22);

INSERT INTO predictions (trip_id, predicted_fare, model_version) VALUES
(1, 1120.00, 'v1.0'),
(2, 3935.00, 'v1.0'),
(3, 1377.00, 'v1.1');

INSERT INTO trip_factors (trip_id, factor_id, factor_value) VALUES
(1, 1, 'moderate'),
(1, 3, 'yes'),
(2, 2, 'rainy'),
(2, 1, 'heavy'),
(3, 3, 'no');

-- Query 1: JOIN across four tables
SELECT
    t.trip_id,
    u.full_name AS passenger,
    v.vehicle_class,
    ta.tariff_name,
    p.predicted_fare,
    p.model_version
FROM trips AS t
JOIN users AS u ON u.user_id = t.passenger_id
JOIN vehicles AS v ON v.vehicle_id = t.vehicle_id
JOIN tariffs AS ta ON ta.tariff_id = t.tariff_id
JOIN predictions AS p ON p.trip_id = t.trip_id
ORDER BY t.trip_id;

-- Query 2: GROUP BY - average predicted fare for each tariff
SELECT
    ta.tariff_name,
    COUNT(p.prediction_id) AS prediction_count,
    ROUND(AVG(p.predicted_fare), 2) AS average_predicted_fare
FROM tariffs AS ta
JOIN trips AS t ON t.tariff_id = ta.tariff_id
JOIN predictions AS p ON p.trip_id = t.trip_id
GROUP BY ta.tariff_id, ta.tariff_name
ORDER BY ta.tariff_name;
