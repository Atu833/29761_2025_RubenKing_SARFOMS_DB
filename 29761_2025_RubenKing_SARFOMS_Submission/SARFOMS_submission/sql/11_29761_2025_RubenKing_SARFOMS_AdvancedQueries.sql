--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025 | Oracle Username: 29761_2025
-- Phase XV, Part A: Advanced SQL Queries (20 concepts)
--------------------------------------------------------------------------------
-- Run this AFTER all previous phase scripts. These are read-only SELECT
-- statements demonstrating Oracle SQL concepts -- nothing here modifies data.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. INNER JOIN
-- Purpose: shows only bookings that have a matching farmer AND equipment
-- (guaranteed by FK, so this returns every booking with full context).
-- Decision support: the day-to-day operational view of who has what.
--------------------------------------------------------------------------------
SELECT b.booking_id, f.first_name || ' ' || f.last_name AS farmer_name,
       e.equipment_name, b.start_date, b.end_date, b.status
FROM BOOKING b
JOIN FARMER f    ON b.farmer_id    = f.farmer_id
JOIN EQUIPMENT e ON b.equipment_id = e.equipment_id
ORDER BY b.start_date;

--------------------------------------------------------------------------------
-- 2. LEFT OUTER JOIN
-- Purpose: shows every equipment item, including ones that have NEVER been
-- booked (booking columns will be NULL for those rows).
-- Decision support: instantly spot dead inventory that has generated zero
-- bookings -- something INNER JOIN alone would hide.
--------------------------------------------------------------------------------
SELECT e.equipment_id, e.equipment_name, b.booking_id, b.status AS booking_status
FROM EQUIPMENT e
LEFT JOIN BOOKING b ON e.equipment_id = b.equipment_id
ORDER BY e.equipment_id;

--------------------------------------------------------------------------------
-- 3. RIGHT OUTER JOIN
-- Purpose: shows every technician, including any with zero assigned jobs
-- (written as RIGHT JOIN so TECHNICIAN is guaranteed fully represented).
-- Decision support: identify underutilized technicians for reassignment.
--------------------------------------------------------------------------------
SELECT t.technician_id, t.full_name, m.maintenance_id, m.service_date
FROM MAINTENANCE_RECORD m
RIGHT JOIN TECHNICIAN t ON m.technician_id = t.technician_id
ORDER BY t.technician_id;

--------------------------------------------------------------------------------
-- 4. FULL OUTER JOIN
-- Purpose: matches BOOKING and PAYMENT on booking_id, keeping unmatched rows
-- from BOTH sides. In our current sample data every booking has exactly one
-- payment (enforced by Phase X trigger + 1:1 constraint), so this currently
-- returns identical rows to an INNER JOIN -- but the syntax matters because
-- a future booking created without an attached payment yet (a real
-- operational state) WOULD show up here with NULL payment columns, which
-- neither INNER nor a one-sided OUTER JOIN would both catch correctly.
--------------------------------------------------------------------------------
SELECT b.booking_id, b.status AS booking_status, p.payment_id, p.status AS payment_status
FROM BOOKING b
FULL OUTER JOIN PAYMENT p ON b.booking_id = p.booking_id
ORDER BY b.booking_id;

--------------------------------------------------------------------------------
-- 5. GROUP BY
-- Purpose: total bookings per equipment category.
-- Decision support: which category of machine is most in demand.
--------------------------------------------------------------------------------
SELECT c.category_name, COUNT(b.booking_id) AS total_bookings
FROM EQUIPMENT_CATEGORY c
JOIN EQUIPMENT e    ON c.category_id  = e.category_id
LEFT JOIN BOOKING b ON e.equipment_id = b.equipment_id
GROUP BY c.category_name
ORDER BY total_bookings DESC;

--------------------------------------------------------------------------------
-- 6. HAVING
-- Purpose: same grouping as above, filtered to categories with more than
-- 2 total bookings -- HAVING filters on the aggregate, WHERE could not.
-- Decision support: flags genuinely high-demand categories worth
-- purchasing more units of.
--------------------------------------------------------------------------------
SELECT c.category_name, COUNT(b.booking_id) AS total_bookings
FROM EQUIPMENT_CATEGORY c
JOIN EQUIPMENT e    ON c.category_id  = e.category_id
LEFT JOIN BOOKING b ON e.equipment_id = b.equipment_id
GROUP BY c.category_name
HAVING COUNT(b.booking_id) > 2
ORDER BY total_bookings DESC;

