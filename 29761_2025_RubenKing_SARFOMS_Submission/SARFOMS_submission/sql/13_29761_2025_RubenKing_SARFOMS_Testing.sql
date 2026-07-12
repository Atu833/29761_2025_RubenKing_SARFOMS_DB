--------------------------------------------------------------------------------
-- DPR400210 Capstone Project
-- Smart Agricultural Resource and Farm Operations Management System (SARFOMS)
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase XVII: Testing & Validation
--------------------------------------------------------------------------------
-- Run this AFTER all previous phase scripts (CreateTables through
-- AdvancedQueries/ManagementReports). This script is READ-SAFE: every test
-- that inserts, updates, or deletes data wraps its own change in a
-- SAVEPOINT/ROLLBACK so the sample dataset is unchanged after this script
-- finishes, regardless of pass or fail outcome.
--
-- TEST RESULT CATEGORIES:
--   [PASS] - the expected behavior was observed
--   [FAIL] - the expected behavior was NOT observed (needs investigation)
--   [SKIP] - the test could not run in a meaningful way under today's date
--            (specifically, the Phase X mandatory weekday/holiday lock on
--            BOOKING makes some BOOKING-table tests only demonstrable on a
--            weekend/non-holiday -- this is documented per test, not hidden)
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_pass_count NUMBER := 0;
    v_fail_count NUMBER := 0;
    v_skip_count NUMBER := 0;

    PROCEDURE sp_assert(p_test_id VARCHAR2, p_description VARCHAR2, p_condition BOOLEAN) IS
    BEGIN
        IF p_condition THEN
            v_pass_count := v_pass_count + 1;
            DBMS_OUTPUT.PUT_LINE('[PASS] ' || p_test_id || ' - ' || p_description);
        ELSE
            v_fail_count := v_fail_count + 1;
            DBMS_OUTPUT.PUT_LINE('[FAIL] ' || p_test_id || ' - ' || p_description);
        END IF;
    END sp_assert;

    PROCEDURE sp_skip(p_test_id VARCHAR2, p_reason VARCHAR2) IS
    BEGIN
        v_skip_count := v_skip_count + 1;
        DBMS_OUTPUT.PUT_LINE('[SKIP] ' || p_test_id || ' - ' || p_reason);
    END sp_skip;

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('SARFOMS TEST SUITE - Run date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('================================================================');

    --------------------------------------------------------------------------
    -- T01: All 13 core tables exist and are queryable
    --------------------------------------------------------------------------
    DECLARE
        v_count NUMBER;
        v_all_ok BOOLEAN := TRUE;
        TYPE t_tab_list IS TABLE OF VARCHAR2(30);
        v_tables t_tab_list := t_tab_list(
            'FARMER','FARM','CROP','EQUIPMENT_CATEGORY','EQUIPMENT_OWNER','EQUIPMENT',
            'BOOKING','PAYMENT','TECHNICIAN','MAINTENANCE_RECORD','SENSOR_READING',
            'PUBLIC_HOLIDAY','AUDIT_LOG'
        );
    BEGIN
        FOR i IN 1 .. v_tables.COUNT LOOP
            BEGIN
                EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || v_tables(i) INTO v_count;
            EXCEPTION
                WHEN OTHERS THEN
                    v_all_ok := FALSE;
                    DBMS_OUTPUT.PUT_LINE('    -> Table ' || v_tables(i) || ' is not queryable: ' || SQLERRM);
            END;
        END LOOP;
        sp_assert('T01', 'All 13 core tables exist and are queryable', v_all_ok);
    END;

    --------------------------------------------------------------------------
    -- T02 / T03: Sample data volume sanity checks
    --------------------------------------------------------------------------
    DECLARE
        v_farmer_count  NUMBER;
        v_booking_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_farmer_count FROM FARMER;
        SELECT COUNT(*) INTO v_booking_count FROM BOOKING;
        sp_assert('T02', 'FARMER has at least 15 sample rows (found ' || v_farmer_count || ')', v_farmer_count >= 15);
        sp_assert('T03', 'BOOKING has at least 20 sample rows (found ' || v_booking_count || ')', v_booking_count >= 20);
    END;

    --------------------------------------------------------------------------
    -- T04: CHECK constraint - negative EQUIPMENT.daily_rate rejected
    --------------------------------------------------------------------------
    DECLARE
        v_rejected BOOLEAN := FALSE;
    BEGIN
        SAVEPOINT sp_t04;
        BEGIN
            INSERT INTO EQUIPMENT (equipment_id, category_id, owner_id, equipment_name, model, daily_rate, status, acquisition_date)
            VALUES (seq_equipment.NEXTVAL, 1, 1, 'Test Rig', 'TR-1', -500, 'AVAILABLE', SYSDATE);
        EXCEPTION
            WHEN OTHERS THEN v_rejected := TRUE;
        END;
        ROLLBACK TO sp_t04;
        sp_assert('T04', 'Negative EQUIPMENT.daily_rate is rejected', v_rejected);
    END;

    --------------------------------------------------------------------------
    -- T05: CHECK constraint - FARM.size_hectares <= 0 rejected
    --------------------------------------------------------------------------
    DECLARE
        v_rejected BOOLEAN := FALSE;
    BEGIN
        SAVEPOINT sp_t05;
        BEGIN
            INSERT INTO FARM (farm_id, farmer_id, location, size_hectares, soil_type)
            VALUES (seq_farm.NEXTVAL, 1, 'Test Plot', -2, 'Loam');
        EXCEPTION
            WHEN OTHERS THEN v_rejected := TRUE;
        END;
        ROLLBACK TO sp_t05;
        sp_assert('T05', 'Non-positive FARM.size_hectares is rejected', v_rejected);
    END;

    --------------------------------------------------------------------------
    -- T06: UNIQUE constraint - duplicate FARMER.national_id rejected
    --------------------------------------------------------------------------
    DECLARE
        v_rejected BOOLEAN := FALSE;
    BEGIN
        SAVEPOINT sp_t06;
        BEGIN
            INSERT INTO FARMER (farmer_id, first_name, last_name, phone, email, national_id, address, registration_date)
            VALUES (seq_farmer.NEXTVAL, 'Duplicate', 'Test', '0788000000', 'dup@test.com', '1198010010001', 'Test', SYSDATE);
            -- '1198010010001' already belongs to farmer_id 1 (Jean Bosco Habimana)
        EXCEPTION
            WHEN OTHERS THEN v_rejected := TRUE;
        END;
        ROLLBACK TO sp_t06;
        sp_assert('T06', 'Duplicate FARMER.national_id is rejected', v_rejected);
    END;

    --------------------------------------------------------------------------
    -- T07: FK constraint - BOOKING with non-existent equipment_id rejected
    --------------------------------------------------------------------------
    DECLARE
        v_rejected BOOLEAN := FALSE;
    BEGIN
        SAVEPOINT sp_t07;
        BEGIN
            INSERT INTO BOOKING (booking_id, farmer_id, equipment_id, start_date, end_date, status, created_at)
            VALUES (seq_booking.NEXTVAL, 1, 999999, SYSDATE+5, SYSDATE+7, 'PENDING', SYSDATE);
        EXCEPTION
            WHEN OTHERS THEN v_rejected := TRUE;
        END;
        ROLLBACK TO sp_t07;
        sp_assert('T07', 'BOOKING with an invalid equipment_id is rejected (FK)', v_rejected);
    END;

    --------------------------------------------------------------------------
    -- T08: Mandatory business rule - weekday/holiday lock on BOOKING
    -- Adaptive: the expected outcome depends on today's actual date, so this
    -- test checks the calendar first and asserts the CORRECT behavior for
    -- today rather than hardcoding an assumption.
    --------------------------------------------------------------------------
    DECLARE
        v_day_name   VARCHAR2(3) := TRIM(TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH'));
        v_is_holiday NUMBER;
        v_blocked    BOOLEAN := FALSE;
    BEGIN
        SELECT COUNT(*) INTO v_is_holiday FROM PUBLIC_HOLIDAY WHERE holiday_date = TRUNC(SYSDATE);

        SAVEPOINT sp_t08;
        BEGIN
            INSERT INTO BOOKING (booking_id, farmer_id, equipment_id, start_date, end_date, status, created_at)
            VALUES (seq_booking.NEXTVAL, 2, 3, SYSDATE+20, SYSDATE+22, 'PENDING', SYSDATE);
        EXCEPTION
            WHEN OTHERS THEN v_blocked := TRUE;
        END;
        ROLLBACK TO sp_t08;

        IF v_day_name NOT IN ('SAT', 'SUN') OR v_is_holiday > 0 THEN
            sp_assert('T08', 'Weekday/holiday lock correctly blocks BOOKING changes today (' || v_day_name || ')', v_blocked);
        ELSE
            sp_assert('T08', 'BOOKING insert correctly succeeds on a weekend/non-holiday (' || v_day_name || ')', NOT v_blocked);
        END IF;
    END;

    --------------------------------------------------------------------------
    -- T09: Booking overlap-conflict DETECTION LOGIC (tested directly against
    -- the query, independent of the day-of-week restriction in T08, since
    -- sp_create_booking's INSERT would otherwise be blocked by the same
    -- weekday trigger before the overlap logic could be demonstrated)
    --------------------------------------------------------------------------
    DECLARE
        v_conflict_count NUMBER;
    BEGIN
        -- booking_id 3 and 4 (Phase V sample data) both use equipment_id 5
        -- over overlapping dates (Jun 10-15 vs Jun 13-18) -- this is the
        -- exact scenario the conflict-check query must catch
        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING
        WHERE equipment_id = 5
          AND status IN ('CONFIRMED', 'PENDING')
          AND DATE '2026-06-12' <= end_date
          AND DATE '2026-06-16' >= start_date;

        sp_assert('T09', 'Overlap-detection query correctly finds the known conflicting bookings (found ' || v_conflict_count || ')', v_conflict_count >= 2);
    END;

    --------------------------------------------------------------------------
    -- T10: Equipment status auto-sync when BOOKING.status changes
    -- (SKIPPED on a weekday because the Phase X trigger blocks the UPDATE
    -- before this cascading logic can even fire -- documented, not hidden)
    --------------------------------------------------------------------------
    DECLARE
        v_day_name VARCHAR2(3) := TRIM(TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH'));
        v_is_holiday NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_is_holiday FROM PUBLIC_HOLIDAY WHERE holiday_date = TRUNC(SYSDATE);

        IF v_day_name NOT IN ('SAT','SUN') OR v_is_holiday > 0 THEN
            sp_skip('T10', 'Cannot exercise BOOKING UPDATE today (' || v_day_name || ') due to the mandatory weekday/holiday lock -- rerun this script on a weekend to observe trg_equipment_status_sync_aiu firing.');
        ELSE
            DECLARE
                v_status_before VARCHAR2(20);
                v_status_after  VARCHAR2(20);
            BEGIN
                SAVEPOINT sp_t10;
                SELECT status INTO v_status_before FROM EQUIPMENT WHERE equipment_id = 15;
                UPDATE BOOKING SET status = 'CONFIRMED' WHERE booking_id = 10;
                SELECT status INTO v_status_after FROM EQUIPMENT WHERE equipment_id = 15;
                ROLLBACK TO sp_t10;
                sp_assert('T10', 'EQUIPMENT.status auto-updates to RENTED when its BOOKING is CONFIRMED', v_status_after = 'RENTED');
            END;
        END IF;
    END;

    --------------------------------------------------------------------------
    -- T11: Audit trigger - PAYMENT change creates a new AUDIT_LOG row
    --------------------------------------------------------------------------
    DECLARE
        v_audit_count_before NUMBER;
        v_audit_count_after  NUMBER;
    BEGIN
        SAVEPOINT sp_t11;
        SELECT COUNT(*) INTO v_audit_count_before FROM AUDIT_LOG WHERE table_name = 'PAYMENT';
        UPDATE PAYMENT SET payment_method = 'CASH' WHERE payment_id = 1;
        SELECT COUNT(*) INTO v_audit_count_after FROM AUDIT_LOG WHERE table_name = 'PAYMENT';
        ROLLBACK TO sp_t11;
        sp_assert('T11', 'PAYMENT update creates a new AUDIT_LOG entry', v_audit_count_after > v_audit_count_before);
    END;

    --------------------------------------------------------------------------
    -- T12: Referential protection - deleting a FARMER with bookings is blocked
    --------------------------------------------------------------------------
    DECLARE
        v_rejected BOOLEAN := FALSE;
    BEGIN
        SAVEPOINT sp_t12;
        BEGIN
            DELETE FROM FARMER WHERE farmer_id = 1;
        EXCEPTION
            WHEN OTHERS THEN v_rejected := TRUE;
        END;
        ROLLBACK TO sp_t12;
        sp_assert('T12', 'Deleting a FARMER with existing bookings is blocked', v_rejected);
    END;

    --------------------------------------------------------------------------
    -- T13: Referential protection - deleting a costed MAINTENANCE_RECORD is blocked
    --------------------------------------------------------------------------
    DECLARE
        v_rejected BOOLEAN := FALSE;
    BEGIN
        SAVEPOINT sp_t13;
        BEGIN
            DELETE FROM MAINTENANCE_RECORD WHERE maintenance_id = 1;
        EXCEPTION
            WHEN OTHERS THEN v_rejected := TRUE;
        END;
        ROLLBACK TO sp_t13;
        sp_assert('T13', 'Deleting a completed/costed MAINTENANCE_RECORD is blocked', v_rejected);
    END;

    --------------------------------------------------------------------------
    -- T14: Sequence generates strictly increasing values
    --------------------------------------------------------------------------
    DECLARE
        v_first  NUMBER;
        v_second NUMBER;
    BEGIN
        SELECT seq_equipment.NEXTVAL INTO v_first FROM DUAL;
        SELECT seq_equipment.NEXTVAL INTO v_second FROM DUAL;
        sp_assert('T14', 'seq_equipment.NEXTVAL increases monotonically', v_second = v_first + 1);
    END;

    --------------------------------------------------------------------------
    -- T15: View returns exactly one summary row
    --------------------------------------------------------------------------
    DECLARE
        v_row_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_row_count FROM VW_FARM_DASHBOARD_SUMMARY;
        sp_assert('T15', 'VW_FARM_DASHBOARD_SUMMARY returns exactly 1 row', v_row_count = 1);
    END;

    --------------------------------------------------------------------------
    -- T16: Service-due view never lists RETIRED equipment
    --------------------------------------------------------------------------
    DECLARE
        v_retired_leak NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_retired_leak
        FROM VW_SERVICE_DUE_REMINDER
        WHERE status = 'RETIRED';
        sp_assert('T16', 'VW_SERVICE_DUE_REMINDER never lists RETIRED equipment', v_retired_leak = 0);
    END;

    --------------------------------------------------------------------------
    -- T17: fn_is_crop_ready_for_harvest returns correct Yes/No values
    --------------------------------------------------------------------------
    DECLARE
        v_ready_result    VARCHAR2(3);
        v_not_ready_result VARCHAR2(3);
    BEGIN
        v_ready_result     := fn_is_crop_ready_for_harvest(1);  -- Irish Potatoes, harvest_date in the past
        v_not_ready_result := fn_is_crop_ready_for_harvest(2);  -- Maize, harvest_date IS NULL (still growing)
        sp_assert('T17', 'fn_is_crop_ready_for_harvest returns YES for a past-harvest crop and NO for a still-growing crop',
                  v_ready_result = 'YES' AND v_not_ready_result = 'NO');
    END;

    --------------------------------------------------------------------------
    -- T18: fn_total_maintenance_cost matches a manual SUM
    --------------------------------------------------------------------------
    DECLARE
        v_function_result NUMBER;
        v_manual_sum       NUMBER;
    BEGIN
        v_function_result := fn_total_maintenance_cost(1);
        SELECT NVL(SUM(cost), 0) INTO v_manual_sum FROM MAINTENANCE_RECORD WHERE equipment_id = 1;
        sp_assert('T18', 'fn_total_maintenance_cost(1) matches manual SUM (' || v_function_result || ' = ' || v_manual_sum || ')',
                  v_function_result = v_manual_sum);
    END;

    --------------------------------------------------------------------------
    -- T19: Package function fn_count_active_bookings matches a manual COUNT
    --------------------------------------------------------------------------
    DECLARE
        v_package_result NUMBER;
        v_manual_count    NUMBER;
    BEGIN
        v_package_result := PKG_REPORTS.fn_count_active_bookings;
        SELECT COUNT(*) INTO v_manual_count FROM BOOKING WHERE status IN ('PENDING', 'CONFIRMED');
        sp_assert('T19', 'PKG_REPORTS.fn_count_active_bookings matches manual COUNT (' || v_package_result || ' = ' || v_manual_count || ')',
                  v_package_result = v_manual_count);
    END;

    --------------------------------------------------------------------------
    -- T20: Package function fn_crop_days_in_ground matches manual calculation
    --------------------------------------------------------------------------
    DECLARE
        v_package_result NUMBER;
        v_manual_calc     NUMBER;
    BEGIN
        v_package_result := PKG_CROP_MANAGEMENT.fn_crop_days_in_ground(1);
        SELECT ROUND(harvest_date - planting_date) INTO v_manual_calc FROM CROP WHERE crop_id = 1;
        sp_assert('T20', 'PKG_CROP_MANAGEMENT.fn_crop_days_in_ground(1) matches manual calculation (' || v_package_result || ' = ' || v_manual_calc || ')',
                  v_package_result = v_manual_calc);
    END;

    --------------------------------------------------------------------------
    -- T21: Procedure sp_calculate_maintenance_cost OUT parameter is correct
    --------------------------------------------------------------------------
    DECLARE
        v_out_result NUMBER;
        v_manual_sum NUMBER;
    BEGIN
        sp_calculate_maintenance_cost(8, v_out_result);
        SELECT NVL(SUM(cost), 0) INTO v_manual_sum FROM MAINTENANCE_RECORD WHERE equipment_id = 8;
        sp_assert('T21', 'sp_calculate_maintenance_cost(8, ...) OUT parameter matches manual SUM (' || v_out_result || ' = ' || v_manual_sum || ')',
                  v_out_result = v_manual_sum);
    END;

    --------------------------------------------------------------------------
    -- T22: Explicit cursor row count matches a plain SELECT COUNT(*)
    --------------------------------------------------------------------------
    DECLARE
        CURSOR cur_test IS SELECT equipment_id FROM EQUIPMENT;
        v_cursor_count NUMBER := 0;
        v_direct_count NUMBER;
    BEGIN
        FOR rec IN cur_test LOOP
            v_cursor_count := v_cursor_count + 1;
        END LOOP;
        SELECT COUNT(*) INTO v_direct_count FROM EQUIPMENT;
        sp_assert('T22', 'Cursor FOR loop row count matches SELECT COUNT(*) (' || v_cursor_count || ' = ' || v_direct_count || ')',
                  v_cursor_count = v_direct_count);
    END;

    --------------------------------------------------------------------------
    -- SUMMARY
    --------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('TEST SUMMARY: ' || v_pass_count || ' PASSED, ' || v_fail_count ||
                          ' FAILED, ' || v_skip_count || ' SKIPPED (out of ' ||
                          (v_pass_count + v_fail_count + v_skip_count) || ' total tests)');
    DBMS_OUTPUT.PUT_LINE('================================================================');
END;
/

--------------------------------------------------------------------------------
-- End of Phase XVII: Testing & Validation (SQL)
--------------------------------------------------------------------------------
