--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase IX: PL/SQL Functions
--------------------------------------------------------------------------------
-- Run this AFTER CreateTables, InsertData, Sequences, Views, and Procedures.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- 1. fn_crop_days_in_ground
-- Business purpose: how long a crop has been (or was) growing. For a still-
-- growing crop (harvest_date IS NULL) this measures days since planting up
-- to today; for a harvested crop it measures the actual growing period.
-- This is the closest real equivalent to "yield" available in our data --
-- we track dates, not measured output quantities.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_crop_days_in_ground (
    p_crop_id IN NUMBER
) RETURN NUMBER
IS
    v_planting_date DATE;
    v_harvest_date  DATE;
    v_days          NUMBER;
BEGIN
    SELECT planting_date, harvest_date
    INTO v_planting_date, v_harvest_date
    FROM CROP
    WHERE crop_id = p_crop_id;

    IF v_harvest_date IS NULL THEN
        v_days := ROUND(SYSDATE - v_planting_date);
    ELSE
        v_days := ROUND(v_harvest_date - v_planting_date);
    END IF;

    RETURN v_days;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20020, 'Crop ID ' || p_crop_id || ' does not exist.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_crop_days_in_ground failed: ' || SQLERRM);
END fn_crop_days_in_ground;
/

-- Example usage:
-- SELECT crop_name, fn_crop_days_in_ground(crop_id) AS days_in_ground FROM CROP;

--------------------------------------------------------------------------------
-- 2. fn_farmer_total_spend
-- Business purpose: total amount a farmer has actually paid across all their
-- bookings -- the real financial-cost rollup available in our schema.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_farmer_total_spend (
    p_farmer_id IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(p.amount), 0)
    INTO v_total
    FROM PAYMENT p
    JOIN BOOKING b ON p.booking_id = b.booking_id
    WHERE b.farmer_id = p_farmer_id
      AND p.status = 'PAID';

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_farmer_total_spend failed: ' || SQLERRM);
END fn_farmer_total_spend;
/

-- Example usage:
-- SELECT first_name, last_name, fn_farmer_total_spend(farmer_id) AS total_spend FROM FARMER;

--------------------------------------------------------------------------------
-- 3. fn_equipment_total_revenue
-- Business purpose: total paid revenue a single piece of equipment has
-- generated across all its bookings -- the rental-business equivalent of
-- "revenue from sales."
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_equipment_total_revenue (
    p_equipment_id IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(p.amount), 0)
    INTO v_total
    FROM PAYMENT p
    JOIN BOOKING b ON p.booking_id = b.booking_id
    WHERE b.equipment_id = p_equipment_id
      AND p.status = 'PAID';

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_equipment_total_revenue failed: ' || SQLERRM);
END fn_equipment_total_revenue;
/

-- Example usage:
-- SELECT equipment_name, fn_equipment_total_revenue(equipment_id) AS revenue FROM EQUIPMENT;

--------------------------------------------------------------------------------
-- 4. fn_available_equipment_count
-- Business purpose: how many units of a given equipment category are
-- currently free to rent -- the "current stock quantity" equivalent for a
-- rental business rather than a retail one.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_available_equipment_count (
    p_category_id IN NUMBER
) RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM EQUIPMENT
    WHERE category_id = p_category_id
      AND status = 'AVAILABLE';

    RETURN v_count;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_available_equipment_count failed: ' || SQLERRM);
END fn_available_equipment_count;
/

-- Example usage:
-- SELECT category_name, fn_available_equipment_count(category_id) AS available_units
-- FROM EQUIPMENT_CATEGORY;

--------------------------------------------------------------------------------
-- 5. fn_equipment_age_days
-- Business purpose: how long ago a machine was acquired -- used to flag
-- aging assets that may need closer maintenance attention.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_equipment_age_days (
    p_equipment_id IN NUMBER
) RETURN NUMBER
IS
    v_acquisition_date DATE;
BEGIN
    SELECT acquisition_date
    INTO v_acquisition_date
    FROM EQUIPMENT
    WHERE equipment_id = p_equipment_id;

    RETURN ROUND(SYSDATE - v_acquisition_date);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021, 'Equipment ID ' || p_equipment_id || ' does not exist.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_equipment_age_days failed: ' || SQLERRM);
END fn_equipment_age_days;
/

-- Example usage:
-- SELECT equipment_name, fn_equipment_age_days(equipment_id) AS age_in_days FROM EQUIPMENT;

