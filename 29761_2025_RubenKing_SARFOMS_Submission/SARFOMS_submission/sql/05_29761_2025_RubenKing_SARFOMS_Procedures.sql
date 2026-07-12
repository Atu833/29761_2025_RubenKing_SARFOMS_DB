--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase VIII: Stored Procedures
--------------------------------------------------------------------------------
-- Run this AFTER CreateTables, InsertData, Sequences, and Views scripts.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- 1. sp_add_equipment
-- Business purpose: onboards a new rentable machine into the system.
-- Real-world use: an equipment owner lists a new tractor/drone/pump.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_add_equipment (
    p_category_id       IN  NUMBER,
    p_owner_id          IN  NUMBER,
    p_equipment_name    IN  VARCHAR2,
    p_model             IN  VARCHAR2,
    p_daily_rate        IN  NUMBER,
    p_status            IN  VARCHAR2 DEFAULT 'AVAILABLE',
    p_acquisition_date  IN  DATE     DEFAULT SYSDATE,
    p_new_equipment_id  OUT NUMBER
) IS
BEGIN
    -- Basic business-rule validation before touching the table
    IF p_daily_rate <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Daily rate must be greater than zero.');
    END IF;

    -- Assign the next surrogate key and insert the new equipment row
    SELECT seq_equipment.NEXTVAL INTO p_new_equipment_id FROM DUAL;

    INSERT INTO EQUIPMENT (equipment_id, category_id, owner_id, equipment_name,
                            model, daily_rate, status, acquisition_date)
    VALUES (p_new_equipment_id, p_category_id, p_owner_id, p_equipment_name,
            p_model, p_daily_rate, p_status, p_acquisition_date);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Equipment added successfully. New equipment_id = ' || p_new_equipment_id);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Duplicate equipment record detected.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_add_equipment failed: ' || SQLERRM);
END sp_add_equipment;
/

-- Example execution:
-- DECLARE
--     v_new_id NUMBER;
-- BEGIN
--     sp_add_equipment(1, 1, 'Kubota M5-111 Tractor', 'M5-111', 52000, 'AVAILABLE', SYSDATE, v_new_id);
-- END;
-- /

--------------------------------------------------------------------------------
-- 2. sp_register_farmer
-- Business purpose: onboards a new customer (farmer) into the system.
-- Real-world use: front-desk / APEX registration form.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_register_farmer (
    p_first_name    IN  VARCHAR2,
    p_last_name     IN  VARCHAR2,
    p_phone         IN  VARCHAR2,
    p_email         IN  VARCHAR2,
    p_national_id   IN  VARCHAR2,
    p_address       IN  VARCHAR2,
    p_new_farmer_id OUT NUMBER
) IS
BEGIN
    SELECT seq_farmer.NEXTVAL INTO p_new_farmer_id FROM DUAL;

    INSERT INTO FARMER (farmer_id, first_name, last_name, phone, email,
                         national_id, address, registration_date)
    VALUES (p_new_farmer_id, p_first_name, p_last_name, p_phone, p_email,
            p_national_id, p_address, SYSDATE);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Farmer registered successfully. New farmer_id = ' || p_new_farmer_id);

EXCEPTION
    -- Fires when phone, email, or national_id violates a UNIQUE constraint
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'A farmer with this phone, email, or national ID already exists.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_register_farmer failed: ' || SQLERRM);
END sp_register_farmer;
/

-- Example execution:
-- DECLARE
--     v_new_id NUMBER;
-- BEGIN
--     sp_register_farmer('Alice','Mutoni','0788555001','amutoni@gmail.com','1199901010055','Kicukiro, Kigali', v_new_id);
-- END;
-- /

