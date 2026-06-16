# Airline Reservation System
## DBMS Mini Project Report
### B.Tech CSE-ICB | DSATM | June 2026

---

## Team Members

| Name | USN |
|------|-----|
| Prateek P Ellur | 1DT24IC029 |
| Sanjay | 1DT24IC035 |
| Pratham Arya | 1DT24IC030 |
| AS Vijay Kumar | 1DT24IC001 |

**Guide:** Department of Computer Science and Engineering  
**Institute:** Dayananda Sagar Academy of Technology & Management (DSATM), Bengaluru  
**Database:** MySQL 8.0  

---

## 1. Project Overview

The **Airline Reservation System** is a relational database designed to manage the end-to-end lifecycle of airline bookings — from flight scheduling and seat inventory to passenger bookings, payments, and cancellations.

### Objectives

- Design a normalized relational schema with 8 tables across 4 entity domains
- Implement referential integrity using FOREIGN KEYs and business rules using CHECK constraints and ENUM types
- Automate seat availability management using MySQL AFTER INSERT triggers
- Demonstrate complex data retrieval using multi-table JOINs, GROUP BY aggregations, and subqueries
- Simulate a real cancellation workflow showing trigger-based seat release

---

## 2. Entity-Relationship Diagram

```
┌─────────────┐       ┌─────────────────┐       ┌─────────────┐
│  airports   │ 1───M │    flights      │ M───1 │  aircraft   │
│  ─────────  │       │  ─────────────  │       │  ─────────  │
│  airport_id │       │  flight_id      │       │  aircraft_id│
│  iata_code  │       │  flight_number  │       │  model      │
│  city       │       │  origin_id (FK) │       │  total_seats│
│  country    │       │  dest_id (FK)   │       │  eco_seats  │
└─────────────┘       │  aircraft_id(FK)│       │  biz_seats  │
                      │  departure_time │       └─────────────┘
                      │  arrival_time   │
                      │  status (ENUM)  │
                      └────────┬────────┘
                               │ 1
                               │
                               M
                      ┌────────┴────────┐
                      │     seats       │
                      │  ─────────────  │
                      │  seat_id        │
                      │  flight_id (FK) │
                      │  seat_number    │
                      │  class (ENUM)   │
                      │  is_available ◄─┼─── Trigger: mark_seat_unavailable
                      │  price          │◄── Trigger: restore_seat_on_cancel
                      └────────┬────────┘
                               │ 1
                               │
                               M
                      ┌────────┴────────┐       ┌─────────────┐
                      │   bookings      │ M───1 │  passengers │
                      │  ─────────────  │       │  ─────────  │
                      │  booking_id     │       │ passenger_id│
                      │  passenger_id(FK│       │  full_name  │
                      │  seat_id (FK)   │       │  email      │
                      │  booking_date   │       │  phone      │
                      │  status (ENUM)  │       │  passport_no│
                      │  pnr (UNIQUE)   │       │  dob        │
                      └────┬────────────┘       └─────────────┘
                           │ 1                  
                   ┌───────┴───────┐            
                   │               │            
                   M               M            
        ┌──────────┴──┐   ┌────────┴────────┐  
        │  payments   │   │ cancellations   │  
        │  ─────────  │   │  ─────────────  │  
        │  payment_id │   │  cancel_id      │  
        │ booking_id  │   │  booking_id(FK) │  
        │  amount     │   │  cancelled_at   │  
        │  method     │   │  reason         │  
        │  status     │   │  refund_amount  │  
        └─────────────┘   │  refund_status  │  
                          └─────────────────┘  
```

---

## 3. Table Descriptions

### 3.1 `airports`
Stores information about all airports in the system.

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| airport_id | INT | PK, AUTO_INCREMENT | Surrogate primary key |
| iata_code | CHAR(3) | UNIQUE, NOT NULL | 3-letter IATA code (e.g., BLR) |
| airport_name | VARCHAR(100) | NOT NULL | Full official name |
| city | VARCHAR(50) | NOT NULL | City of location |
| country | VARCHAR(50) | NOT NULL | Country |

### 3.2 `aircraft`
Stores aircraft model information including seat configuration.

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| aircraft_id | INT | PK, AUTO_INCREMENT | Surrogate primary key |
| model | VARCHAR(50) | NOT NULL | Aircraft model name |
| total_seats | INT | NOT NULL | Total seat count |
| economy_seats | INT | NOT NULL | Economy section count |
| business_seats | INT | NOT NULL | Business section count |

