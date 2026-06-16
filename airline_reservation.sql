-- ============================================================
--  AIRLINE RESERVATION SYSTEM
--  MySQL Workbench Safe Version
--  DBMS Mini Project | B.Tech CSE-ICB | DSATM
--
--  Team Members:
--    PRATEEK P ELLUR    - 1DT24IC029
--    SANJAY             - 1DT24IC035
--    PRATHAM ARYA       - 1DT24IC030
--    AS VIJAY KUMAR     - 1DT24IC001
--
--  HOW TO RUN IN MYSQL WORKBENCH:
--  1. File > Open SQL Script > select this file
--  2. Press Ctrl+Shift+Enter  (Run ALL)
--  3. Check Action Output at bottom for green ticks
-- ============================================================

-- ============================================================
--  STEP 1: CREATE DATABASE
-- ============================================================

DROP DATABASE IF EXISTS airline_reservation;
CREATE DATABASE airline_reservation;
USE airline_reservation;

-- ============================================================
--  STEP 2: DDL — CREATE TABLES
-- ============================================================

CREATE TABLE airports (
    airport_id    INT PRIMARY KEY AUTO_INCREMENT,
    iata_code     CHAR(3) UNIQUE NOT NULL,
    airport_name  VARCHAR(100) NOT NULL,
    city          VARCHAR(50) NOT NULL,
    country       VARCHAR(50) NOT NULL
);

CREATE TABLE aircraft (
    aircraft_id     INT PRIMARY KEY AUTO_INCREMENT,
    model           VARCHAR(50) NOT NULL,
    total_seats     INT NOT NULL,
    economy_seats   INT NOT NULL,
    business_seats  INT NOT NULL
);

CREATE TABLE flights (
    flight_id          INT PRIMARY KEY AUTO_INCREMENT,
    flight_number      VARCHAR(10) UNIQUE NOT NULL,
    origin_airport_id  INT NOT NULL,
    dest_airport_id    INT NOT NULL,
    aircraft_id        INT NOT NULL,
    departure_time     DATETIME NOT NULL,
    arrival_time       DATETIME NOT NULL,
    status             ENUM('SCHEDULED','DELAYED','CANCELLED','COMPLETED') DEFAULT 'SCHEDULED',
    FOREIGN KEY (origin_airport_id) REFERENCES airports(airport_id),
    FOREIGN KEY (dest_airport_id)   REFERENCES airports(airport_id),
    FOREIGN KEY (aircraft_id)       REFERENCES aircraft(aircraft_id),
    CHECK (arrival_time > departure_time)
);

CREATE TABLE passengers (
    passenger_id    INT PRIMARY KEY AUTO_INCREMENT,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone           VARCHAR(15),
    passport_number VARCHAR(20) UNIQUE,
    date_of_birth   DATE NOT NULL
);

CREATE TABLE seats (
    seat_id      INT PRIMARY KEY AUTO_INCREMENT,
    flight_id    INT NOT NULL,
    seat_number  VARCHAR(5) NOT NULL,
    class        ENUM('ECONOMY','BUSINESS') NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    price        DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id),
    UNIQUE (flight_id, seat_number)
);

CREATE TABLE bookings (
    booking_id   INT PRIMARY KEY AUTO_INCREMENT,
    passenger_id INT NOT NULL,
    seat_id      INT UNIQUE NOT NULL,
    booking_date DATETIME DEFAULT NOW(),
    status       ENUM('CONFIRMED','CANCELLED','WAITLISTED') DEFAULT 'CONFIRMED',
    pnr          CHAR(6) UNIQUE NOT NULL,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id),
    FOREIGN KEY (seat_id)      REFERENCES seats(seat_id)
);