--------------------------------------------------------------------------------
-- 7. ORDER BY (with NULLS LAST)
-- Purpose: crops sorted by harvest date, with still-growing crops
-- (harvest_date IS NULL) pushed to the bottom rather than the top.
-- Decision support: an at-a-glance harvest calendar.
--------------------------------------------------------------------------------
SELECT crop_name, planting_date, harvest_date
FROM CROP
ORDER BY harvest_date NULLS LAST;

--------------------------------------------------------------------------------
-- 8. Aggregate functions (SUM, AVG, COUNT, MIN, MAX)
-- Purpose: full maintenance cost profile per equipment category.
-- Decision support: which category is most expensive to maintain overall
-- vs. per incident.
--------------------------------------------------------------------------------
SELECT c.category_name,
       COUNT(m.maintenance_id) AS service_count,
       SUM(m.cost)             AS total_cost,
       ROUND(AVG(m.cost), 2)   AS avg_cost,
       MIN(m.cost)             AS min_cost,
       MAX(m.cost)             AS max_cost
FROM EQUIPMENT_CATEGORY c
JOIN EQUIPMENT e                 ON c.category_id  = e.category_id
LEFT JOIN MAINTENANCE_RECORD m   ON e.equipment_id = m.equipment_id
GROUP BY c.category_name
ORDER BY total_cost DESC NULLS LAST;

--------------------------------------------------------------------------------
-- 9. Scalar functions
-- Purpose: demonstrates UPPER, SUBSTR, and LENGTH used together to format
-- farmer data and partially mask a sensitive identifier.
-- Decision support: shows how a report layer can present clean, safe
-- values without altering the stored data.
--------------------------------------------------------------------------------
SELECT UPPER(first_name) || ' ' || UPPER(last_name) AS farmer_name_upper,
       LENGTH(phone) AS phone_length,
       SUBSTR(national_id, 1, 4) || '*********' AS masked_national_id
FROM FARMER;

--------------------------------------------------------------------------------
-- 10. Date functions
-- Purpose: TO_CHAR for readable month names, MONTHS_BETWEEN for growing
-- duration, and ADD_MONTHS to project a future milestone date.
-- Decision support: growing-duration analytics feed directly into
-- planning next season's equipment bookings.
--------------------------------------------------------------------------------
SELECT crop_name,
       TO_CHAR(planting_date, 'Month YYYY') AS planting_month,
       ROUND(MONTHS_BETWEEN(NVL(harvest_date, SYSDATE), planting_date), 1) AS months_growing,
       ADD_MONTHS(planting_date, 6) AS six_month_checkpoint
FROM CROP
ORDER BY planting_date;

--------------------------------------------------------------------------------
-- 11. Nested subquery
-- Purpose: equipment priced above the system-wide average daily rate.
-- Decision support: identifies premium-tier equipment for targeted
-- marketing or insurance review.
--------------------------------------------------------------------------------
SELECT equipment_name, daily_rate
FROM EQUIPMENT
WHERE daily_rate > (SELECT AVG(daily_rate) FROM EQUIPMENT)
ORDER BY daily_rate DESC;

--------------------------------------------------------------------------------
-- 12. Correlated subquery
-- Purpose: farmers whose total PAID spend exceeds the average spend across
-- all farmers -- the inner query re-executes per outer row, correlated on
-- f.farmer_id, which is what makes this different from query 11.
-- Decision support: identifies high-value repeat customers.
--------------------------------------------------------------------------------
SELECT f.farmer_id, f.first_name, f.last_name
FROM FARMER f
WHERE (SELECT NVL(SUM(p.amount), 0)
       FROM PAYMENT p JOIN BOOKING b ON p.booking_id = b.booking_id
       WHERE b.farmer_id = f.farmer_id AND p.status = 'PAID')
      >
      (SELECT AVG(farmer_total) FROM (
            SELECT b2.farmer_id, NVL(SUM(p2.amount), 0) AS farmer_total
            FROM BOOKING b2
            LEFT JOIN PAYMENT p2 ON b2.booking_id = p2.booking_id AND p2.status = 'PAID'
            GROUP BY b2.farmer_id
      ));

