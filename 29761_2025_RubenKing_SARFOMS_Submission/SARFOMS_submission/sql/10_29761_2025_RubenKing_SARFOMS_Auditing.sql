--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase XIV: Database Auditing
--------------------------------------------------------------------------------
-- Run this AFTER all previous phase scripts. Nothing here modifies or
-- recreates any table, trigger, procedure, function, or package from a
-- prior phase -- it only ADDS new audit triggers on top of the existing
-- AUDIT_LOG table (created in Phase V) and reuses seq_audit_log (Phase VI).
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- WHY AUDITING MATTERS IN THIS SYSTEM (for the report)
--------------------------------------------------------------------------------
-- 1. Accountability: if an equipment's daily rate is changed, or a payment
--    status is altered, the system must be able to say WHO did it and WHEN --
--    not just what the current value is.
-- 2. Dispute resolution: if a farmer disputes a charge, or an owner disputes
--    an equipment status, the audit trail is the objective record of what
--    actually happened, in what order.
-- 3. Fraud/error detection: a payment silently changed from UNPAID to PAID
--    without a matching transaction, or a maintenance cost quietly reduced
--    after the fact, are exactly the anomalies an audit trail surfaces.
-- 4. Regulatory/academic requirement: this course's brief explicitly
--    mandates an auditing system with security control -- this phase is
--    that requirement being satisfied directly, not just a nice-to-have.
--
-- WHICH TABLES ARE AUDITED AND WHY THOSE FIVE:
--   BOOKING           - the core transaction; already audited in Phase X
--   PAYMENT           - money changing hands is the single highest-risk
--                       table in the system for fraud or dispute
--   EQUIPMENT         - status and price changes affect revenue and
--                       availability; owners need to see who altered them
--   MAINTENANCE_RECORD- cost figures here directly affect profitability
--                       reporting (Phase IX functions), so tampering here
--                       is a real business risk worth tracking
--   FARMER            - personal/contact data changes (phone, address)
--                       need a trail for accountability and data-protection
--                       reasons
--
-- WHAT INFORMATION IS CAPTURED (per AUDIT_LOG row, from Phase V):
--   audit_id, table_name, operation (INSERT/UPDATE/DELETE), record_id,
--   changed_by (Oracle session USER), changed_at (SYSDATE), old_value,
--   new_value (both stored as descriptive strings, not raw column dumps --
--   deliberately readable rather than requiring a second lookup)
--
-- SECURITY NOTE: FARMER's audit trigger intentionally does NOT log
-- national_id in old_value/new_value, even though it changes rarely --
-- an audit log itself becomes a security liability if it duplicates
-- sensitive personal identifiers unnecessarily. Logging "a contact detail
-- changed" is enough for accountability without multiplying where a
-- national ID number is stored in the database.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 1. trg_payment_audit_aiud
-- Type: AFTER INSERT OR UPDATE OR DELETE, FOR EACH ROW, ON PAYMENT
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_payment_audit_aiud
AFTER INSERT OR UPDATE OR DELETE ON PAYMENT
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_record_id NUMBER;
    v_old_val   VARCHAR2(4000);
    v_new_val   VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.payment_id;
        v_new_val   := 'booking_id=' || :NEW.booking_id || ', amount=' || :NEW.amount ||
                       ', status=' || :NEW.status;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :NEW.payment_id;
        v_old_val   := 'amount=' || :OLD.amount || ', status=' || :OLD.status;
        v_new_val   := 'amount=' || :NEW.amount || ', status=' || :NEW.status;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_record_id := :OLD.payment_id;
        v_old_val   := 'amount=' || :OLD.amount || ', status=' || :OLD.status;
    END IF;

    INSERT INTO AUDIT_LOG (audit_id, table_name, operation, record_id, changed_by, changed_at, old_value, new_value)
    VALUES (seq_audit_log.NEXTVAL, 'PAYMENT', v_operation, v_record_id, USER, SYSDATE, v_old_val, v_new_val);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_payment_audit_aiud failed: ' || SQLERRM);