CREATE TABLE payments (
    payment_id       INT PRIMARY KEY AUTO_INCREMENT,
    booking_id       INT UNIQUE NOT NULL,
    amount           DECIMAL(10,2) NOT NULL,
    payment_method   ENUM('CARD','UPI','NETBANKING','WALLET') NOT NULL,
    payment_status   ENUM('PENDING','SUCCESS','FAILED','REFUNDED') DEFAULT 'PENDING',
    transaction_date DATETIME DEFAULT NOW(),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE cancellations (
    cancel_id     INT PRIMARY KEY AUTO_INCREMENT,
    booking_id    INT NOT NULL,
    cancelled_at  DATETIME DEFAULT NOW(),
    reason        TEXT,
    refund_amount DECIMAL(10,2),
    refund_status ENUM('PENDING','PROCESSED','DENIED') DEFAULT 'PENDING',
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

-- ============================================================
--  STEP 3: TRIGGERS
--  (MySQL Workbench handles DELIMITER automatically)
-- ============================================================

-- Trigger 1: Lock seat when booking is made
DROP TRIGGER IF EXISTS mark_seat_unavailable;
DELIMITER $$
CREATE TRIGGER mark_seat_unavailable
AFTER INSERT ON bookings FOR EACH ROW
BEGIN
    UPDATE seats
    SET is_available = FALSE
    WHERE seat_id = NEW.seat_id;
END $$
DELIMITER ;

-- Trigger 2: Release seat when cancellation is recorded
DROP TRIGGER IF EXISTS restore_seat_on_cancel;
DELIMITER $$
CREATE TRIGGER restore_seat_on_cancel
AFTER INSERT ON cancellations FOR EACH ROW
BEGIN
    UPDATE seats s
    JOIN bookings b ON b.seat_id = s.seat_id
    SET s.is_available = TRUE
    WHERE b.booking_id = NEW.booking_id;
END $$
DELIMITER ;

-- ============================================================
--  STEP 4: SAMPLE DATA
-- ============================================================

-- Airports
INSERT INTO airports (iata_code, airport_name, city, country) VALUES
('BLR', 'Kempegowda International Airport',              'Bengaluru', 'India'),
('DEL', 'Indira Gandhi International Airport',           'New Delhi',  'India'),
('BOM', 'Chhatrapati Shivaji Maharaj International Airport', 'Mumbai', 'India'),
('MAA', 'Chennai International Airport',                 'Chennai',    'India'),
('HYD', 'Rajiv Gandhi International Airport',            'Hyderabad',  'India');

-- Aircraft
INSERT INTO aircraft (model, total_seats, economy_seats, business_seats) VALUES
('Boeing 737-800',  162, 138, 24),
('Airbus A320',     150, 126, 24),
('Boeing 777-300',  350, 308, 42);

-- Flights
INSERT INTO flights (flight_number, origin_airport_id, dest_airport_id, aircraft_id, departure_time, arrival_time, status) VALUES
('AI-204', 1, 2, 1, '2026-06-05 06:00:00', '2026-06-05 08:45:00', 'SCHEDULED'),
('6E-301', 1, 3, 2, '2026-06-05 09:30:00', '2026-06-05 11:15:00', 'SCHEDULED'),
('SG-415', 2, 4, 1, '2026-06-05 13:00:00', '2026-06-05 15:30:00', 'SCHEDULED'),
('AI-890', 3, 5, 3, '2026-06-05 17:00:00', '2026-06-05 18:20:00', 'DELAYED'),
('6E-112', 4, 1, 2, '2026-06-05 20:00:00', '2026-06-05 21:45:00', 'SCHEDULED');

-- Seats for Flight AI-204 (BLR to DEL) -- 10 sample seats
INSERT INTO seats (flight_id, seat_number, class, is_available, price) VALUES
(1, '1A',  'BUSINESS', TRUE, 12500.00),
(1, '1B',  'BUSINESS', TRUE, 12500.00),
(1, '2A',  'BUSINESS', TRUE, 11800.00),
(1, '4A',  'ECONOMY',  TRUE,  4200.00),
(1, '4B',  'ECONOMY',  TRUE,  4200.00),
(1, '4C',  'ECONOMY',  TRUE,  4200.00),
(1, '10A', 'ECONOMY',  TRUE,  3800.00),
(1, '10B', 'ECONOMY',  TRUE,  3800.00),
(1, '15A', 'ECONOMY',  TRUE,  3500.00),
(1, '15B', 'ECONOMY',  TRUE,  3500.00);

-- Seats for Flight 6E-301 (BLR to BOM) -- 6 sample seats
INSERT INTO seats (flight_id, seat_number, class, is_available, price) VALUES
(2, '1A',  'BUSINESS', TRUE, 9800.00),
(2, '3A',  'ECONOMY',  TRUE, 2900.00),
(2, '3B',  'ECONOMY',  TRUE, 2900.00),
(2, '8A',  'ECONOMY',  TRUE, 2600.00),
(2, '8B',  'ECONOMY',  TRUE, 2600.00),
(2, '12A', 'ECONOMY',  TRUE, 2400.00);

-- Seats for Flight SG-415 (DEL to MAA)
INSERT INTO seats (flight_id, seat_number, class, is_available, price) VALUES
(3, '1A',  'BUSINESS', TRUE, 10500.00),
(3, '3A',  'ECONOMY',  TRUE,  3200.00),
(3, '3B',  'ECONOMY',  TRUE,  3200.00),
(3, '7A',  'ECONOMY',  TRUE,  2900.00),
(3, '7B',  'ECONOMY',  TRUE,  2900.00);

-- Seats for Flight AI-890 (BOM to HYD)
INSERT INTO seats (flight_id, seat_number, class, is_available, price) VALUES
(4, '1A',  'BUSINESS', TRUE, 8500.00),
(4, '2A',  'BUSINESS', TRUE, 8500.00),
(4, '5A',  'ECONOMY',  TRUE, 2200.00),
(4, '5B',  'ECONOMY',  TRUE, 2200.00),
(4, '9A',  'ECONOMY',  TRUE, 2000.00);

-- Seats for Flight 6E-112 (MAA to BLR)
INSERT INTO seats (flight_id, seat_number, class, is_available, price) VALUES
(5, '1A',  'BUSINESS', TRUE, 7800.00),
(5, '4A',  'ECONOMY',  TRUE, 1900.00),
(5, '4B',  'ECONOMY',  TRUE, 1900.00),
(5, '8A',  'ECONOMY',  TRUE, 1700.00),
(5, '8B',  'ECONOMY',  TRUE, 1700.00);

-- Passengers
INSERT INTO passengers (full_name, email, phone, passport_number, date_of_birth) VALUES
('Priya Sharma',   'priya.sharma@gmail.com',   '9876543210', 'P1234567', '1995-03-14'),
('Rahul Mehta',    'rahul.mehta@gmail.com',    '9845123456', 'P2345678', '1990-07-22'),
('Ananya Iyer',    'ananya.iyer@yahoo.com',    '9731234567', 'P3456789', '1998-11-05'),
('Karan Verma',    'karan.verma@outlook.com',  '9654321098', 'P4567890', '1985-01-30'),
('Sneha Nair',     'sneha.nair@gmail.com',     '9123456789', 'P5678901', '2000-06-18'),
('Arjun Patel',    'arjun.patel@gmail.com',    '9012345678', 'P6789012', '1993-09-27'),
('Divya Reddy',    'divya.reddy@gmail.com',    '8901234567', 'P7890123', '1997-04-12'),
('Vikram Singh',   'vikram.singh@yahoo.com',   '8890123456', 'P8901234', '1988-12-03');

-- Bookings (triggers fire automatically and mark seats as unavailable)
INSERT INTO bookings (passenger_id, seat_id, booking_date, status, pnr) VALUES
(1, 4,  '2026-06-01 10:00:00', 'CONFIRMED', 'PNR001'),
(2, 5,  '2026-06-01 10:30:00', 'CONFIRMED', 'PNR002'),
(3, 1,  '2026-06-01 11:00:00', 'CONFIRMED', 'PNR003'),
(4, 11, '2026-06-01 11:30:00', 'CONFIRMED', 'PNR004'),
(5, 7,  '2026-06-01 12:00:00', 'CONFIRMED', 'PNR005'),
(6, 12, '2026-06-01 12:30:00', 'CONFIRMED', 'PNR006'),
(7, 6,  '2026-06-01 13:00:00', 'CONFIRMED', 'PNR007'),
(8, 2,  '2026-06-01 13:30:00', 'CONFIRMED', 'PNR008');

-- Payments
INSERT INTO payments (booking_id, amount, payment_method, payment_status, transaction_date) VALUES
(1,  4200.00,  'UPI',        'SUCCESS', '2026-06-01 10:01:00'),
(2,  4200.00,  'CARD',       'SUCCESS', '2026-06-01 10:31:00'),
(3, 12500.00,  'NETBANKING', 'SUCCESS', '2026-06-01 11:01:00'),
(4,  9800.00,  'CARD',       'SUCCESS', '2026-06-01 11:31:00'),
(5,  3800.00,  'WALLET',     'SUCCESS', '2026-06-01 12:01:00'),
(6,  2900.00,  'UPI',        'SUCCESS', '2026-06-01 12:31:00'),
(7,  4200.00,  'CARD',       'SUCCESS', '2026-06-01 13:01:00'),
(8, 12500.00,  'NETBANKING', 'SUCCESS', '2026-06-01 13:31:00');

-- ============================================================
--  STEP 5: DEMO QUERIES
-- ============================================================

-- -------------------------------------------------------
-- DEMO QUERY 1: Show all seats on flight AI-204 (BLR to DEL)
--   Point: is_available = FALSE on booked seats (trigger fired)
-- -------------------------------------------------------
SELECT
    s.seat_number,
    s.class,
    s.price,
    CASE WHEN s.is_available THEN 'AVAILABLE' ELSE 'BOOKED' END AS seat_status
FROM seats s
WHERE s.flight_id = 1
ORDER BY s.seat_number;

-- -------------------------------------------------------
-- DEMO QUERY 2: Full booking details with passenger and flight info
--   Point: demonstrates 6-table JOIN
-- -------------------------------------------------------
SELECT
    b.pnr,
    p.full_name,
    CONCAT(a1.iata_code, ' -> ', a2.iata_code) AS route,
    f.flight_number,
    f.departure_time,
    s.seat_number,
    s.class,
    pay.amount,
    pay.payment_method,
    b.status AS booking_status
FROM bookings b
JOIN passengers p  ON p.passenger_id = b.passenger_id
JOIN seats s       ON s.seat_id      = b.seat_id
JOIN flights f     ON f.flight_id    = s.flight_id
JOIN airports a1   ON a1.airport_id  = f.origin_airport_id
JOIN airports a2   ON a2.airport_id  = f.dest_airport_id
JOIN payments pay  ON pay.booking_id = b.booking_id
ORDER BY b.booking_id;

-- -------------------------------------------------------
-- DEMO QUERY 3: Total revenue per flight
--   Point: GROUP BY + SUM + JOIN
-- -------------------------------------------------------
SELECT
    f.flight_number,
    CONCAT(a1.city, ' -> ', a2.city) AS route,
    COUNT(b.booking_id)              AS total_bookings,
    SUM(pay.amount)                  AS total_revenue
FROM flights f
JOIN airports a1   ON a1.airport_id  = f.origin_airport_id
JOIN airports a2   ON a2.airport_id  = f.dest_airport_id
JOIN seats s       ON s.flight_id    = f.flight_id
JOIN bookings b    ON b.seat_id      = s.seat_id
JOIN payments pay  ON pay.booking_id = b.booking_id
WHERE pay.payment_status = 'SUCCESS'
GROUP BY f.flight_id, f.flight_number, route
ORDER BY total_revenue DESC;

-- -------------------------------------------------------
-- DEMO QUERY 4: Business vs Economy revenue breakdown
--   Point: ENUM filtering + GROUP BY class
-- -------------------------------------------------------
SELECT
    s.class,
    COUNT(b.booking_id) AS bookings,
    SUM(pay.amount)     AS revenue
FROM bookings b
JOIN seats s      ON s.seat_id      = b.seat_id
JOIN payments pay ON pay.booking_id = b.booking_id
WHERE pay.payment_status = 'SUCCESS'
GROUP BY s.class;

-- -------------------------------------------------------
-- DEMO QUERY 5: THE CANCELLATION STORY
--   Priya (PNR001) cancels her booking
--   Watch: seat 4A flips back to AVAILABLE (trigger fires)
-- -------------------------------------------------------

-- Step A: Check seat 4A BEFORE cancellation
SELECT seat_number, is_available FROM seats WHERE seat_id = 4;

-- Step B: Update booking status to CANCELLED
-- [MANUAL DEMO FOR EXAMINER: Select and run the query below]
-- UPDATE bookings SET status = 'CANCELLED' WHERE pnr = 'PNR001';

-- Step C: Insert cancellation record (this fires the trigger)
-- [MANUAL DEMO FOR EXAMINER: Select and run the query below]
-- INSERT INTO cancellations (booking_id, reason, refund_amount, refund_status)
-- VALUES (1, 'Change of travel plans', 3780.00, 'PENDING');

-- Step D: Update payment to REFUNDED
-- [MANUAL DEMO FOR EXAMINER: Select and run the query below]
-- UPDATE payments SET payment_status = 'REFUNDED' WHERE booking_id = 1;

-- Step E: Check seat 4A AFTER cancellation -- should now be TRUE (AVAILABLE)
-- [MANUAL DEMO FOR EXAMINER: Select and run the query below]
-- SELECT seat_number, is_available FROM seats WHERE seat_id = 4;

-- Step F: Show pending refunds
SELECT
    b.pnr,
    p.full_name,
    c.refund_amount,
    c.refund_status,
    c.cancelled_at
FROM cancellations c
JOIN bookings b   ON b.booking_id   = c.booking_id
JOIN passengers p ON p.passenger_id = b.passenger_id
WHERE c.refund_status = 'PENDING';

-- -------------------------------------------------------
-- DEMO QUERY 6: Flight occupancy percentage
--   Point: calculated column, LEFT JOIN, ROUND()
-- -------------------------------------------------------
SELECT
    f.flight_number,
    CONCAT(a1.city, ' -> ', a2.city)                            AS route,
    ac.total_seats,
    COUNT(b.booking_id)                                         AS booked_seats,
    ROUND(COUNT(b.booking_id) * 100.0 / ac.total_seats, 1)     AS occupancy_pct
FROM flights f
JOIN aircraft ac     ON ac.aircraft_id = f.aircraft_id
JOIN airports a1     ON a1.airport_id  = f.origin_airport_id
JOIN airports a2     ON a2.airport_id  = f.dest_airport_id
LEFT JOIN seats s    ON s.flight_id    = f.flight_id
LEFT JOIN bookings b ON b.seat_id      = s.seat_id AND b.status = 'CONFIRMED'
GROUP BY f.flight_id, f.flight_number, route, ac.total_seats
ORDER BY occupancy_pct DESC;

-- -------------------------------------------------------
-- BONUS: Quick table row counts summary
-- -------------------------------------------------------
SELECT 'airports'      AS table_name, COUNT(*) AS row_count FROM airports     UNION ALL
SELECT 'aircraft',                    COUNT(*)              FROM aircraft      UNION ALL
SELECT 'flights',                     COUNT(*)              FROM flights       UNION ALL
SELECT 'passengers',                  COUNT(*)              FROM passengers    UNION ALL
SELECT 'seats',                       COUNT(*)              FROM seats         UNION ALL
SELECT 'bookings',                    COUNT(*)              FROM bookings      UNION ALL
SELECT 'payments',                    COUNT(*)              FROM payments      UNION ALL
SELECT 'cancellations',               COUNT(*)              FROM cancellations;

-- ============================================================
--  END OF SCRIPT
-- ============================================================
