--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase XII/XIII: Cursors
--------------------------------------------------------------------------------
-- Run this AFTER all previous phase scripts. Each block is a standalone
-- anonymous PL/SQL block -- run them individually in SQL Developer with
-- SET SERVEROUTPUT ON to see the DBMS_OUTPUT results.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- 1. EXPLICIT CURSOR - Display all active (still-growing) crops
-- Technique: explicit cursor with manual OPEN / FETCH / EXIT WHEN %NOTFOUND / CLOSE
-- Purpose: "active" here means harvest_date IS NULL -- the crop is still in
-- the ground and has not yet been harvested.
--------------------------------------------------------------------------------
DECLARE
    CURSOR cur_active_crops IS
        SELECT crop_id, crop_name, farm_id, planting_date
        FROM CROP
        WHERE harvest_date IS NULL
        ORDER BY planting_date;

    v_crop_id       CROP.crop_id%TYPE;
    v_crop_name     CROP.crop_name%TYPE;
    v_farm_id       CROP.farm_id%TYPE;
    v_planting_date CROP.planting_date%TYPE;
BEGIN
    OPEN cur_active_crops;
    LOOP
        FETCH cur_active_crops INTO v_crop_id, v_crop_name, v_farm_id, v_planting_date;
        EXIT WHEN cur_active_crops%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Crop ' || v_crop_id || ': ' || v_crop_name ||
                              ' (Farm ' || v_farm_id || ') planted ' ||
                              TO_CHAR(v_planting_date, 'DD-MON-YYYY'));
    END LOOP;
    CLOSE cur_active_crops;
END;
/

--------------------------------------------------------------------------------
-- 2. PARAMETERIZED CURSOR - List technicians' assigned maintenance jobs
-- (the "farm worker assigned to activities" equivalent -- our schema's
-- workers are TECHNICIANs, and their activities are MAINTENANCE_RECORDs)
--------------------------------------------------------------------------------
DECLARE
    CURSOR cur_technician_jobs (p_technician_id NUMBER) IS
        SELECT maintenance_id, equipment_id, service_date, description, cost
        FROM MAINTENANCE_RECORD
        WHERE technician_id = p_technician_id
        ORDER BY service_date DESC;

    v_rec cur_technician_jobs%ROWTYPE;
BEGIN
    OPEN cur_technician_jobs(1);  -- David Habimana, technician_id = 1
    LOOP
        FETCH cur_technician_jobs INTO v_rec;
        EXIT WHEN cur_technician_jobs%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Job ' || v_rec.maintenance_id || ' - Equipment ' ||
                              v_rec.equipment_id || ' - ' || v_rec.description);
    END LOOP;
    CLOSE cur_technician_jobs;
END;
/

--------------------------------------------------------------------------------
-- 3. CURSOR FOR LOOP - Show scheduled (not-yet-completed) farming activities
-- Technique: Oracle handles OPEN/FETCH/CLOSE automatically inside the loop
--------------------------------------------------------------------------------
BEGIN
    FOR rec IN (
        SELECT booking_id, farmer_id, equipment_id, start_date, end_date, status
        FROM BOOKING
        WHERE status IN ('PENDING', 'CONFIRMED')
        ORDER BY start_date
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Booking ' || rec.booking_id || ': farmer ' || rec.farmer_id ||
                              ', equipment ' || rec.equipment_id || ', ' ||
                              TO_CHAR(rec.start_date, 'DD-MON-YYYY') || ' to ' ||
                              TO_CHAR(rec.end_date, 'DD-MON-YYYY') || ' [' || rec.status || ']');
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 4. EXPLICIT CURSOR with %ROWCOUNT - Display crops ready for harvest
--------------------------------------------------------------------------------
DECLARE
    CURSOR cur_ready_crops IS
        SELECT crop_id, crop_name, harvest_date
        FROM CROP
        WHERE harvest_date IS NOT NULL AND harvest_date <= SYSDATE
        ORDER BY harvest_date;

    v_rec cur_ready_crops%ROWTYPE;
BEGIN
    OPEN cur_ready_crops;
    LOOP
        FETCH cur_ready_crops INTO v_rec;
        EXIT WHEN cur_ready_crops%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('READY: ' || v_rec.crop_name || ' (Crop ' || v_rec.crop_id ||
                              ') - harvest date ' || TO_CHAR(v_rec.harvest_date, 'DD-MON-YYYY'));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Total ready-for-harvest crops: ' || cur_ready_crops%ROWCOUNT);
    CLOSE cur_ready_crops;
END;
/

--------------------------------------------------------------------------------
-- 5. CURSOR FOR LOOP over a VIEW - List equipment requiring maintenance
-- Demonstrates that a cursor can iterate over a view exactly like a table --
-- reusing VW_SERVICE_DUE_REMINDER from Phase VII instead of duplicating SQL.
--------------------------------------------------------------------------------
BEGIN
    FOR rec IN (SELECT equipment_id, equipment_name, days_since_last_service
                FROM VW_SERVICE_DUE_REMINDER)
    LOOP
        DBMS_OUTPUT.PUT_LINE('Equipment ' || rec.equipment_id || ' (' || rec.equipment_name ||
                              ') needs service - ' ||
                              NVL(TO_CHAR(rec.days_since_last_service), 'never serviced') || ' days.');
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 6. PARAMETERIZED CURSOR - Display recent harvest records
-- The parameter (days back) makes this cursor reusable for any lookback
-- window without rewriting the query.
--------------------------------------------------------------------------------
DECLARE
    CURSOR cur_recent_harvests (p_days_back NUMBER) IS
        SELECT crop_id, crop_name, harvest_date
        FROM CROP
        WHERE harvest_date IS NOT NULL
          AND harvest_date >= SYSDATE - p_days_back
        ORDER BY harvest_date DESC;

    v_rec cur_recent_harvests%ROWTYPE;