END;
/

--------------------------------------------------------------------------------
-- 2. trg_equipment_audit_aiud
-- Type: AFTER INSERT OR UPDATE OR DELETE, FOR EACH ROW, ON EQUIPMENT
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_equipment_audit_aiud
AFTER INSERT OR UPDATE OR DELETE ON EQUIPMENT
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_record_id NUMBER;
    v_old_val   VARCHAR2(4000);
    v_new_val   VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.equipment_id;
        v_new_val   := 'name=' || :NEW.equipment_name || ', rate=' || :NEW.daily_rate ||
                       ', status=' || :NEW.status;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :NEW.equipment_id;
        v_old_val   := 'rate=' || :OLD.daily_rate || ', status=' || :OLD.status;
        v_new_val   := 'rate=' || :NEW.daily_rate || ', status=' || :NEW.status;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_record_id := :OLD.equipment_id;
        v_old_val   := 'name=' || :OLD.equipment_name || ', status=' || :OLD.status;
    END IF;

    INSERT INTO AUDIT_LOG (audit_id, table_name, operation, record_id, changed_by, changed_at, old_value, new_value)
    VALUES (seq_audit_log.NEXTVAL, 'EQUIPMENT', v_operation, v_record_id, USER, SYSDATE, v_old_val, v_new_val);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_equipment_audit_aiud failed: ' || SQLERRM);
END;
/

--------------------------------------------------------------------------------
-- 3. trg_maintenance_record_audit_aiud
-- Type: AFTER INSERT OR UPDATE OR DELETE, FOR EACH ROW, ON MAINTENANCE_RECORD
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_maintenance_record_audit_aiud
AFTER INSERT OR UPDATE OR DELETE ON MAINTENANCE_RECORD
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_record_id NUMBER;
    v_old_val   VARCHAR2(4000);
    v_new_val   VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.maintenance_id;
        v_new_val   := 'equipment_id=' || :NEW.equipment_id || ', cost=' || NVL(TO_CHAR(:NEW.cost), 'NULL');
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :NEW.maintenance_id;
        v_old_val   := 'cost=' || NVL(TO_CHAR(:OLD.cost), 'NULL');
        v_new_val   := 'cost=' || NVL(TO_CHAR(:NEW.cost), 'NULL');
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_record_id := :OLD.maintenance_id;
        v_old_val   := 'equipment_id=' || :OLD.equipment_id || ', cost=' || NVL(TO_CHAR(:OLD.cost), 'NULL');
    END IF;

    INSERT INTO AUDIT_LOG (audit_id, table_name, operation, record_id, changed_by, changed_at, old_value, new_value)
    VALUES (seq_audit_log.NEXTVAL, 'MAINTENANCE_RECORD', v_operation, v_record_id, USER, SYSDATE, v_old_val, v_new_val);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_maintenance_record_audit_aiud failed: ' || SQLERRM);
END;
/

--------------------------------------------------------------------------------
-- 4. trg_farmer_audit_aiud
-- Type: AFTER INSERT OR UPDATE OR DELETE, FOR EACH ROW, ON FARMER
-- Note: deliberately does NOT include national_id in old_value/new_value --
-- see the security note above the trigger block.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_farmer_audit_aiud
AFTER INSERT OR UPDATE OR DELETE ON FARMER
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_record_id NUMBER;
    v_old_val   VARCHAR2(4000);
    v_new_val   VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.farmer_id;
        v_new_val   := 'name=' || :NEW.first_name || ' ' || :NEW.last_name || ', phone=' || :NEW.phone;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :NEW.farmer_id;
        v_old_val   := 'phone=' || :OLD.phone || ', address=' || :OLD.address;
        v_new_val   := 'phone=' || :NEW.phone || ', address=' || :NEW.address;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_record_id := :OLD.farmer_id;
        v_old_val   := 'name=' || :OLD.first_name || ' ' || :OLD.last_name;
    END IF;

    INSERT INTO AUDIT_LOG (audit_id, table_name, operation, record_id, changed_by, changed_at, old_value, new_value)
    VALUES (seq_audit_log.NEXTVAL, 'FARMER', v_operation, v_record_id, USER, SYSDATE, v_old_val, v_new_val);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'trg_farmer_audit_aiud failed: ' || SQLERRM);
