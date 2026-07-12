--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase XI: Packages
--------------------------------------------------------------------------------
-- Run this AFTER all previous phase scripts (CreateTables through Triggers).
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- PACKAGE 1: PKG_CROP_MANAGEMENT
-- Business purpose: groups every operation a farmer or agronomist performs
-- around a single crop's lifecycle -- registering it, updating it, and
-- checking on its progress -- into one cohesive, easy-to-find unit instead
-- of scattered standalone objects.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_CROP_MANAGEMENT AS

    -- Registers a new crop on an existing farm plot
    PROCEDURE sp_register_crop (
        p_farm_id        IN  NUMBER,
        p_crop_name      IN  VARCHAR2,
        p_planting_date  IN  DATE,
        p_season         IN  VARCHAR2,
        p_new_crop_id    OUT NUMBER
    );

    -- Updates the harvest date and/or season of an existing crop
    PROCEDURE sp_update_crop_info (
        p_crop_id        IN NUMBER,
        p_harvest_date   IN DATE DEFAULT NULL,
        p_season         IN VARCHAR2 DEFAULT NULL
    );

    -- Returns how long a crop has been (or was) growing, in days
    FUNCTION fn_crop_days_in_ground (
        p_crop_id IN NUMBER
    ) RETURN NUMBER;

    -- Returns 'YES' or 'NO' depending on whether the crop's harvest_date
    -- has arrived
    FUNCTION fn_is_crop_ready_for_harvest (
        p_crop_id IN NUMBER
    ) RETURN VARCHAR2;

END PKG_CROP_MANAGEMENT;
/

CREATE OR REPLACE PACKAGE BODY PKG_CROP_MANAGEMENT AS

    PROCEDURE sp_register_crop (
        p_farm_id        IN  NUMBER,
        p_crop_name      IN  VARCHAR2,
        p_planting_date  IN  DATE,
        p_season         IN  VARCHAR2,
        p_new_crop_id    OUT NUMBER
    ) IS
        v_farm_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_farm_exists FROM FARM WHERE farm_id = p_farm_id;
        IF v_farm_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20050, 'Farm ID ' || p_farm_id || ' does not exist.');
        END IF;

        SELECT seq_crop.NEXTVAL INTO p_new_crop_id FROM DUAL;

        INSERT INTO CROP (crop_id, farm_id, crop_name, planting_date, harvest_date, season)
        VALUES (p_new_crop_id, p_farm_id, p_crop_name, p_planting_date, NULL, p_season);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Crop registered. New crop_id = ' || p_new_crop_id);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20099, 'sp_register_crop failed: ' || SQLERRM);
    END sp_register_crop;


    PROCEDURE sp_update_crop_info (
        p_crop_id        IN NUMBER,
        p_harvest_date   IN DATE DEFAULT NULL,
        p_season         IN VARCHAR2 DEFAULT NULL
    ) IS
        v_rows_updated NUMBER;
    BEGIN
        UPDATE CROP
        SET harvest_date = NVL(p_harvest_date, harvest_date),
            season       = NVL(p_season, season)
        WHERE crop_id = p_crop_id;

        v_rows_updated := SQL%ROWCOUNT;
        IF v_rows_updated = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'Crop ID ' || p_crop_id || ' does not exist.');
        END IF;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Crop ' || p_crop_id || ' updated successfully.');

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20099, 'sp_update_crop_info failed: ' || SQLERRM);
    END sp_update_crop_info;


    FUNCTION fn_crop_days_in_ground (
        p_crop_id IN NUMBER
    ) RETURN NUMBER IS
        v_planting_date DATE;
        v_harvest_date  DATE;
    BEGIN
        SELECT planting_date, harvest_date INTO v_planting_date, v_harvest_date
        FROM CROP WHERE crop_id = p_crop_id;

        IF v_harvest_date IS NULL THEN
            RETURN ROUND(SYSDATE - v_planting_date);
        ELSE
            RETURN ROUND(v_harvest_date - v_planting_date);
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20052, 'Crop ID ' || p_crop_id || ' does not exist.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'fn_crop_days_in_ground failed: ' || SQLERRM);
    END fn_crop_days_in_ground;


    FUNCTION fn_is_crop_ready_for_harvest (
        p_crop_id IN NUMBER
    ) RETURN VARCHAR2 IS
        v_harvest_date DATE;
    BEGIN
        SELECT harvest_date INTO v_harvest_date FROM CROP WHERE crop_id = p_crop_id;

        IF v_harvest_date IS NOT NULL AND v_harvest_date <= SYSDATE THEN
            RETURN 'YES';
        ELSE
            RETURN 'NO';
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20053, 'Crop ID ' || p_crop_id || ' does not exist.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'fn_is_crop_ready_for_harvest failed: ' || SQLERRM);
    END fn_is_crop_ready_for_harvest;