--------------------------------------------------------------------------------
-- 3. sp_record_payment
-- Business purpose: records a financial transaction against a booking
-- (the closest equivalent to logging a fuel purchase -- a costed,
-- timestamped transaction tied to an existing usage record).
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_record_payment (
    p_booking_id        IN  NUMBER,
    p_amount            IN  NUMBER,
    p_payment_method    IN  VARCHAR2,
    p_new_payment_id    OUT NUMBER
) IS
    v_booking_exists NUMBER;
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Payment amount must be greater than zero.');
    END IF;

    -- Confirm the booking actually exists before attaching a payment to it
    SELECT COUNT(*) INTO v_booking_exists FROM BOOKING WHERE booking_id = p_booking_id;
    IF v_booking_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Booking ID ' || p_booking_id || ' does not exist.');
    END IF;

    SELECT seq_payment.NEXTVAL INTO p_new_payment_id FROM DUAL;

    INSERT INTO PAYMENT (payment_id, booking_id, amount, payment_date, payment_method, status)
    VALUES (p_new_payment_id, p_booking_id, p_amount, SYSDATE, p_payment_method, 'PAID');

    -- A paid booking that was still PENDING is now confirmed
    UPDATE BOOKING SET status = 'CONFIRMED'
    WHERE booking_id = p_booking_id AND status = 'PENDING';

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payment recorded. New payment_id = ' || p_new_payment_id);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, 'This booking already has a payment recorded (1:1 constraint).');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_record_payment failed: ' || SQLERRM);
END sp_record_payment;
/

-- Example execution:
-- DECLARE
--     v_new_id NUMBER;
-- BEGIN
--     sp_record_payment(10, 90000, 'MOBILE_MONEY', v_new_id);
-- END;
-- /

--------------------------------------------------------------------------------
-- 4. sp_schedule_maintenance
-- Business purpose: opens a maintenance ticket for equipment and takes it
-- out of the rentable pool immediately, preventing it from being booked
-- while service is pending.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_schedule_maintenance (
    p_equipment_id      IN  NUMBER,
    p_technician_id     IN  NUMBER,
    p_service_date      IN  DATE,
    p_description       IN  VARCHAR2,
    p_new_maintenance_id OUT NUMBER
) IS
    v_equipment_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_equipment_exists FROM EQUIPMENT WHERE equipment_id = p_equipment_id;
    IF v_equipment_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Equipment ID ' || p_equipment_id || ' does not exist.');
    END IF;

    SELECT seq_maintenance_record.NEXTVAL INTO p_new_maintenance_id FROM DUAL;

    -- Cost is NULL until sp_complete_maintenance finalizes it
    INSERT INTO MAINTENANCE_RECORD (maintenance_id, equipment_id, technician_id,
                                     service_date, description, cost)
    VALUES (p_new_maintenance_id, p_equipment_id, p_technician_id, p_service_date, p_description, NULL);

    UPDATE EQUIPMENT SET status = 'MAINTENANCE' WHERE equipment_id = p_equipment_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Maintenance scheduled. New maintenance_id = ' || p_new_maintenance_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_schedule_maintenance failed: ' || SQLERRM);
END sp_schedule_maintenance;
/

-- Example execution:
-- DECLARE
--     v_new_id NUMBER;
-- BEGIN
--     sp_schedule_maintenance(9, 4, DATE '2026-08-01', 'Quarterly sensor calibration check', v_new_id);
-- END;
-- /

--------------------------------------------------------------------------------
-- 5. sp_complete_maintenance
-- Business purpose: closes out a maintenance ticket, records the final cost,
-- and returns the equipment to the rentable pool.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_complete_maintenance (
    p_maintenance_id    IN  NUMBER,
    p_final_cost        IN  NUMBER,
    p_new_equipment_status IN VARCHAR2 DEFAULT 'AVAILABLE'
) IS
    v_equipment_id NUMBER;
BEGIN
    -- %ROWTYPE-free lookup: get the equipment tied to this ticket
    SELECT equipment_id INTO v_equipment_id
    FROM MAINTENANCE_RECORD
    WHERE maintenance_id = p_maintenance_id;

    UPDATE MAINTENANCE_RECORD SET cost = p_final_cost WHERE maintenance_id = p_maintenance_id;

    UPDATE EQUIPMENT SET status = p_new_equipment_status WHERE equipment_id = v_equipment_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Maintenance ticket ' || p_maintenance_id || ' closed. Equipment ' ||
                          v_equipment_id || ' set to ' || p_new_equipment_status || '.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20008, 'Maintenance ID ' || p_maintenance_id || ' was not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_complete_maintenance failed: ' || SQLERRM);
