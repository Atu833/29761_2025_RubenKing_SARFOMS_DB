--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase XV, Part B: Management Reports (10 reports)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- REPORT 1: Crop Production Report
-- Every crop with its farm location, planting/harvest dates, and current
-- growth duration -- the base operational report for field oversight.
--------------------------------------------------------------------------------
SELECT c.crop_name, f.location, c.season, c.planting_date, c.harvest_date,
       ROUND(NVL(c.harvest_date, SYSDATE) - c.planting_date) AS days_in_ground
FROM CROP c
JOIN FARM f ON c.farm_id = f.farm_id
ORDER BY f.location, c.planting_date;

--------------------------------------------------------------------------------
-- REPORT 2: Harvest Summary
-- Crops actually harvested, grouped by month, with average growing duration
-- -- useful for spotting seasonal harvest peaks that need equipment surge
-- capacity (more harvesters booked in a given month).
--------------------------------------------------------------------------------
SELECT TO_CHAR(harvest_date, 'YYYY-MM') AS harvest_month,
       COUNT(*) AS crops_harvested,
       ROUND(AVG(harvest_date - planting_date), 1) AS avg_growing_days
FROM CROP
WHERE harvest_date IS NOT NULL
GROUP BY TO_CHAR(harvest_date, 'YYYY-MM')
ORDER BY harvest_month;

--------------------------------------------------------------------------------
-- REPORT 3: Technician (Worker) Performance Report
-- Jobs completed and total cost of work handled per technician -- the
-- staffing-level equivalent of "who is doing the most (and most expensive)
-- work."
--------------------------------------------------------------------------------
SELECT t.full_name, t.specialty,
       COUNT(m.maintenance_id) AS jobs_handled,
       NVL(SUM(m.cost), 0)     AS total_cost_handled,
       ROUND(AVG(m.cost), 2)   AS avg_cost_per_job
FROM TECHNICIAN t
LEFT JOIN MAINTENANCE_RECORD m ON t.technician_id = m.technician_id
GROUP BY t.full_name, t.specialty
ORDER BY jobs_handled DESC;

--------------------------------------------------------------------------------
-- REPORT 4: Equipment Utilization Report
-- Rental days vs. days owned, expressed as a percentage -- reusing the
-- logic behind VW_EQUIPMENT_UTILIZATION_REPORT (Phase VII) directly in
-- report form so it can be filtered/sorted independently of the view.
--------------------------------------------------------------------------------
SELECT e.equipment_name,
       NVL(SUM(CASE WHEN b.status IN ('CONFIRMED','COMPLETED')
                     THEN b.end_date - b.start_date + 1 ELSE 0 END), 0) AS days_rented,
       ROUND(SYSDATE - e.acquisition_date) AS days_owned,
       ROUND(NVL(SUM(CASE WHEN b.status IN ('CONFIRMED','COMPLETED')
                     THEN b.end_date - b.start_date + 1 ELSE 0 END), 0)
             / NULLIF(ROUND(SYSDATE - e.acquisition_date), 0) * 100, 2) AS utilization_pct
FROM EQUIPMENT e
LEFT JOIN BOOKING b ON e.equipment_id = b.equipment_id
GROUP BY e.equipment_name, e.acquisition_date
ORDER BY utilization_pct DESC NULLS LAST;

--------------------------------------------------------------------------------
-- REPORT 5: Farm Activity Report
-- All booking activity grouped by farmer, showing how actively each
-- customer is using the rental service.
--------------------------------------------------------------------------------
SELECT f.first_name || ' ' || f.last_name AS farmer_name,
       COUNT(b.booking_id) AS total_activities,
       SUM(CASE WHEN b.status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed,
       SUM(CASE WHEN b.status IN ('PENDING','CONFIRMED') THEN 1 ELSE 0 END) AS in_progress,
       SUM(CASE WHEN b.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled
FROM FARMER f
LEFT JOIN BOOKING b ON f.farmer_id = b.farmer_id
GROUP BY f.first_name, f.last_name
ORDER BY total_activities DESC;

--------------------------------------------------------------------------------
-- REPORT 6: Revenue Report (monthly trend)
-- Paid revenue grouped by month -- the core financial trend line for
-- management review.
--------------------------------------------------------------------------------
SELECT TO_CHAR(payment_date, 'YYYY-MM') AS revenue_month,
       COUNT(*) AS payments_count,
       SUM(amount) AS total_revenue
FROM PAYMENT
WHERE status = 'PAID'
GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
ORDER BY revenue_month;

--------------------------------------------------------------------------------
-- REPORT 7: Resource Allocation Report
-- Equipment distribution across categories and owners -- shows where the
-- rental fleet's capital is concentrated.
--------------------------------------------------------------------------------
SELECT o.owner_name, c.category_name, COUNT(*) AS unit_count,
       SUM(e.daily_rate) AS combined_daily_value
FROM EQUIPMENT e
JOIN EQUIPMENT_OWNER o    ON e.owner_id    = o.owner_id
JOIN EQUIPMENT_CATEGORY c ON e.category_id = c.category_id
GROUP BY o.owner_name, c.category_name
ORDER BY o.owner_name, c.category_name;

--------------------------------------------------------------------------------
-- REPORT 8: Seasonal Production Report
-- Crop counts and average growing duration by Rwandan agricultural season
-- (A, B, C) -- supports planning which equipment to stock ahead of each
-- season's peak.
--------------------------------------------------------------------------------
SELECT season,
       COUNT(*) AS crop_count,
       ROUND(AVG(NVL(harvest_date, SYSDATE) - planting_date), 1) AS avg_days_in_ground
FROM CROP
GROUP BY season
ORDER BY season;

--------------------------------------------------------------------------------
-- REPORT 9: Maintenance Report
-- Full maintenance activity rolled up by equipment, including how many
-- days ago the last service happened -- the direct operational companion
-- to VW_SERVICE_DUE_REMINDER (Phase VII).
--------------------------------------------------------------------------------
SELECT e.equipment_name, COUNT(m.maintenance_id) AS service_count,
       NVL(SUM(m.cost), 0) AS total_maintenance_cost,
       MAX(m.service_date) AS last_service_date,
       ROUND(SYSDATE - MAX(m.service_date)) AS days_since_last_service
FROM EQUIPMENT e
LEFT JOIN MAINTENANCE_RECORD m ON e.equipment_id = m.equipment_id
GROUP BY e.equipment_name
ORDER BY days_since_last_service DESC NULLS FIRST;

--------------------------------------------------------------------------------
-- REPORT 10: Executive Dashboard Summary
-- One-row KPI snapshot for leadership -- extends VW_FARM_DASHBOARD_SUMMARY
-- (Phase VII) with two additional derived metrics not in the base view.
--------------------------------------------------------------------------------
SELECT d.*,
       (SELECT COUNT(*) FROM CROP WHERE harvest_date IS NOT NULL AND harvest_date <= SYSDATE) AS crops_ready_now,
       (SELECT ROUND(AVG(soil_moisture), 2) FROM SENSOR_READING) AS system_avg_soil_moisture
FROM VW_FARM_DASHBOARD_SUMMARY d;

--------------------------------------------------------------------------------
-- End of Phase XV, Part B: Management Reports
--------------------------------------------------------------------------------