--------------------------------------------------------------------------------
-- 13. EXISTS
-- Purpose: equipment that has never once been booked.
-- Decision support: same business question as query 2, answered with a
-- different (often more efficient) technique -- worth comparing execution
-- plans in your report to show you understand both approaches.
--------------------------------------------------------------------------------
SELECT equipment_id, equipment_name
FROM EQUIPMENT e
WHERE NOT EXISTS (SELECT 1 FROM BOOKING b WHERE b.equipment_id = e.equipment_id);

--------------------------------------------------------------------------------
-- 14. IN
-- Purpose: farmers who have ever booked a Drone Sprayer (category_id = 3).
-- Decision support: a targeted marketing list -- "who already uses drones,
-- who might upgrade to a newer model."
--------------------------------------------------------------------------------
SELECT DISTINCT f.first_name, f.last_name
FROM FARMER f
WHERE f.farmer_id IN (
    SELECT b.farmer_id FROM BOOKING b
    JOIN EQUIPMENT e ON b.equipment_id = e.equipment_id
    WHERE e.category_id = 3
);

--------------------------------------------------------------------------------
-- 15. ANY / ALL
-- Purpose: (a) equipment cheaper than at least one Drone Sprayer (ANY);
-- (b) equipment more expensive than every Plough (ALL).
-- Decision support: relative pricing checks against a reference category.
--------------------------------------------------------------------------------
SELECT equipment_name, daily_rate
FROM EQUIPMENT
WHERE daily_rate < ANY (SELECT daily_rate FROM EQUIPMENT WHERE category_id = 3)
ORDER BY daily_rate;

SELECT equipment_name, daily_rate
FROM EQUIPMENT
WHERE daily_rate > ALL (SELECT daily_rate FROM EQUIPMENT WHERE category_id = 6)
ORDER BY daily_rate;

--------------------------------------------------------------------------------
-- 16. CASE expression
-- Purpose: translates the raw status code into a farmer-friendly
-- description without altering the stored value.
-- Decision support: this is exactly the transformation an APEX report
-- column would use for readability.
--------------------------------------------------------------------------------
SELECT equipment_name, status,
       CASE status
           WHEN 'AVAILABLE'   THEN 'Ready to rent'
           WHEN 'RENTED'      THEN 'Currently out on rental'
           WHEN 'MAINTENANCE' THEN 'Under repair'
           WHEN 'RETIRED'     THEN 'Retired - no longer in service'
           ELSE 'Unknown status'
       END AS status_description
FROM EQUIPMENT;

--------------------------------------------------------------------------------
-- 17. Common Table Expression (CTE / WITH clause)
-- Purpose: computes total PAID revenue per equipment owner, then filters
-- to owners above a revenue threshold -- the CTE makes the aggregation
-- readable as a named, reusable result set instead of a nested subquery.
-- Decision support: which owners are the business's top revenue partners.
--------------------------------------------------------------------------------
WITH owner_revenue AS (
    SELECT o.owner_id, o.owner_name, NVL(SUM(p.amount), 0) AS total_revenue
    FROM EQUIPMENT_OWNER o
    JOIN EQUIPMENT e ON o.owner_id    = e.owner_id
    JOIN BOOKING b   ON e.equipment_id = b.equipment_id
    JOIN PAYMENT p   ON b.booking_id  = p.booking_id AND p.status = 'PAID'
    GROUP BY o.owner_id, o.owner_name
)
SELECT * FROM owner_revenue
WHERE total_revenue > 100000
ORDER BY total_revenue DESC;