END sp_complete_maintenance;
/

-- Example execution:
-- BEGIN
--     sp_complete_maintenance(2, 42000, 'AVAILABLE');
-- END;
-- /

--------------------------------------------------------------------------------
-- 6. sp_create_booking
-- Business purpose: reserves a piece of equipment for a farmer over a date
-- range. Includes a genuine double-booking guard -- the same overlap check
-- that our Phase V sample data (booking_id 3 and 4) was deliberately built
-- to test.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_create_booking (
    p_farmer_id     IN  NUMBER,
    p_equipment_id  IN  NUMBER,
    p_start_date    IN  DATE,
    p_end_date      IN  DATE,
    p_new_booking_id OUT NUMBER
) IS
    v_conflict_count NUMBER;
BEGIN
    IF p_end_date < p_start_date THEN
        RAISE_APPLICATION_ERROR(-20009, 'End date cannot be before start date.');
    END IF;

    -- Overlap test: does any CONFIRMED/PENDING booking for this equipment
    -- share any day with the requested range?
    SELECT COUNT(*) INTO v_conflict_count
    FROM BOOKING
    WHERE equipment_id = p_equipment_id
      AND status IN ('CONFIRMED', 'PENDING')
      AND p_start_date <= end_date
      AND p_end_date   >= start_date;

    IF v_conflict_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Equipment ' || p_equipment_id || ' is already booked for an overlapping date range.');
    END IF;

    SELECT seq_booking.NEXTVAL INTO p_new_booking_id FROM DUAL;

    INSERT INTO BOOKING (booking_id, farmer_id, equipment_id, start_date, end_date, status, created_at)
    VALUES (p_new_booking_id, p_farmer_id, p_equipment_id, p_start_date, p_end_date, 'PENDING', SYSDATE);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Booking created. New booking_id = ' || p_new_booking_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_create_booking failed: ' || SQLERRM);
END sp_create_booking;
/

-- Example execution (this SUCCEEDS - no conflict):
-- DECLARE
--     v_new_id NUMBER;
-- BEGIN
--     sp_create_booking(5, 12, DATE '2026-09-01', DATE '2026-09-03', v_new_id);
-- END;
-- /
--
-- Example execution (this FAILS - overlaps existing booking_id 3 on equipment 5):
-- DECLARE
--     v_new_id NUMBER;
-- BEGIN
--     sp_create_booking(2, 5, DATE '2026-06-12', DATE '2026-06-14', v_new_id);
-- END;
-- /

--------------------------------------------------------------------------------
-- 7. sp_complete_booking
-- Business purpose: marks a rental as finished and returns the equipment
-- to the available pool (the "record a completed trip" equivalent).
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_complete_booking (
    p_booking_id IN NUMBER
) IS
    v_equipment_id NUMBER;
    v_current_status VARCHAR2(20);
BEGIN
    SELECT equipment_id, status INTO v_equipment_id, v_current_status
    FROM BOOKING
    WHERE booking_id = p_booking_id;

    IF v_current_status <> 'CONFIRMED' THEN
        RAISE_APPLICATION_ERROR(-20011,
            'Only CONFIRMED bookings can be completed. Current status: ' || v_current_status);
    END IF;

    UPDATE BOOKING SET status = 'COMPLETED' WHERE booking_id = p_booking_id;
    UPDATE EQUIPMENT SET status = 'AVAILABLE' WHERE equipment_id = v_equipment_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Booking ' || p_booking_id || ' completed. Equipment ' ||
                          v_equipment_id || ' is now AVAILABLE.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20012, 'Booking ID ' || p_booking_id || ' was not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_complete_booking failed: ' || SQLERRM);
END sp_complete_booking;
/

-- Example execution:
-- BEGIN
--     sp_complete_booking(6);
-- END;
-- /

--------------------------------------------------------------------------------
-- 8. sp_update_equipment_status
-- Business purpose: a single controlled entry point for changing equipment
-- status, so status transitions are validated in one place instead of
-- scattered UPDATE statements throughout the application.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_update_equipment_status (
    p_equipment_id  IN NUMBER,
    p_new_status    IN VARCHAR2
) IS
    v_rows_updated NUMBER;