### 3.3 `flights`
Core flight scheduling table. References both airports (twice) and aircraft.

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| flight_id | INT | PK | Surrogate primary key |
| flight_number | VARCHAR(10) | UNIQUE | e.g., AI-204 |
| origin_airport_id | INT | FK → airports | Departure airport |
| dest_airport_id | INT | FK → airports | Arrival airport |
| aircraft_id | INT | FK → aircraft | Operating aircraft |
| departure_time | DATETIME | NOT NULL | Scheduled departure |
| arrival_time | DATETIME | CHECK (> departure) | Scheduled arrival |
| status | ENUM | SCHEDULED/DELAYED/CANCELLED/COMPLETED | Flight status |

### 3.4 `passengers`
Passenger PII (personally identifiable information).

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| passenger_id | INT | PK | Surrogate primary key |
| full_name | VARCHAR(100) | NOT NULL | Full name |
| email | VARCHAR(100) | UNIQUE | Contact email |
| phone | VARCHAR(15) | — | Mobile number |
| passport_number | VARCHAR(20) | UNIQUE | Passport identifier |
| date_of_birth | DATE | NOT NULL | DOB for age verification |

### 3.5 `seats`
Individual seat inventory per flight. `is_available` is managed by triggers.

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| seat_id | INT | PK | Surrogate primary key |
| flight_id | INT | FK → flights | Parent flight |
| seat_number | VARCHAR(5) | UNIQUE(flight,seat) | e.g., 4A, 1B |
| class | ENUM | ECONOMY/BUSINESS | Seat class |
| is_available | BOOLEAN | DEFAULT TRUE | Managed by triggers |
| price | DECIMAL(10,2) | NOT NULL | Seat fare |

### 3.6 `bookings`
Central reservation record linking a passenger to a specific seat.

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| booking_id | INT | PK | Surrogate primary key |
| passenger_id | INT | FK → passengers | Traveling passenger |
| seat_id | INT | FK → seats, UNIQUE | Reserved seat (1:1) |
| booking_date | DATETIME | DEFAULT NOW() | Booking timestamp |
| status | ENUM | CONFIRMED/CANCELLED/WAITLISTED | Booking state |
| pnr | CHAR(6) | UNIQUE | Passenger Name Record |

### 3.7 `payments`
One-to-one payment record per booking.

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| payment_id | INT | PK | Surrogate primary key |
| booking_id | INT | FK → bookings, UNIQUE | Parent booking (1:1) |
| amount | DECIMAL(10,2) | NOT NULL | Amount charged |
| payment_method | ENUM | CARD/UPI/NETBANKING/WALLET | Payment channel |
| payment_status | ENUM | PENDING/SUCCESS/FAILED/REFUNDED | Status |
| transaction_date | DATETIME | DEFAULT NOW() | Transaction timestamp |

### 3.8 `cancellations`
Records cancellation events with refund tracking.

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| cancel_id | INT | PK | Surrogate primary key |
| booking_id | INT | FK → bookings | Parent booking |
| cancelled_at | DATETIME | DEFAULT NOW() | Cancellation timestamp |
| reason | TEXT | — | Free-text reason |
| refund_amount | DECIMAL(10,2) | — | Refund amount (may be < paid) |
| refund_status | ENUM | PENDING/PROCESSED/DENIED | Refund state |

---

## 4. Triggers

### 4.1 `mark_seat_unavailable`

**Event:** AFTER INSERT ON bookings  
**Purpose:** Automatically marks a seat as unavailable when a booking is confirmed, preventing double-booking without application-layer checks.

```sql
CREATE TRIGGER mark_seat_unavailable
AFTER INSERT ON bookings FOR EACH ROW
BEGIN
    UPDATE seats
    SET is_available = FALSE
    WHERE seat_id = NEW.seat_id;
END;
```

**Effect:** Every time a row is inserted into `bookings`, the corresponding row in `seats` has `is_available` set to `FALSE` atomically.

---

### 4.2 `restore_seat_on_cancel`

**Event:** AFTER INSERT ON cancellations  
**Purpose:** Automatically releases a seat back to the available pool when a cancellation record is created. Uses a JOIN to find the seat via the booking.