END PKG_CROP_MANAGEMENT;
/

-- Example calls:
-- DECLARE
--     v_new_id NUMBER;
-- BEGIN
--     PKG_CROP_MANAGEMENT.sp_register_crop(3, 'Soybeans', DATE '2026-08-01', 'C', v_new_id);
--     PKG_CROP_MANAGEMENT.sp_update_crop_info(v_new_id, DATE '2026-11-15', NULL);
--     DBMS_OUTPUT.PUT_LINE('Days in ground: ' || PKG_CROP_MANAGEMENT.fn_crop_days_in_ground(v_new_id));
--     DBMS_OUTPUT.PUT_LINE('Ready for harvest? ' || PKG_CROP_MANAGEMENT.fn_is_crop_ready_for_harvest(v_new_id));
-- END;
-- /


--------------------------------------------------------------------------------
-- PACKAGE 2: PKG_FARM_OPERATIONS
-- Business purpose: groups the day-to-day operational actions of the
-- rental business -- assigning a technician to service work, scheduling an
-- equipment booking for a farm activity, and reporting on activity cost
-- and completion counts.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_FARM_OPERATIONS AS

    -- Assigns (or reassigns) the technician responsible for a maintenance job
    PROCEDURE sp_assign_technician (
        p_maintenance_id IN NUMBER,
        p_technician_id  IN NUMBER
    );

    -- Schedules a farm activity by creating an equipment booking
    -- (includes the same overlap-conflict guard as sp_create_booking)
    PROCEDURE sp_schedule_activity (
        p_farmer_id      IN  NUMBER,
        p_equipment_id   IN  NUMBER,
        p_start_date     IN  DATE,
        p_end_date       IN  DATE,
        p_new_booking_id OUT NUMBER
    );

    -- Returns the total cost of one activity (equipment daily_rate x rental days)
    FUNCTION fn_activity_cost (
        p_booking_id IN NUMBER
    ) RETURN NUMBER;

    -- Returns how many activities (bookings) a farmer has fully completed
    FUNCTION fn_count_completed_activities (
        p_farmer_id IN NUMBER
    ) RETURN NUMBER;

END PKG_FARM_OPERATIONS;
/

