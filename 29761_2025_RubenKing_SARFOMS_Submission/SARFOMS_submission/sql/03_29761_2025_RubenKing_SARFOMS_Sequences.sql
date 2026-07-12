--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase VI: Sequences
--------------------------------------------------------------------------------
-- Run this AFTER 29761_2025_RubenKing_SARFOMS_CreateTables.sql and
-- 29761_2025_RubenKing_SARFOMS_InsertData.sql, since each START WITH value
-- is set to continue immediately after the highest hand-assigned ID already
-- in that table. This avoids a PRIMARY KEY collision on the very first
-- sequence-driven INSERT.
--------------------------------------------------------------------------------

-- FARMER: 15 rows already exist (IDs 1-15) -> continue from 16
CREATE SEQUENCE seq_farmer
    START WITH 16
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- FARM: 18 rows already exist (IDs 1-18) -> continue from 19
CREATE SEQUENCE seq_farm
    START WITH 19
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- CROP: 20 rows already exist (IDs 1-20) -> continue from 21
CREATE SEQUENCE seq_crop
    START WITH 21
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- EQUIPMENT_CATEGORY: 7 rows already exist -> continue from 8
CREATE SEQUENCE seq_equipment_category
    START WITH 8
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- EQUIPMENT_OWNER: 8 rows already exist -> continue from 9
CREATE SEQUENCE seq_equipment_owner
    START WITH 9
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- EQUIPMENT: 20 rows already exist -> continue from 21
CREATE SEQUENCE seq_equipment
    START WITH 21
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- BOOKING: 20 rows already exist -> continue from 21
-- This is the highest-traffic table in the system (every rental creates a
-- booking), so it is the one sequence where a CACHE setting would normally
-- be considered for performance -- see the explanation below the script.
CREATE SEQUENCE seq_booking
    START WITH 21
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- PAYMENT: 20 rows already exist (1:1 with BOOKING) -> continue from 21
CREATE SEQUENCE seq_payment
    START WITH 21
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- TECHNICIAN: 6 rows already exist -> continue from 7
CREATE SEQUENCE seq_technician
    START WITH 7
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- MAINTENANCE_RECORD: 15 rows already exist -> continue from 16
CREATE SEQUENCE seq_maintenance_record
    START WITH 16
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- SENSOR_READING: 25 rows already exist -> continue from 26
-- This table receives the highest INSERT volume of all (every sensor
-- transmission is one row), so unlike the others it is deliberately given
-- CACHE 20 instead of NOCACHE -- see the explanation below the script.
CREATE SEQUENCE seq_sensor_reading
    START WITH 26
    INCREMENT BY 1
    CACHE 20
    NOCYCLE;

-- PUBLIC_HOLIDAY: 10 rows already exist -> continue from 11
CREATE SEQUENCE seq_public_holiday
    START WITH 11
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- AUDIT_LOG: empty so far (populated only by triggers from Phase VII onward)
CREATE SEQUENCE seq_audit_log
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

--------------------------------------------------------------------------------
-- Example usage: how future application/manual INSERTs should reference
-- these sequences instead of hardcoded ID numbers
--------------------------------------------------------------------------------

-- Example 1: registering a new farmer
INSERT INTO FARMER (farmer_id, first_name, last_name, phone, email, national_id, address, registration_date)
VALUES (seq_farmer.NEXTVAL, 'Aline', 'Uwamahoro', '0788999001', 'auwamahoro@gmail.com', '1199901010099', 'Rugende, Musanze', SYSDATE);

-- Example 2: registering a new booking (references CURRVAL nowhere needed here
-- because BOOKING is not the parent of another sequence-driven insert in the
-- same transaction -- see Example 3 for a case where CURRVAL is required)
INSERT INTO BOOKING (booking_id, farmer_id, equipment_id, start_date, end_date, status, created_at)
VALUES (seq_booking.NEXTVAL, 1, 3, DATE '2026-08-01', DATE '2026-08-04', 'PENDING', SYSDATE);

-- Example 3: a booking immediately followed by its payment in the SAME
-- transaction -- here CURRVAL is the correct choice, not a second NEXTVAL,
-- because PAYMENT.booking_id must reference the exact BOOKING row just created
INSERT INTO BOOKING (booking_id, farmer_id, equipment_id, start_date, end_date, status, created_at)
VALUES (seq_booking.NEXTVAL, 4, 9, DATE '2026-08-10', DATE '2026-08-12', 'CONFIRMED', SYSDATE);

INSERT INTO PAYMENT (payment_id, booking_id, amount, payment_date, payment_method, status)
VALUES (seq_payment.NEXTVAL, seq_booking.CURRVAL, 24000, SYSDATE, 'MOBILE_MONEY', 'PAID');

-- Example 4: logging a new sensor reading (high-frequency insert)
INSERT INTO SENSOR_READING (reading_id, farm_id, crop_id, reading_timestamp, soil_moisture, temperature, humidity)
VALUES (seq_sensor_reading.NEXTVAL, 3, 4, SYSTIMESTAMP, 44.0, 22.6, 61);

COMMIT;

--------------------------------------------------------------------------------
-- End of Phase VI: Sequences
--------------------------------------------------------------------------------