```sql
CREATE TRIGGER restore_seat_on_cancel
AFTER INSERT ON cancellations FOR EACH ROW
BEGIN
    UPDATE seats s
    JOIN bookings b ON b.seat_id = s.seat_id
    SET s.is_available = TRUE
    WHERE b.booking_id = NEW.booking_id;
END;
```

**Effect:** When a cancellation is recorded, the seat linked to that booking flips back to `is_available = TRUE`, making it bookable again.

---

## 5. Demo Query Walkthroughs

### Query 1 — Seat Availability (Trigger Verification)
**Purpose:** Show that the `mark_seat_unavailable` trigger worked correctly after inserts.

```sql
SELECT seat_number, class, price,
       CASE WHEN is_available THEN 'AVAILABLE' ELSE 'BOOKED' END AS seat_status
FROM seats
WHERE flight_id = 1
ORDER BY seat_number;
```

**Expected Output:**

| seat_number | class    | price    | seat_status |
|-------------|----------|----------|-------------|
| 10A         | ECONOMY  | 3800.00  | BOOKED      |
| 10B         | ECONOMY  | 3800.00  | AVAILABLE   |
| 15A         | ECONOMY  | 3500.00  | AVAILABLE   |
| 15B         | ECONOMY  | 3500.00  | AVAILABLE   |
| 1A          | BUSINESS | 12500.00 | BOOKED      |
| 1B          | BUSINESS | 12500.00 | BOOKED      |
| 2A          | BUSINESS | 11800.00 | AVAILABLE   |
| 4A          | ECONOMY  | 4200.00  | BOOKED      |
| 4B          | ECONOMY  | 4200.00  | BOOKED      |
| 4C          | ECONOMY  | 4200.00  | BOOKED      |

---

### Query 2 — Full Booking Details (6-Table JOIN)
**Purpose:** Demonstrate multi-table JOIN across bookings, passengers, seats, flights, airports (×2), and payments.

```sql
SELECT b.pnr, p.full_name,
       CONCAT(a1.iata_code, ' → ', a2.iata_code) AS route,
       f.flight_number, f.departure_time,
       s.seat_number, s.class,
       pay.amount, pay.payment_method, b.status
FROM bookings b
JOIN passengers p  ON p.passenger_id = b.passenger_id
JOIN seats s       ON s.seat_id      = b.seat_id
JOIN flights f     ON f.flight_id    = s.flight_id
JOIN airports a1   ON a1.airport_id  = f.origin_airport_id
JOIN airports a2   ON a2.airport_id  = f.dest_airport_id
JOIN payments pay  ON pay.booking_id = b.booking_id
ORDER BY b.booking_id;
```

**Concepts demonstrated:** Inner JOIN, self-referencing table (airports used twice with aliases), column aliasing, ORDER BY.

---

### Query 3 — Revenue Per Flight (GROUP BY + SUM)
**Purpose:** Aggregate total revenue per flight using GROUP BY and SUM with conditional filtering.

```sql
SELECT f.flight_number,
       CONCAT(a1.city, ' → ', a2.city) AS route,
       COUNT(b.booking_id) AS total_bookings,
       SUM(pay.amount) AS total_revenue
FROM flights f
JOIN airports a1 ON a1.airport_id = f.origin_airport_id
JOIN airports a2 ON a2.airport_id = f.dest_airport_id
JOIN seats s     ON s.flight_id   = f.flight_id
JOIN bookings b  ON b.seat_id     = s.seat_id
JOIN payments pay ON pay.booking_id = b.booking_id
WHERE pay.payment_status = 'SUCCESS'
GROUP BY f.flight_id, f.flight_number, route
ORDER BY total_revenue DESC;
```

| flight_number | route | total_bookings | total_revenue |
|---------------|-------|----------------|---------------|
| AI-204 | Bengaluru → New Delhi | 5 | 37200.00 |
| 6E-301 | Bengaluru → Mumbai | 2 | 12700.00 |

---

### Query 4 — Class Breakdown (ENUM Filtering)
**Purpose:** Compare Business vs Economy revenue using ENUM column filtering.

```sql
SELECT s.class, COUNT(b.booking_id) AS bookings, SUM(pay.amount) AS revenue
FROM bookings b
JOIN seats s      ON s.seat_id      = b.seat_id
JOIN payments pay ON pay.booking_id = b.booking_id
WHERE pay.payment_status = 'SUCCESS'
GROUP BY s.class;
```

