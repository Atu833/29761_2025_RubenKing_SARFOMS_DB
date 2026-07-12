--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase VII: Views
--------------------------------------------------------------------------------
-- Run this AFTER the CreateTables and InsertData scripts.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. VW_EQUIPMENT_DETAILS
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_EQUIPMENT_DETAILS AS
SELECT
    e.equipment_id,
    e.equipment_name,
    e.model,
    c.category_name,
    o.owner_name,
    o.business_type,
    e.daily_rate,
    e.status,
    e.acquisition_date
FROM EQUIPMENT e
JOIN EQUIPMENT_CATEGORY c ON e.category_id = c.category_id
JOIN EQUIPMENT_OWNER o    ON e.owner_id    = o.owner_id;

--------------------------------------------------------------------------------
-- 2. VW_FARMER_BOOKING_ASSIGNMENT
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_FARMER_BOOKING_ASSIGNMENT AS
SELECT
    b.booking_id,
    f.farmer_id,
    f.first_name || ' ' || f.last_name AS farmer_name,
    f.phone,
    e.equipment_id,
    e.equipment_name,
    b.start_date,
    b.end_date,
    b.status AS booking_status
FROM BOOKING b
JOIN FARMER f    ON b.farmer_id    = f.farmer_id
JOIN EQUIPMENT e ON b.equipment_id = e.equipment_id;

--------------------------------------------------------------------------------
-- 3. VW_SENSOR_READING_SUMMARY
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_SENSOR_READING_SUMMARY AS
SELECT
    s.farm_id,
    f.location,
    s.crop_id,
    c.crop_name,
    ROUND(AVG(s.soil_moisture), 2) AS avg_soil_moisture,
    ROUND(MIN(s.soil_moisture), 2) AS min_soil_moisture,
    ROUND(MAX(s.soil_moisture), 2) AS max_soil_moisture,
    ROUND(AVG(s.temperature), 2)   AS avg_temperature,
    ROUND(AVG(s.humidity), 2)      AS avg_humidity,
    COUNT(*)                       AS reading_count
FROM SENSOR_READING s
JOIN FARM f      ON s.farm_id = f.farm_id
LEFT JOIN CROP c ON s.crop_id = c.crop_id
GROUP BY s.farm_id, f.location, s.crop_id, c.crop_name;

--------------------------------------------------------------------------------
-- 4. VW_MAINTENANCE_HISTORY
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_MAINTENANCE_HISTORY AS
SELECT
    m.maintenance_id,
    e.equipment_name,
    t.full_name AS technician_name,
    m.service_date,
    m.description,
    m.cost
FROM MAINTENANCE_RECORD m
JOIN EQUIPMENT e  ON m.equipment_id  = e.equipment_id
JOIN TECHNICIAN t ON m.technician_id = t.technician_id;

--------------------------------------------------------------------------------
-- 5. VW_SERVICE_DUE_REMINDER
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_SERVICE_DUE_REMINDER AS
SELECT
    e.equipment_id,
    e.equipment_name,
    e.status,
    m.last_service_date,
    ROUND(SYSDATE - m.last_service_date) AS days_since_last_service
FROM EQUIPMENT e
LEFT JOIN (
    SELECT equipment_id, MAX(service_date) AS last_service_date
    FROM MAINTENANCE_RECORD
    GROUP BY equipment_id
) m ON e.equipment_id = m.equipment_id
WHERE e.status <> 'RETIRED'
  AND (m.last_service_date IS NULL OR m.last_service_date < SYSDATE - 180);

--------------------------------------------------------------------------------
-- 6. VW_BOOKING_RENTAL_SUMMARY
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_BOOKING_RENTAL_SUMMARY AS
SELECT
    e.equipment_id,
    e.equipment_name,
    COUNT(b.booking_id) AS total_bookings,
    NVL(SUM(CASE WHEN b.status IN ('CONFIRMED','COMPLETED')
                  THEN (b.end_date - b.start_date + 1) ELSE 0 END), 0) AS total_rental_days,
    NVL(SUM(CASE WHEN p.status = 'PAID' THEN p.amount ELSE 0 END), 0) AS total_revenue