BEGIN
    IF p_new_status NOT IN ('AVAILABLE','RENTED','MAINTENANCE','RETIRED') THEN
        RAISE_APPLICATION_ERROR(-20013,
            'Invalid status "' || p_new_status || '". Must be AVAILABLE, RENTED, MAINTENANCE, or RETIRED.');
    END IF;

    UPDATE EQUIPMENT SET status = p_new_status WHERE equipment_id = p_equipment_id;
    v_rows_updated := SQL%ROWCOUNT;

    IF v_rows_updated = 0 THEN
        RAISE_APPLICATION_ERROR(-20014, 'Equipment ID ' || p_equipment_id || ' does not exist.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Equipment ' || p_equipment_id || ' status updated to ' || p_new_status || '.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'sp_update_equipment_status failed: ' || SQLERRM);
END sp_update_equipment_status;
/

-- Example execution:
-- BEGIN
--     sp_update_equipment_status(19, 'RETIRED');
-- END;
-- /

--------------------------------------------------------------------------------
-- 9. sp_calculate_maintenance_cost
-- Business purpose: rolls up all-time maintenance spend for one piece of
-- equipment, e.g. to support a lifetime-cost-vs-revenue decision.
-- Note: this procedure returns the total via an OUT parameter rather than
-- writing it to a new column, since EQUIPMENT was already finalized in
-- Phase V -- adding a stored, denormalized total column would itself
-- violate 3NF (the total is fully derivable from MAINTENANCE_RECORD, so it
-- should be calculated on demand, not persisted).
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_calculate_maintenance_cost (
    p_equipment_id  IN  NUMBER,
    p_total_cost    OUT NUMBER
) IS
    v_equipment_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_equipment_exists FROM EQUIPMENT WHERE equipment_id = p_equipment_id;
    IF v_equipment_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20015, 'Equipment ID ' || p_equipment_id || ' does not exist.');
    END IF;

    SELECT NVL(SUM(cost), 0) INTO p_total_cost
    FROM MAINTENANCE_RECORD
    WHERE equipment_id = p_equipment_id;

    DBMS_OUTPUT.PUT_LINE('Total maintenance cost for equipment ' || p_equipment_id ||
                          ' = ' || p_total_cost);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'sp_calculate_maintenance_cost failed: ' || SQLERRM);
END sp_calculate_maintenance_cost;
/

-- Example execution:
-- DECLARE
--     v_total NUMBER;
-- BEGIN
--     sp_calculate_maintenance_cost(8, v_total);
--     DBMS_OUTPUT.PUT_LINE('Returned value: ' || v_total);
-- END;
-- /

--------------------------------------------------------------------------------
-- 10. sp_generate_service_reminders
-- Business purpose: prints a reminder list for every piece of equipment
-- overdue for service, using the VW_SERVICE_DUE_REMINDER view built in
-- Phase VII. In a production system this loop would call an email/SMS API
-- instead of DBMS_OUTPUT -- a natural future enhancement to mention in
-- your report.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_generate_service_reminders IS
    v_reminder_count NUMBER := 0;
BEGIN
    FOR rec IN (SELECT equipment_id, equipment_name, days_since_last_service
                FROM VW_SERVICE_DUE_REMINDER)
    LOOP
        DBMS_OUTPUT.PUT_LINE('REMINDER: Equipment ' || rec.equipment_id || ' ('
            || rec.equipment_name || ') is due for service - '
            || NVL(TO_CHAR(rec.days_since_last_service), 'never serviced')
            || ' days since last service.');
        v_reminder_count := v_reminder_count + 1;
    END LOOP;

    IF v_reminder_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No equipment is currently due for service.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(v_reminder_count || ' reminder(s) generated.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'sp_generate_service_reminders failed: ' || SQLERRM);
END sp_generate_service_reminders;
/

-- Example execution:
-- BEGIN
--     sp_generate_service_reminders;
-- END;
-- /

--------------------------------------------------------------------------------
-- End of Phase VIII: Stored Procedures
--------------------------------------------------------------------------------
