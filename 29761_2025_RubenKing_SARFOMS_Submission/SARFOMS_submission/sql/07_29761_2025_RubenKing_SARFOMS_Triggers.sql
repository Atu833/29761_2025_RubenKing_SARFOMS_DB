--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase X: Triggers
--------------------------------------------------------------------------------
-- Run this AFTER CreateTables, InsertData, Sequences, Views, Procedures,
-- and Functions. No tables are added or modified in this phase.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- 1. trg_booking_biud_rules
-- Type: BEFORE INSERT OR UPDATE OR DELETE, FOR EACH ROW, ON BOOKING
-- Purpose: enforces the course's MANDATORY business rule -- no INSERT,
-- UPDATE, or DELETE is permitted on weekdays (Mon-Fri) or on a date stored
-- in PUBLIC_HOLIDAY. Also auto-populates the created_at audit field on
-- INSERT (never trusting a client-supplied value) and rejects a booking
-- whose start_date is in the past.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_booking_biud_rules
BEFORE INSERT OR UPDATE OR DELETE ON BOOKING
FOR EACH ROW
DECLARE
    v_day_name    VARCHAR2(3);
    v_is_holiday  NUMBER;
BEGIN
    -- Day name forced to English regardless of session NLS settings
    v_day_name := TRIM(TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH'));

    SELECT COUNT(*) INTO v_is_holiday
    FROM PUBLIC_HOLIDAY
    WHERE holiday_date = TRUNC(SYSDATE);

    IF v_day_name NOT IN ('SAT','SUN') THEN
        RAISE_APPLICATION_ERROR(-20030,
            'Data changes are not permitted on weekdays (Monday-Friday). Today is ' || v_day_name || '.');
    ELSIF v_is_holiday > 0 THEN
        RAISE_APPLICATION_ERROR(-20031, 'Data changes are not permitted on a public holiday.');
    END IF;

    IF INSERTING THEN
        :NEW.created_at := SYSDATE;  -- audit timestamp is always system-generated

        IF :NEW.start_date < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20032, 'Booking start date cannot be in the past.');
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE BETWEEN -20099 AND -20030 THEN
            RAISE;  -- re-raise our own deliberate business-rule errors unchanged
        ELSE
            RAISE_APPLICATION_ERROR(-20099, 'trg_booking_biud_rules failed: ' || SQLERRM);
        END IF;
END;
/

-- Example (run on ANY weekday - this will fail with ORA-20030 as expected):
-- INSERT INTO BOOKING (booking_id, farmer_id, equipment_id, start_date, end_date, status, created_at)
-- VALUES (seq_booking.NEXTVAL, 1, 3, SYSDATE+5, SYSDATE+7, 'PENDING', SYSDATE);

--------------------------------------------------------------------------------
-- 2. trg_equipment_price_check_biu
-- Type: BEFORE INSERT OR UPDATE, FOR EACH ROW, ON EQUIPMENT
-- Purpose: rejects a non-positive daily_rate and a blank/whitespace-only
-- equipment_name with a friendly message (the second check is something a
-- simple NOT NULL constraint cannot catch, since ' ' is not NULL).
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_equipment_price_check_biu
BEFORE INSERT OR UPDATE ON EQUIPMENT
FOR EACH ROW
BEGIN
    IF :NEW.daily_rate <= 0 THEN
        RAISE_APPLICATION_ERROR(-20033, 'Equipment daily rate must be a positive value.');
    END IF;

    IF TRIM(:NEW.equipment_name) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20034, 'Equipment name cannot be blank or whitespace only.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20033, -20034) THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20099, 'trg_equipment_price_check_biu failed: ' || SQLERRM);
        END IF;
END;
/

-- Example (fails with ORA-20033):
-- UPDATE EQUIPMENT SET daily_rate = -500 WHERE equipment_id = 1;