--------------------------------------------------------------------------------
-- 18. Analytic (Window) Functions
-- Purpose: ranks each equipment item's revenue within its own category
-- (RANK), and shows the category's total revenue alongside every row
-- (SUM ... OVER) -- something GROUP BY alone cannot do in a single query,
-- since GROUP BY would collapse the individual equipment rows.
-- Decision support: "which is the best-performing tractor, and how does
-- it compare to the category as a whole" in one result set.
--------------------------------------------------------------------------------
SELECT category_id, equipment_name, revenue,
       RANK()      OVER (PARTITION BY category_id ORDER BY revenue DESC) AS rank_in_category,
       SUM(revenue) OVER (PARTITION BY category_id)                     AS category_total_revenue
FROM (
    SELECT e.category_id, e.equipment_name, NVL(SUM(p.amount), 0) AS revenue
    FROM EQUIPMENT e
    LEFT JOIN BOOKING b ON e.equipment_id = b.equipment_id
    LEFT JOIN PAYMENT p ON b.booking_id   = p.booking_id AND p.status = 'PAID'
    GROUP BY e.category_id, e.equipment_name
)
ORDER BY category_id, rank_in_category;

--------------------------------------------------------------------------------
-- 19. Set operators (UNION, INTERSECT, MINUS)
-- Purpose: three distinct demonstrations.
-- Decision support: each answers a genuinely different business question.
--------------------------------------------------------------------------------

-- UNION: a combined contact roster of farmers and technicians (people the
-- business needs to be able to reach), removing duplicate names
SELECT first_name || ' ' || last_name AS person_name, 'FARMER' AS role FROM FARMER
UNION
SELECT full_name, 'TECHNICIAN' FROM TECHNICIAN
ORDER BY person_name;

-- INTERSECT: equipment categories that currently have units in BOTH an
-- AVAILABLE state and a RETIRED state (categories with a full asset
-- lifecycle already represented)
SELECT category_id FROM EQUIPMENT WHERE status = 'AVAILABLE'
INTERSECT
SELECT category_id FROM EQUIPMENT WHERE status = 'RETIRED';

-- MINUS: farmers who have made a booking but have NEVER completed a PAID
-- payment (an outstanding-collections list)
SELECT farmer_id FROM BOOKING
MINUS
SELECT b.farmer_id FROM BOOKING b JOIN PAYMENT p ON b.booking_id = p.booking_id WHERE p.status = 'PAID';

--------------------------------------------------------------------------------
-- 20. Complex management report combining multiple tables
-- Purpose: a full farmer profile in one row -- farm count, total bookings,
-- total amount actually paid, and average soil moisture across their land.
-- Decision support: this is the exact query an account manager would run
-- before a farmer renewal conversation.
--
-- TECHNIQUE NOTE: this deliberately uses independent scalar subqueries in
-- the SELECT list rather than joining FARM, BOOKING, and SENSOR_READING
-- all directly off FARMER in one FROM clause. Joining three "many" sides
-- to the same "one" side at once causes a fan-out: a farmer with 2 farms
-- and 3 bookings would produce 2x3=6 cross-product rows, and a naive
-- SUM(payment.amount) across that cross-product would count each payment
-- 6 times instead of once. Scalar subqueries each aggregate independently
-- before the outer query ever combines them, avoiding that multiplication
-- entirely -- an important distinction to be able to explain in the viva.
--------------------------------------------------------------------------------
SELECT f.farmer_id,
       f.first_name || ' ' || f.last_name AS farmer_name,
       (SELECT COUNT(*) FROM FARM fa WHERE fa.farmer_id = f.farmer_id) AS farm_count,
       (SELECT COUNT(*) FROM BOOKING b WHERE b.farmer_id = f.farmer_id) AS total_bookings,
       (SELECT NVL(SUM(p.amount), 0)
        FROM PAYMENT p JOIN BOOKING b2 ON p.booking_id = b2.booking_id
        WHERE b2.farmer_id = f.farmer_id AND p.status = 'PAID') AS total_paid,
       (SELECT ROUND(AVG(s.soil_moisture), 2)
        FROM SENSOR_READING s JOIN FARM fa2 ON s.farm_id = fa2.farm_id
        WHERE fa2.farmer_id = f.farmer_id) AS avg_soil_moisture
FROM FARMER f
ORDER BY total_paid DESC;

--------------------------------------------------------------------------------
-- End of Phase XV, Part A: Advanced SQL Queries
--------------------------------------------------------------------------------
