# Smart Agricultural Resource and Farm Operations Management System (SARFOMS)

**Course:** DPR400210 – Database Programming (Final Examination / Capstone Project)
**Faculty of Computing and Information Sciences | Academic Year 2025–2026**
**Student:** Ruben King
**Student ID:** 29761/2025
**Oracle Username:** `29761_2025` | **Schema/Project Name:** `29761_2025_RubenKing_DB`

---

## 1. Problem Statement

Smallholder and cooperative farmers often cannot justify owning expensive equipment (tractors, irrigation pumps, drone sprayers) that would sit idle most of the year, while equipment owners have machines sitting unused between jobs. SARFOMS matches equipment supply to farmer demand through a rental booking system, while simultaneously monitoring the crops that equipment services through IoT-style sensor data (soil moisture, temperature, humidity).

**Target users:** farmers/cooperative members, equipment owners/dealers, maintenance technicians, and a system administrator.

**Core objectives:** conflict-free equipment booking, preventive maintenance tracking, crop/soil sensor monitoring, mandatory audit and data-integrity controls, and management reporting via Oracle APEX.

---

## 2. Repository Structure

```
SARFOMS/
├── README.md                                          <- this file
├── sql/
│   ├── 01_29761_2025_RubenKing_SARFOMS_CreateTables.sql
│   ├── 02_29761_2025_RubenKing_SARFOMS_InsertData.sql
│   ├── 03_29761_2025_RubenKing_SARFOMS_Sequences.sql
│   ├── 04_29761_2025_RubenKing_SARFOMS_Views.sql
│   ├── 05_29761_2025_RubenKing_SARFOMS_Procedures.sql
│   ├── 06_29761_2025_RubenKing_SARFOMS_Functions.sql
│   ├── 07_29761_2025_RubenKing_SARFOMS_Triggers.sql
│   ├── 08_29761_2025_RubenKing_SARFOMS_Packages.sql
│   ├── 09_29761_2025_RubenKing_SARFOMS_Cursors.sql
│   ├── 10_29761_2025_RubenKing_SARFOMS_Auditing.sql
│   ├── 11_29761_2025_RubenKing_SARFOMS_AdvancedQueries.sql
│   ├── 12_29761_2025_RubenKing_SARFOMS_ManagementReports.sql
│   └── 13_29761_2025_RubenKing_SARFOMS_Testing.sql
├── docs/
│   ├── 29761_2025_RubenKing_SARFOMS_APEX_Design.docx
│   ├── 29761_2025_RubenKing_SARFOMS_Testing_Plan.docx
│   └── 29761_2025_RubenKing_SARFOMS_FinalReport.docx
└── screenshots/
    └── (add your own Oracle APEX and SQL Developer screenshots here before submission — see Section 5)
```

> The numeric prefixes in `sql/` are not part of the actual filenames delivered — rename on copy-in, or keep the original names and rely on this README's run order instead. Either is fine; what matters is running them in order.

---

## 3. Setup Instructions

1. **Create the Oracle user/schema** (run once, connected as `SYSTEM` or `SYS`):
   ```sql
   CREATE USER "29761_2025" IDENTIFIED BY YourPassword123;
   GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE, CREATE TRIGGER TO "29761_2025";
   ALTER USER "29761_2025" QUOTA UNLIMITED ON USERS;
   ```
2. **Reconnect** to Oracle SQL Developer as `29761_2025`.
3. **Run each script in this exact order** (each depends on objects created by the previous one):

   | Order | Script | Creates |
   |---|---|---|
   | 1 | `CreateTables.sql` | 13 core tables, constraints |
   | 2 | `InsertData.sql` | Sample data (farmers, farms, crops, equipment, bookings, etc.) |
   | 3 | `Sequences.sql` | Surrogate-key sequences for all 13 tables |
   | 4 | `Views.sql` | 10 reporting/operational views |
   | 5 | `Procedures.sql` | 10 stored procedures |
   | 6 | `Functions.sql` | 10 PL/SQL functions |
   | 7 | `Triggers.sql` | 10 triggers, including the mandatory weekday/holiday lock |
   | 8 | `Packages.sql` | 3 packages (Crop Management, Farm Operations, Reports) |
   | 9 | `Cursors.sql` | 10 cursor demonstrations (run blocks individually) |
   | 10 | `Auditing.sql` | 4 additional audit triggers + demonstration |
   | 11 | `AdvancedQueries.sql` | 20 advanced SQL query demonstrations |
   | 12 | `ManagementReports.sql` | 10 management reports |
   | 13 | `Testing.sql` | Automated PASS/FAIL/SKIP test suite |

4. **Enable output** before running any block: `SET SERVEROUTPUT ON` (already included at the top of every script that needs it).
5. **Important:** the `BOOKING` table has a mandatory business rule (Phase X) blocking all INSERT/UPDATE/DELETE on weekdays and Rwandan public holidays. If you are testing on a weekday, this is expected behavior, not a bug — see `Testing.sql` (test T08) and the Testing Plan document for how this is verified adaptively.

---

## 4. Feature Summary

- **13-table normalized (3NF) schema** covering farmers, farms, crops, equipment, bookings, payments, maintenance, sensor readings, and audit infrastructure.
- **10 views, 10 procedures, 10 functions, 10 triggers, 3 packages, 10 cursor demonstrations** — all cross-referenced rather than duplicated (e.g., packages call the same logic as standalone functions where appropriate, documented explicitly rather than silently).
- **Full auditing system** on 5 tables (BOOKING, PAYMENT, EQUIPMENT, MAINTENANCE_RECORD, FARMER) with a deliberate security decision not to log sensitive identifiers (national ID) even during audit capture.
- **20 advanced SQL query demonstrations** (all major join types, subqueries, CTEs, window functions, set operators) plus **10 management reports**.
- **Oracle APEX application design** (Phase XVI) covering authentication, role-based authorization (Administrator / Farm Manager / Staff), dashboard, 10 forms, 6 reports, and full page-by-page documentation.
- **Automated test suite** (22 tests) plus a manual APEX UI test plan (10 test cases), with adaptive handling of the weekday/holiday business rule so tests behave correctly regardless of what day they're run.

---

## 5. Screenshots (to be added before submission)

This repository currently contains the *designed* Oracle APEX application (Phase XVI documentation) rather than a deployed one. Before final submission, add screenshots to `screenshots/` covering:

- [ ] Login page
- [ ] Home Dashboard (KPI cards + charts)
- [ ] At least one Form page (e.g., Activities/Bookings) showing a validation error being triggered
- [ ] At least one Interactive Report page
- [ ] SQL Developer output showing `Testing.sql` PASS/FAIL/SKIP summary
- [ ] ERD diagram

---

## 6. Academic Integrity

This is individual work submitted for DPR400210. AI tools were used for learning and support during development, consistent with the course's stated policy — all code has been reviewed and is understood well enough to explain and defend live during the final demonstration and viva.

---

## 7. Contact

**Ruben King** | Student ID: 29761/2025