CREATE OR REPLACE PACKAGE BODY PKG_FARM_OPERATIONS AS

    PROCEDURE sp_assign_technician (
        p_maintenance_id IN NUMBER,
        p_technician_id  IN NUMBER
    ) IS
        v_tech_exists NUMBER;
        v_rows_updated NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_tech_exists FROM TECHNICIAN WHERE technician_id = p_technician_id;
        IF v_tech_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20054, 'Technician ID ' || p_technician_id || ' does not exist.');
        END IF;

        UPDATE MAINTENANCE_RECORD
        SET technician_id = p_technician_id
        WHERE maintenance_id = p_maintenance_id;

        v_rows_updated := SQL%ROWCOUNT;
        IF v_rows_updated = 0 THEN
            RAISE_APPLICATION_ERROR(-20055, 'Maintenance ID ' || p_maintenance_id || ' does not exist.');
        END IF;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Technician ' || p_technician_id || ' assigned to maintenance job ' || p_maintenance_id || '.');

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20099, 'sp_assign_technician failed: ' || SQLERRM);
    END sp_assign_technician;


    PROCEDURE sp_schedule_activity (
        p_farmer_id      IN  NUMBER,
        p_equipment_id   IN  NUMBER,
        p_start_date     IN  DATE,
        p_end_date       IN  DATE,
        p_new_booking_id OUT NUMBER
    ) IS
        v_conflict_count NUMBER;
    BEGIN
        IF p_end_date < p_start_date THEN
            RAISE_APPLICATION_ERROR(-20056, 'End date cannot be before start date.');
        END IF;

        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING
        WHERE equipment_id = p_equipment_id
          AND status IN ('CONFIRMED', 'PENDING')
          AND p_start_date <= end_date
          AND p_end_date   >= start_date;

        IF v_conflict_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20057,
                'Equipment ' || p_equipment_id || ' already has a conflicting booking for that date range.');
        END IF;

        SELECT seq_booking.NEXTVAL INTO p_new_booking_id FROM DUAL;

        INSERT INTO BOOKING (booking_id, farmer_id, equipment_id, start_date, end_date, status, created_at)
        VALUES (p_new_booking_id, p_farmer_id, p_equipment_id, p_start_date, p_end_date, 'PENDING', SYSDATE);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Activity scheduled. New booking_id = ' || p_new_booking_id);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20099, 'sp_schedule_activity failed: ' || SQLERRM);
    END sp_schedule_activity;


    FUNCTION fn_activity_cost (
        p_booking_id IN NUMBER
    ) RETURN NUMBER IS
        v_daily_rate NUMBER;
        v_days       NUMBER;
    BEGIN
        SELECT e.daily_rate, (b.end_date - b.start_date + 1)
        INTO v_daily_rate, v_days
        FROM BOOKING b
        JOIN EQUIPMENT e ON b.equipment_id = e.equipment_id
        WHERE b.booking_id = p_booking_id;

        RETURN v_daily_rate * v_days;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20058, 'Booking ID ' || p_booking_id || ' does not exist.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'fn_activity_cost failed: ' || SQLERRM);
    END fn_activity_cost;


    FUNCTION fn_count_completed_activities (
        p_farmer_id IN NUMBER
    ) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM BOOKING
        WHERE farmer_id = p_farmer_id
          AND status = 'COMPLETED';

        RETURN v_count;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'fn_count_completed_activities failed: ' || SQLERRM);
    END fn_count_completed_activities;

END PKG_FARM_OPERATIONS;
/

-- Example calls:
-- DECLARE
--     v_new_booking NUMBER;
-- BEGIN
--     PKG_FARM_OPERATIONS.sp_assign_technician(3, 4);
--     PKG_FARM_OPERATIONS.sp_schedule_activity(7, 12, DATE '2026-09-01', DATE '2026-09-03', v_new_booking);
--     DBMS_OUTPUT.PUT_LINE('Activity cost: ' || PKG_FARM_OPERATIONS.fn_activity_cost(v_new_booking));
--     DBMS_OUTPUT.PUT_LINE('Completed activities for farmer 7: ' || PKG_FARM_OPERATIONS.fn_count_completed_activities(7));
-- END;
-- /