| class    | bookings | revenue  |
|----------|----------|----------|
| BUSINESS | 3        | 34800.00 |
| ECONOMY  | 4        | 15100.00 |

---

### Query 5 — Cancellation Story (Step-by-Step)
**Purpose:** Demonstrate the full cancellation workflow and trigger-based seat release.

**Step A:** Before cancellation — seat 4A is BOOKED (is_available = FALSE)

**Step B:** `UPDATE bookings SET status = 'CANCELLED' WHERE pnr = 'PNR001';`

**Step C:** Insert into cancellations → `restore_seat_on_cancel` trigger fires  
→ seat 4A: is_available = **TRUE**

**Step D:** `UPDATE payments SET payment_status = 'REFUNDED' WHERE booking_id = 1;`

**Step E:** After cancellation — seat 4A is AVAILABLE (is_available = TRUE) ✓

---

### Query 6 — Occupancy Percentage (Calculated Column)
**Purpose:** Demonstrate derived columns, ROUND(), and LEFT JOIN for flights with no bookings.

```sql
SELECT f.flight_number,
       CONCAT(a1.city, ' → ', a2.city) AS route,
       ac.total_seats,
       COUNT(b.booking_id) AS booked_seats,
       ROUND(COUNT(b.booking_id) * 100.0 / ac.total_seats, 1) AS occupancy_pct
FROM flights f
JOIN aircraft ac ON ac.aircraft_id = f.aircraft_id
JOIN airports a1 ON a1.airport_id  = f.origin_airport_id
JOIN airports a2 ON a2.airport_id  = f.dest_airport_id
LEFT JOIN seats s    ON s.flight_id = f.flight_id
LEFT JOIN bookings b ON b.seat_id   = s.seat_id AND b.status = 'CONFIRMED'
GROUP BY f.flight_id, f.flight_number, route, ac.total_seats
ORDER BY occupancy_pct DESC;
```

| flight_number | route | total_seats | booked_seats | occupancy_pct |
|---------------|-------|-------------|--------------|---------------|
| AI-204 | Bengaluru → New Delhi | 162 | 5 | 3.1% |
| 6E-301 | Bengaluru → Mumbai | 150 | 2 | 1.3% |
| SG-415 | New Delhi → Chennai | 162 | 0 | 0.0% |
| AI-890 | Mumbai → Hyderabad | 350 | 0 | 0.0% |
| 6E-112 | Chennai → Bengaluru | 150 | 0 | 0.0% |

---

## 6. Normalization

The schema follows **Third Normal Form (3NF)**:

- **1NF:** All attributes are atomic; no repeating groups
- **2NF:** All non-key attributes depend on the whole primary key (surrogate int PKs used throughout)
- **3NF:** No transitive dependencies — airport details are in `airports`, not repeated in `flights`

---

## 7. Constraints Summary

| Constraint Type | Example |
|----------------|---------|
| PRIMARY KEY | All tables use INT AUTO_INCREMENT PKs |
| FOREIGN KEY | flights.aircraft_id → aircraft.aircraft_id |
| UNIQUE | bookings.pnr, seats.(flight_id, seat_number) |
| NOT NULL | All critical columns |
| DEFAULT | booking_date DEFAULT NOW() |
| ENUM | flights.status, seats.class, payments.payment_method |
| CHECK | flights: arrival_time > departure_time |
| TRIGGER | mark_seat_unavailable, restore_seat_on_cancel |

---

## 8. Sample Data Summary

| Table | Rows |
|-------|------|
| airports | 5 |
| aircraft | 3 |
| flights | 5 |
| seats | 31 (across all 5 flights) |
| passengers | 8 |
| bookings | 8 |
| payments | 8 |
| cancellations | 1 (demo) |

**Total revenue (all SUCCESS payments):** ₹49,900  
**Business class revenue:** ₹34,800 (69.7%)  
**Economy class revenue:** ₹15,100 (30.3%)

---

## 9. Project Files

| File | Description |
|------|-------------|
| `airline_reservation.sql` | Complete SQL script — DDL, triggers, data, queries |
| `index.html` | Interactive web dashboard |
| `style.css` | Dashboard styling (dark glassmorphism theme) |
| `script.js` | Dashboard logic, charts, cancellation demo |
| `project_report.md` | This report |

---

*DBMS Mini Project — B.Tech CSE-ICB | DSATM | June 2026*