END;
/


--------------------------------------------------------------------------------
-- DEMONSTRATION: sample INSERT / UPDATE / DELETE to populate the audit trail
-- (none of these touch BOOKING, so the Phase X weekday/holiday lock does not
-- interfere -- these can be run on any day, any time)
--------------------------------------------------------------------------------

-- (a) PAYMENT: mark a previously UNPAID payment as PAID
UPDATE PAYMENT
SET status = 'PAID', payment_date = SYSDATE, payment_method = 'MOBILE_MONEY'
WHERE payment_id = 9;
COMMIT;

-- (b) EQUIPMENT: take a machine out of service for a moment, then bring it back
UPDATE EQUIPMENT SET status = 'MAINTENANCE' WHERE equipment_id = 11;
COMMIT;
UPDATE EQUIPMENT SET status = 'AVAILABLE' WHERE equipment_id = 11;
COMMIT;

-- (c) MAINTENANCE_RECORD: insert a new (uncosted) service ticket, then cost it
INSERT INTO MAINTENANCE_RECORD (maintenance_id, equipment_id, technician_id, service_date, description, cost)
VALUES (seq_maintenance_record.NEXTVAL, 12, 5, SYSDATE, 'Blade replacement - urgent callout', NULL);
COMMIT;

UPDATE MAINTENANCE_RECORD SET cost = 14500
WHERE maintenance_id = (SELECT MAX(maintenance_id) FROM MAINTENANCE_RECORD);
COMMIT;

-- (d) FARMER: full lifecycle demo - register, update, then delete (this new
--     farmer has zero bookings, so trg_farmer_prevent_delete_bd from Phase X
--     will correctly allow the delete to proceed)
DECLARE
    v_new_farmer_id NUMBER;
BEGIN
    sp_register_farmer('Test','Auditor','0788999999','test.auditor@gmail.com',
                        '1199999999999','Demo Address, Kigali', v_new_farmer_id);

    UPDATE FARMER SET phone = '0788888888' WHERE farmer_id = v_new_farmer_id;
    COMMIT;

    DELETE FROM FARMER WHERE farmer_id = v_new_farmer_id;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Farmer lifecycle demo complete for farmer_id ' || v_new_farmer_id);
END;
/

--------------------------------------------------------------------------------
-- EXAMPLE QUERIES: retrieving the audit trail
--------------------------------------------------------------------------------

-- All audit activity, most recent first
SELECT audit_id, table_name, operation, record_id, changed_by, changed_at, old_value, new_value
FROM AUDIT_LOG
ORDER BY changed_at DESC;

-- Audit activity for one table only
SELECT * FROM AUDIT_LOG WHERE table_name = 'PAYMENT' ORDER BY changed_at DESC;

-- Everything a specific session user has changed (accountability query)
SELECT table_name, operation, COUNT(*) AS change_count
FROM AUDIT_LOG
WHERE changed_by = USER
GROUP BY table_name, operation
ORDER BY table_name;

-- Full history for one specific record (dispute-resolution query)
SELECT * FROM AUDIT_LOG
WHERE table_name = 'MAINTENANCE_RECORD' AND record_id = (SELECT MAX(maintenance_id) FROM MAINTENANCE_RECORD)
ORDER BY changed_at;

--------------------------------------------------------------------------------
-- End of Phase XIV: Database Auditing
--------------------------------------------------------------------------------