BEGIN
    OPEN cur_recent_harvests(120);  -- last 120 days
    LOOP
        FETCH cur_recent_harvests INTO v_rec;
        EXIT WHEN cur_recent_harvests%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Harvested: ' || v_rec.crop_name || ' on ' ||
                              TO_CHAR(v_rec.harvest_date, 'DD-MON-YYYY'));
    END LOOP;
    CLOSE cur_recent_harvests;
END;
/

--------------------------------------------------------------------------------
-- 7. CURSOR FOR LOOP - Generate a crop summary report
-- Combines a join (CROP + FARM) with a package function call
-- (PKG_CROP_MANAGEMENT.fn_crop_days_in_ground from Phase XI) inside the loop.
--------------------------------------------------------------------------------
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('CROP', 16) || RPAD('LOCATION', 26) || 'DAYS IN GROUND');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 55, '-'));

    FOR rec IN (
        SELECT c.crop_id, c.crop_name, f.location
        FROM CROP c JOIN FARM f ON c.farm_id = f.farm_id
        ORDER BY f.location
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(rec.crop_name, 16) || RPAD(rec.location, 26) ||
                              PKG_CROP_MANAGEMENT.fn_crop_days_in_ground(rec.crop_id));
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 8. EXPLICIT CURSOR - Count records using cursor attributes
-- Demonstrates all four cursor attributes explicitly: %ISOPEN, %FOUND,
-- %NOTFOUND, and %ROWCOUNT.
--------------------------------------------------------------------------------
DECLARE
    CURSOR cur_equipment IS
        SELECT equipment_id, equipment_name, status FROM EQUIPMENT;

    v_rec cur_equipment%ROWTYPE;
BEGIN
    IF NOT cur_equipment%ISOPEN THEN
        OPEN cur_equipment;
    END IF;

    LOOP
        FETCH cur_equipment INTO v_rec;
        EXIT WHEN cur_equipment%NOTFOUND;   -- %NOTFOUND ends the loop
        IF cur_equipment%FOUND THEN          -- %FOUND confirms a row was fetched
            DBMS_OUTPUT.PUT_LINE('Row ' || cur_equipment%ROWCOUNT || ': ' ||
                                  v_rec.equipment_name || ' - ' || v_rec.status);
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Cursor still open before CLOSE? ' ||
                          CASE WHEN cur_equipment%ISOPEN THEN 'YES' ELSE 'NO' END);
    DBMS_OUTPUT.PUT_LINE('Total rows processed (%ROWCOUNT): ' || cur_equipment%ROWCOUNT);
    CLOSE cur_equipment;
END;
/

--------------------------------------------------------------------------------
-- 9. PARAMETERIZED CURSOR - Bookings for one specific farmer
-- Dedicated example demonstrating a cursor parameter used directly in OPEN.
--------------------------------------------------------------------------------
DECLARE
    CURSOR cur_farmer_bookings (p_farmer_id NUMBER) IS
        SELECT booking_id, equipment_id, start_date, end_date, status
        FROM BOOKING
        WHERE farmer_id = p_farmer_id
        ORDER BY start_date;

    v_rec cur_farmer_bookings%ROWTYPE;
BEGIN
    OPEN cur_farmer_bookings(1);  -- Jean Bosco Habimana, farmer_id = 1
    LOOP
        FETCH cur_farmer_bookings INTO v_rec;
        EXIT WHEN cur_farmer_bookings%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Booking ' || v_rec.booking_id || ' - equipment ' ||
                              v_rec.equipment_id || ' [' || v_rec.status || ']');
    END LOOP;
    CLOSE cur_farmer_bookings;
END;
/

--------------------------------------------------------------------------------
-- 10. IMPLICIT CURSOR + CURSOR FOR LOOP - combined demonstration
-- Part A: an implicit cursor is automatically created by Oracle for any
-- single SQL statement (UPDATE, DELETE, or SELECT INTO) -- no DECLARE
-- needed. SQL%ROWCOUNT and SQL%FOUND refer to that automatic cursor.
-- Part B: a cursor FOR loop, where Oracle again manages OPEN/FETCH/CLOSE.
--------------------------------------------------------------------------------
BEGIN
    -- Part A: implicit cursor
    UPDATE EQUIPMENT SET status = 'AVAILABLE' WHERE status = 'AVAILABLE';
    DBMS_OUTPUT.PUT_LINE('Implicit cursor SQL%ROWCOUNT: ' || SQL%ROWCOUNT || ' row(s) touched.');
    DBMS_OUTPUT.PUT_LINE('Implicit cursor SQL%FOUND: ' ||
                          CASE WHEN SQL%FOUND THEN 'TRUE' ELSE 'FALSE' END);

    -- Part B: cursor FOR loop
    FOR rec IN (SELECT farmer_id, first_name, last_name FROM FARMER ORDER BY farmer_id)
    LOOP
        DBMS_OUTPUT.PUT_LINE(rec.farmer_id || ': ' || rec.first_name || ' ' || rec.last_name);
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- End of Phase XII/XIII: Cursors
--------------------------------------------------------------------------------