--------------------------------------------------------------------------------
-- 6. fn_equipment_total_rental_days
-- Business purpose: total number of days an equipment item has actually
-- been out on rent (CONFIRMED/COMPLETED bookings only) -- a usage/wear
-- metric, the closest equivalent to cumulative consumption.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_equipment_total_rental_days (
    p_equipment_id IN NUMBER
) RETURN NUMBER
IS
    v_total_days NUMBER;
BEGIN
    SELECT NVL(SUM(end_date - start_date + 1), 0)
    INTO v_total_days
    FROM BOOKING
    WHERE equipment_id = p_equipment_id
      AND status IN ('CONFIRMED', 'COMPLETED');

    RETURN v_total_days;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_equipment_total_rental_days failed: ' || SQLERRM);
END fn_equipment_total_rental_days;
/

-- Example usage:
-- SELECT equipment_name, fn_equipment_total_rental_days(equipment_id) AS days_used FROM EQUIPMENT;

--------------------------------------------------------------------------------
-- 7. fn_days_until_harvest
-- Business purpose: a direct, no-substitution function -- CROP.harvest_date
-- already exists in our schema, so this tells a farmer exactly how many
-- days remain before their crop is due.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_days_until_harvest (
    p_crop_id IN NUMBER
) RETURN NUMBER
IS
    v_harvest_date DATE;
BEGIN
    SELECT harvest_date
    INTO v_harvest_date
    FROM CROP
    WHERE crop_id = p_crop_id;

    IF v_harvest_date IS NULL THEN
        -- Still growing with no confirmed harvest date yet
        RETURN NULL;
    END IF;

    RETURN ROUND(v_harvest_date - SYSDATE);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20022, 'Crop ID ' || p_crop_id || ' does not exist.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_days_until_harvest failed: ' || SQLERRM);
END fn_days_until_harvest;
/

-- Example usage:
-- SELECT crop_name, fn_days_until_harvest(crop_id) AS days_remaining FROM CROP;

--------------------------------------------------------------------------------
-- 8. fn_is_crop_ready_for_harvest
-- Business purpose: a direct Yes/No flag a farmer can check at a glance,
-- based on the real harvest_date already stored for each crop.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_is_crop_ready_for_harvest (
    p_crop_id IN NUMBER
) RETURN VARCHAR2
IS
    v_harvest_date DATE;
BEGIN
    SELECT harvest_date
    INTO v_harvest_date
    FROM CROP
    WHERE crop_id = p_crop_id;

    IF v_harvest_date IS NULL THEN
        RETURN 'NO';
    ELSIF v_harvest_date <= SYSDATE THEN
        RETURN 'YES';
    ELSE
        RETURN 'NO';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20023, 'Crop ID ' || p_crop_id || ' does not exist.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_is_crop_ready_for_harvest failed: ' || SQLERRM);
END fn_is_crop_ready_for_harvest;
/

-- Example usage:
-- SELECT crop_name, fn_is_crop_ready_for_harvest(crop_id) AS ready_flag FROM CROP;

--------------------------------------------------------------------------------
-- 9. fn_total_maintenance_cost
-- Business purpose: a direct rollup, function form of the logic already
-- used in sp_calculate_maintenance_cost (Phase VIII) -- provided as a
-- function here so it can be used directly inside a SELECT statement or a
-- view, which a procedure cannot do.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_total_maintenance_cost (
    p_equipment_id IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(cost), 0)
    INTO v_total
    FROM MAINTENANCE_RECORD
    WHERE equipment_id = p_equipment_id;

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_total_maintenance_cost failed: ' || SQLERRM);
END fn_total_maintenance_cost;
/

-- Example usage:
-- SELECT equipment_name, fn_total_maintenance_cost(equipment_id) AS lifetime_cost FROM EQUIPMENT;

--------------------------------------------------------------------------------
-- 10. fn_owner_equipment_value
-- Business purpose: total daily-rate value of an owner's active (non-
-- retired) equipment portfolio -- the closest real equivalent to
-- "inventory value" for a rental business, where value is expressed as
-- daily earning potential rather than a stocked product price.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_owner_equipment_value (
    p_owner_id IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(daily_rate), 0)
    INTO v_total
    FROM EQUIPMENT
    WHERE owner_id = p_owner_id
      AND status <> 'RETIRED';

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'fn_owner_equipment_value failed: ' || SQLERRM);
END fn_owner_equipment_value;
/

-- Example usage:
-- SELECT owner_name, fn_owner_equipment_value(owner_id) AS active_fleet_daily_value
-- FROM EQUIPMENT_OWNER;

--------------------------------------------------------------------------------
-- End of Phase IX: PL/SQL Functions
--------------------------------------------------------------------------------