--------------------------------------------------------------------------------
-- 3. trg_farm_area_check_biu
-- Type: BEFORE INSERT OR UPDATE, FOR EACH ROW, ON FARM
-- Purpose: enforces a realistic upper bound (1000 ha) in addition to the
-- ">0" already guaranteed by the CHECK constraint -- a plausibility check
-- a simple constraint alone would not express as clearly with a custom
-- message.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_farm_area_check_biu
BEFORE INSERT OR UPDATE ON FARM
FOR EACH ROW
BEGIN
    IF :NEW.size_hectares <= 0 THEN
        RAISE_APPLICATION_ERROR(-20035, 'Farm size must be greater than zero hectares.');
    ELSIF :NEW.size_hectares > 1000 THEN
        RAISE_APPLICATION_ERROR(-20036,
            'Farm size exceeds the realistic maximum (1000 ha) for a single plot - please verify the entry.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20035, -20036) THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20099, 'trg_farm_area_check_biu failed: ' || SQLERRM);
        END IF;
END;
/

-- Example (fails with ORA-20036):
-- INSERT INTO FARM VALUES (19, 1, 'Test Plot', 5000, 'Loam');

--------------------------------------------------------------------------------
-- 4. trg_payment_validation_biu
-- Type: BEFORE INSERT OR UPDATE, FOR EACH ROW, ON PAYMENT
-- Purpose: enforces a cross-column business rule that a simple CHECK
-- constraint on a single column cannot express as clearly -- a payment
-- marked PAID must have an actual payment_date.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_payment_validation_biu
BEFORE INSERT OR UPDATE ON PAYMENT
FOR EACH ROW
BEGIN
    IF :NEW.amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20037, 'Payment amount must be greater than zero.');
    END IF;

    IF :NEW.status = 'PAID' AND :NEW.payment_date IS NULL THEN
        RAISE_APPLICATION_ERROR(-20038, 'A payment marked PAID must have a payment_date.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20037, -20038) THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20099, 'trg_payment_validation_biu failed: ' || SQLERRM);
        END IF;
END;
/

-- Example (fails with ORA-20038):
-- UPDATE PAYMENT SET status = 'PAID', payment_date = NULL WHERE payment_id = 9;

--------------------------------------------------------------------------------
-- 5. trg_equipment_status_sync_aiu
-- Type: AFTER UPDATE OF status, FOR EACH ROW, ON BOOKING
-- Purpose: automatically keeps EQUIPMENT.status consistent with the
-- booking lifecycle -- CONFIRMED marks the equipment RENTED, and
-- COMPLETED/CANCELLED returns it to AVAILABLE. This is the "automatically
-- update related records" requirement.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_equipment_status_sync_aiu
AFTER UPDATE OF status ON BOOKING
FOR EACH ROW
BEGIN
    IF :NEW.status = 'CONFIRMED' THEN
        UPDATE EQUIPMENT SET status = 'RENTED' WHERE equipment_id = :NEW.equipment_id;
    ELSIF :NEW.status IN ('COMPLETED', 'CANCELLED') THEN
        UPDATE EQUIPMENT SET status = 'AVAILABLE'
        WHERE equipment_id = :NEW.equipment_id AND status = 'RENTED';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_equipment_status_sync_aiu failed: ' || SQLERRM);
END;
/

-- Example (on a weekend, with trg_booking_biud_rules temporarily disabled - see note below):
-- UPDATE BOOKING SET status = 'CONFIRMED' WHERE booking_id = 10;
-- SELECT status FROM EQUIPMENT WHERE equipment_id = 15;  -- now shows RENTED

--------------------------------------------------------------------------------
-- 6. trg_farmer_prevent_delete_bd
-- Type: BEFORE DELETE, FOR EACH ROW, ON FARMER
-- Purpose: FARMER is already protected from deletion by the FK constraint
-- on BOOKING, but Oracle's raw error (ORA-02292) is cryptic for an end
-- user. This trigger intercepts the delete first and raises a clear,
-- specific message naming the farmer and the number of dependent records.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_farmer_prevent_delete_bd
BEFORE DELETE ON FARMER
FOR EACH ROW
DECLARE
    v_booking_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_booking_count FROM BOOKING WHERE farmer_id = :OLD.farmer_id;

    IF v_booking_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20039,
            'Cannot delete farmer ' || :OLD.first_name || ' ' || :OLD.last_name ||
            ' - ' || v_booking_count || ' booking record(s) reference this farmer.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20039 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20099, 'trg_farmer_prevent_delete_bd failed: ' || SQLERRM);
        END IF;
END;
/

-- Example (fails with ORA-20039, since farmer 1 has bookings):
-- DELETE FROM FARMER WHERE farmer_id = 1;

--------------------------------------------------------------------------------
-- 7. trg_maintenance_prevent_delete_bd
-- Type: BEFORE DELETE, FOR EACH ROW, ON MAINTENANCE_RECORD
-- Purpose: MAINTENANCE_RECORD has no child table referencing it, so no FK
-- naturally protects it. This trigger adds real protection: a completed
-- and costed service record cannot be deleted, since it is part of the
-- equipment's permanent service and audit history.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_maintenance_prevent_delete_bd
BEFORE DELETE ON MAINTENANCE_RECORD
FOR EACH ROW
BEGIN
    IF :OLD.cost IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20040,
            'Cannot delete maintenance record ' || :OLD.maintenance_id ||
            ' - service already completed and costed; historical records must be preserved.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20040 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20099, 'trg_maintenance_prevent_delete_bd failed: ' || SQLERRM);
        END IF;
END;
/

-- Example (fails with ORA-20040, since maintenance_id 1 has a recorded cost):
-- DELETE FROM MAINTENANCE_RECORD WHERE maintenance_id = 1;

--------------------------------------------------------------------------------
-- 8. trg_booking_audit_log_aiud
-- Type: AFTER INSERT OR UPDATE OR DELETE, FOR EACH ROW, ON BOOKING
-- Purpose: writes every change to BOOKING into AUDIT_LOG, including a
-- derived value (rental_days, calculated from end_date - start_date + 1)
-- that does not exist as a stored column anywhere -- combining the
-- "log changes" and "calculate derived values" requirements in one trigger.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_booking_audit_log_aiud
AFTER INSERT OR UPDATE OR DELETE ON BOOKING
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_record_id NUMBER;
    v_old_val   VARCHAR2(4000);
    v_new_val   VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.booking_id;
        v_new_val   := 'equipment_id=' || :NEW.equipment_id || ', status=' || :NEW.status ||
                       ', rental_days=' || TO_CHAR(:NEW.end_date - :NEW.start_date + 1);
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :NEW.booking_id;
        v_old_val   := 'status=' || :OLD.status;
        v_new_val   := 'status=' || :NEW.status ||
                       ', rental_days=' || TO_CHAR(:NEW.end_date - :NEW.start_date + 1);
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_record_id := :OLD.booking_id;
        v_old_val   := 'status=' || :OLD.status;
    END IF;

    INSERT INTO AUDIT_LOG (audit_id, table_name, operation, record_id, changed_by, changed_at, old_value, new_value)
    VALUES (seq_audit_log.NEXTVAL, 'BOOKING', v_operation, v_record_id, USER, SYSDATE, v_old_val, v_new_val);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_booking_audit_log_aiud failed: ' || SQLERRM);
END;
/

-- Example (check the result after any successful BOOKING change):
-- SELECT * FROM AUDIT_LOG WHERE table_name = 'BOOKING' ORDER BY changed_at DESC;

--------------------------------------------------------------------------------
-- 9. trg_sensor_reading_extreme_alert_ai
-- Type: AFTER INSERT, FOR EACH ROW, ON SENSOR_READING
-- Purpose: automatically flags an incoming sensor reading that indicates
-- drought stress, waterlogging, or extreme heat by writing an alert entry
-- into AUDIT_LOG -- this is the innovation link between raw sensor data
-- and an actionable notification, without needing a new table.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_sensor_reading_extreme_alert_ai
AFTER INSERT ON SENSOR_READING
FOR EACH ROW
DECLARE
    v_alert_msg VARCHAR2(200);
BEGIN
    IF :NEW.soil_moisture < 15 THEN
        v_alert_msg := 'ALERT: Low soil moisture (' || :NEW.soil_moisture || '%) - possible drought stress.';
    ELSIF :NEW.soil_moisture > 90 THEN
        v_alert_msg := 'ALERT: Very high soil moisture (' || :NEW.soil_moisture || '%) - possible waterlogging.';
    ELSIF :NEW.temperature > 35 THEN
        v_alert_msg := 'ALERT: High temperature reading (' || :NEW.temperature || ' C) recorded.';
    END IF;

    IF v_alert_msg IS NOT NULL THEN
        INSERT INTO AUDIT_LOG (audit_id, table_name, operation, record_id, changed_by, changed_at, old_value, new_value)
        VALUES (seq_audit_log.NEXTVAL, 'SENSOR_READING', 'INSERT', :NEW.reading_id, USER, SYSDATE, NULL, v_alert_msg);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_sensor_reading_extreme_alert_ai failed: ' || SQLERRM);
END;
/

-- Example (triggers a drought-stress alert):
-- INSERT INTO SENSOR_READING VALUES (26, 6, 6, SYSTIMESTAMP, 9.0, 37.0, 20);
-- SELECT * FROM AUDIT_LOG WHERE table_name = 'SENSOR_READING' ORDER BY changed_at DESC;

--------------------------------------------------------------------------------
-- 10. trg_maintenance_equipment_status_ai
-- Type: AFTER INSERT, FOR EACH ROW, ON MAINTENANCE_RECORD
-- Purpose: a defense-in-depth safeguard -- sp_schedule_maintenance already
-- sets EQUIPMENT.status to MAINTENANCE, but this trigger guarantees the
-- same outcome even if a maintenance record is inserted directly, bypassing
-- the procedure layer entirely.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_maintenance_equipment_status_ai
AFTER INSERT ON MAINTENANCE_RECORD
FOR EACH ROW
BEGIN
    UPDATE EQUIPMENT
    SET status = 'MAINTENANCE'
    WHERE equipment_id = :NEW.equipment_id
      AND status <> 'RETIRED';

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_maintenance_equipment_status_ai failed: ' || SQLERRM);
END;
/

-- Example:
-- INSERT INTO MAINTENANCE_RECORD VALUES (16, 3, 2, SYSDATE, 'Emergency hose repair', NULL);
-- SELECT status FROM EQUIPMENT WHERE equipment_id = 3;  -- now shows MAINTENANCE

--------------------------------------------------------------------------------
-- End of Phase X: Triggers
--------------------------------------------------------------------------------