FROM EQUIPMENT e
LEFT JOIN BOOKING b ON e.equipment_id = b.equipment_id
LEFT JOIN PAYMENT p ON b.booking_id   = p.booking_id
GROUP BY e.equipment_id, e.equipment_name;

--------------------------------------------------------------------------------
-- 7. VW_MAINTENANCE_COST_ANALYSIS
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_MAINTENANCE_COST_ANALYSIS AS
SELECT
    c.category_name,
    COUNT(m.maintenance_id)      AS service_count,
    NVL(SUM(m.cost), 0)          AS total_cost,
    ROUND(AVG(m.cost), 2)        AS avg_cost_per_service
FROM EQUIPMENT_CATEGORY c
JOIN EQUIPMENT e            ON c.category_id  = e.category_id
LEFT JOIN MAINTENANCE_RECORD m ON e.equipment_id = m.equipment_id
GROUP BY c.category_name;

--------------------------------------------------------------------------------
-- 8. VW_EQUIPMENT_UTILIZATION_REPORT
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_EQUIPMENT_UTILIZATION_REPORT AS
SELECT
    e.equipment_id,
    e.equipment_name,
    NVL(SUM(CASE WHEN b.status IN ('CONFIRMED','COMPLETED')
                  THEN (b.end_date - b.start_date + 1) ELSE 0 END), 0) AS total_days_rented,
    ROUND(SYSDATE - e.acquisition_date) AS days_owned,
    ROUND(
        NVL(SUM(CASE WHEN b.status IN ('CONFIRMED','COMPLETED')
                      THEN (b.end_date - b.start_date + 1) ELSE 0 END), 0)
        / NULLIF(ROUND(SYSDATE - e.acquisition_date), 0) * 100, 2
    ) AS utilization_pct
FROM EQUIPMENT e
LEFT JOIN BOOKING b ON e.equipment_id = b.equipment_id
GROUP BY e.equipment_id, e.equipment_name, e.acquisition_date;

--------------------------------------------------------------------------------
-- 9. VW_INACTIVE_EQUIPMENT
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_INACTIVE_EQUIPMENT AS
SELECT
    e.equipment_id,
    e.equipment_name,
    e.status,
    o.owner_name,
    e.acquisition_date,
    ROUND(SYSDATE - e.acquisition_date) AS days_since_acquisition
FROM EQUIPMENT e
JOIN EQUIPMENT_OWNER o ON e.owner_id = o.owner_id
WHERE e.status IN ('RETIRED','MAINTENANCE');

--------------------------------------------------------------------------------
-- 10. VW_FARM_DASHBOARD_SUMMARY
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_FARM_DASHBOARD_SUMMARY AS
SELECT
    (SELECT COUNT(*) FROM FARMER)                                   AS total_farmers,
    (SELECT COUNT(*) FROM FARM)                                     AS total_farms,
    (SELECT COUNT(*) FROM EQUIPMENT)                                AS total_equipment,
    (SELECT COUNT(*) FROM EQUIPMENT WHERE status = 'RENTED')        AS equipment_currently_rented,
    (SELECT COUNT(*) FROM EQUIPMENT WHERE status = 'MAINTENANCE')   AS equipment_in_maintenance,
    (SELECT COUNT(*) FROM EQUIPMENT WHERE status = 'RETIRED')       AS equipment_retired,
    (SELECT COUNT(*) FROM BOOKING WHERE status IN ('CONFIRMED','PENDING')) AS active_bookings,
    (SELECT NVL(SUM(amount),0) FROM PAYMENT WHERE status = 'PAID')  AS total_revenue_collected,
    (SELECT NVL(SUM(amount),0) FROM PAYMENT WHERE status = 'UNPAID') AS total_outstanding_payments
FROM DUAL;

--------------------------------------------------------------------------------
-- End of Phase VII: Views
--------------------------------------------------------------------------------