--------------------------------------------------------------------------------
-- PACKAGE 3: PKG_REPORTS
-- Business purpose: centralizes every management-facing reporting
-- calculation in one place, so the Oracle APEX dashboard (Phase XIII) has
-- a single, consistent API to call rather than duplicating SQL across
-- multiple report pages.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_REPORTS AS

    -- Total PAID revenue, optionally filtered to one equipment owner
    -- (pass NULL for system-wide total across all owners)
    FUNCTION fn_total_revenue (
        p_owner_id IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    -- Counts bookings currently in an "active" state (PENDING or CONFIRMED)
    FUNCTION fn_count_active_bookings RETURN NUMBER;

    -- Prints a summary report for one farm: crop count, latest sensor
    -- readings, and farmer contact details
    PROCEDURE sp_generate_farm_summary (
        p_farm_id IN NUMBER
    );

    -- Prints system-wide operational statistics using the Phase VII
    -- dashboard view
    PROCEDURE sp_display_operational_stats;

END PKG_REPORTS;
/

CREATE OR REPLACE PACKAGE BODY PKG_REPORTS AS

    FUNCTION fn_total_revenue (
        p_owner_id IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        IF p_owner_id IS NULL THEN
            SELECT NVL(SUM(amount), 0) INTO v_total FROM PAYMENT WHERE status = 'PAID';
        ELSE
            SELECT NVL(SUM(p.amount), 0) INTO v_total
            FROM PAYMENT p
            JOIN BOOKING b   ON p.booking_id  = b.booking_id
            JOIN EQUIPMENT e ON b.equipment_id = e.equipment_id
            WHERE e.owner_id = p_owner_id
              AND p.status = 'PAID';
        END IF;

        RETURN v_total;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'fn_total_revenue failed: ' || SQLERRM);
    END fn_total_revenue;


    FUNCTION fn_count_active_bookings RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM BOOKING WHERE status IN ('PENDING', 'CONFIRMED');
        RETURN v_count;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'fn_count_active_bookings failed: ' || SQLERRM);
    END fn_count_active_bookings;


    PROCEDURE sp_generate_farm_summary (
        p_farm_id IN NUMBER
    ) IS
        v_location      FARM.location%TYPE;
        v_farmer_name   VARCHAR2(100);
        v_crop_count    NUMBER;
        v_avg_moisture  NUMBER;
    BEGIN
        SELECT f.location, fr.first_name || ' ' || fr.last_name
        INTO v_location, v_farmer_name
        FROM FARM f
        JOIN FARMER fr ON f.farmer_id = fr.farmer_id
        WHERE f.farm_id = p_farm_id;

        SELECT COUNT(*) INTO v_crop_count FROM CROP WHERE farm_id = p_farm_id;

        SELECT ROUND(AVG(soil_moisture), 2) INTO v_avg_moisture
        FROM SENSOR_READING WHERE farm_id = p_farm_id;

        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('FARM SUMMARY REPORT - Farm ID ' || p_farm_id);
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Location       : ' || v_location);
        DBMS_OUTPUT.PUT_LINE('Farmer         : ' || v_farmer_name);
        DBMS_OUTPUT.PUT_LINE('Crops recorded : ' || v_crop_count);
        DBMS_OUTPUT.PUT_LINE('Avg soil moist.: ' || NVL(TO_CHAR(v_avg_moisture), 'No readings yet') || '%');
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20059, 'Farm ID ' || p_farm_id || ' does not exist.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'sp_generate_farm_summary failed: ' || SQLERRM);
    END sp_generate_farm_summary;


    PROCEDURE sp_display_operational_stats IS
        v_stats VW_FARM_DASHBOARD_SUMMARY%ROWTYPE;
    BEGIN
        SELECT * INTO v_stats FROM VW_FARM_DASHBOARD_SUMMARY;

        DBMS_OUTPUT.PUT_LINE('==================================================');
        DBMS_OUTPUT.PUT_LINE('SARFOMS - OPERATIONAL STATISTICS');
        DBMS_OUTPUT.PUT_LINE('==================================================');
        DBMS_OUTPUT.PUT_LINE('Total farmers                : ' || v_stats.total_farmers);
        DBMS_OUTPUT.PUT_LINE('Total farms                  : ' || v_stats.total_farms);
        DBMS_OUTPUT.PUT_LINE('Total equipment               : ' || v_stats.total_equipment);
        DBMS_OUTPUT.PUT_LINE('Equipment currently rented    : ' || v_stats.equipment_currently_rented);
        DBMS_OUTPUT.PUT_LINE('Equipment in maintenance      : ' || v_stats.equipment_in_maintenance);
        DBMS_OUTPUT.PUT_LINE('Equipment retired             : ' || v_stats.equipment_retired);
        DBMS_OUTPUT.PUT_LINE('Active bookings               : ' || v_stats.active_bookings);
        DBMS_OUTPUT.PUT_LINE('Total revenue collected       : ' || v_stats.total_revenue_collected);
        DBMS_OUTPUT.PUT_LINE('Total outstanding payments    : ' || v_stats.total_outstanding_payments);
        DBMS_OUTPUT.PUT_LINE('==================================================');

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20099, 'sp_display_operational_stats failed: ' || SQLERRM);
    END sp_display_operational_stats;

END PKG_REPORTS;
/

-- Example calls:
-- BEGIN
--     DBMS_OUTPUT.PUT_LINE('Total system revenue: ' || PKG_REPORTS.fn_total_revenue(NULL));
--     DBMS_OUTPUT.PUT_LINE('Revenue for owner 8: ' || PKG_REPORTS.fn_total_revenue(8));
--     DBMS_OUTPUT.PUT_LINE('Active bookings: ' || PKG_REPORTS.fn_count_active_bookings);
--     PKG_REPORTS.sp_generate_farm_summary(1);
--     PKG_REPORTS.sp_display_operational_stats;
-- END;
-- /

--------------------------------------------------------------------------------
-- End of Phase XI: Packages
--------------------------------------------------------------------------------
