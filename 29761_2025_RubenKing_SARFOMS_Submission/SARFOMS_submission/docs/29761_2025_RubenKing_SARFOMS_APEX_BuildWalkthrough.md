# SARFOMS — Oracle APEX Build Walkthrough

**Student:** Ruben King | **Student ID:** 29761/2025
**Purpose:** A practical, click-by-click path through Oracle APEX App Builder to turn the Phase XVI design document into a real, running application. Follow this in order — each section assumes the previous one is done.

> This assumes your `29761_2025` schema (all 13 tables, views, procedures, functions, triggers, packages) is already created and populated. If not, run the SQL scripts first.

---

## 0. Prerequisites

1. Log into your Oracle APEX workspace (either apex.oracle.com or your institution's instance).
2. **App Builder → Create App → New Application.**
   - Name: `SARFOMS`
   - Appearance: Universal Theme (default) — Vita or Redwood Light both work fine
   - Leave "Add Page" list empty for now — you'll add pages deliberately below
3. Under **Shared Components → Database → Application Access → Parsing Schema**, confirm it points at `29761_2025`.
4. Under **Shared Components → Security → Security Attributes**, leave defaults — CSRF/session protection is on by default; don't disable it.

---

## 1. Authentication

**Shared Components → Security → Authentication Schemes → Create.**
- Scheme Type: **Application Express Accounts**
- Name: `SARFOMS Login`
- Make it current for the application

**Administration → Manage Users** (workspace level): create at least 3 test accounts, one per role you'll assign in Section 2:
- `admin_ruben` (Administrator)
- `manager_test` (Farm Manager)
- `staff_test` (Staff)

APEX's login page comes with this scheme automatically — no page-building needed. Customize the logo/branding later via **Shared Components → User Interface → Templates** if you want, but it's not required for functionality.

---

## 2. Authorization Schemes (the 3 roles)

**Shared Components → Security → Authorization Schemes → Create**, three times:

| Name | Scheme Type | Expression |
|---|---|---|
| `Is Administrator` | Exists SQL Query | `SELECT 1 FROM DUAL WHERE :APP_USER = 'ADMIN_RUBEN'` |
| `Is Farm Manager` | Exists SQL Query | `SELECT 1 FROM DUAL WHERE :APP_USER IN ('ADMIN_RUBEN','MANAGER_TEST')` |
| `Is Staff` | Exists SQL Query | `SELECT 1 FROM DUAL WHERE :APP_USER IN ('ADMIN_RUBEN','MANAGER_TEST','STAFF_TEST')` |

> This hardcoded-username approach is the fastest path for a capstone demo. If you want it data-driven instead, you'd need a role-mapping table — which is exactly the "future enhancement" flagged in the Phase XVI document as intentionally out of scope for now.

You'll attach these to pages in the sections below — **every page except Login gets at minimum `Is Staff`**; Administration pages get `Is Administrator`.

---

## 3. Navigation Menu

**App Builder → SARFOMS → Shared Components → Navigation → Navigation Menu → Create Entries** matching this structure (you'll link each to a page number as you create it below, so it's fine to build this list last and come back to fill in page numbers):

```
Home Dashboard          → Page 1
Crop Management
  ├─ Crops               → Page 10
  ├─ Fields               → Page 11
  └─ Harvests             → Page 12
Worker Management
  ├─ Workers              → Page 13
  └─ Worker Activities (report) → Page 20
Equipment Management
  ├─ Equipment            → Page 14
  ├─ Inventory/Availability → Page 15
  ├─ Suppliers            → Page 16
  └─ Equipment Maintenance (report) → Page 21
Activities
  ├─ Activities (Bookings) → Page 17
  ├─ Customers             → Page 18
  └─ Sales / Payments      → Page 19
Reports
  ├─ Crop Production       → Page 22
  ├─ Harvest Summary       → Page 23
  ├─ Farm Revenue          → Page 24
  └─ Farm Performance Dashboard → Page 25
Administration           (Authorization: Is Administrator)
  ├─ Users & Roles         → Page 30
  ├─ Public Holidays       → Page 31
  ├─ Audit Log             → Page 32
  └─ Equipment Categories  → Page 33
```

---

## 4. Home Dashboard (Page 1)

**App Builder → Create Page → Dashboard** (or Blank Page if your APEX version doesn't offer the Dashboard page type — Blank Page + manual regions works identically).

Add these regions:

1. **4 KPI Card regions** (Create Page → Reports → KPI, or Region type "Value" on a Cards layout):
   - Total Crops: `SELECT COUNT(*) FROM CROP`
   - Total Workers: `SELECT COUNT(*) FROM TECHNICIAN`
   - Total Equipment: `SELECT COUNT(*) FROM EQUIPMENT`
   - Total Harvests: `SELECT COUNT(*) FROM CROP WHERE harvest_date IS NOT NULL`
2. **Bar Chart region** — source SQL:
   ```sql
   SELECT c.category_name, COUNT(b.booking_id) total_bookings
   FROM EQUIPMENT_CATEGORY c JOIN EQUIPMENT e ON c.category_id=e.category_id
   LEFT JOIN BOOKING b ON e.equipment_id=b.equipment_id
   GROUP BY c.category_name
   ```
3. **Line Chart region** — source: `SELECT * FROM (your Phase XV Report 6 monthly revenue query)`
4. **Interactive Report region** "Upcoming Activities" — source:
   ```sql
   SELECT * FROM VW_FARMER_BOOKING_ASSIGNMENT
   WHERE start_date BETWEEN SYSDATE AND SYSDATE+7
   ```

Attach Authorization Scheme `Is Staff` to the page (lowest tier — everyone who can log in sees the dashboard).

---

## 5. Forms (Pages 10–19)

For each one: **App Builder → Create Page → Form → "From a Table or View."** The wizard auto-generates the Interactive Grid (list) + Form (detail) pair — this is the fastest part of the whole build.

| Page | Wizard Source Table | Notes to apply after generation |
|---|---|---|
| 10 – Crops | `CROP` | Change `farm_id` item to a Select List (LOV: `SELECT location, farm_id FROM FARM`) |
| 11 – Fields | `FARM` | LOV on `farmer_id` → `SELECT first_name\|\|' '\|\|last_name, farmer_id FROM FARMER` |
| 12 – Harvests | `CROP` | On the Interactive Grid region, add a filter: `WHERE harvest_date IS NULL`. Only expose the `harvest_date` and `season` fields on the form — hide the rest |
| 13 – Workers | `TECHNICIAN` | LOV on `specialty` if you want a fixed list, otherwise free text is fine |
| 14 – Equipment | `EQUIPMENT` | LOVs on `category_id` and `owner_id`; format `status` column as a **Badge** column type (List: AVAILABLE=green, RENTED=blue, MAINTENANCE=orange, RETIRED=grey) |
| 15 – Inventory/Availability | *(not table-based — see below)* | |
| 16 – Suppliers | `EQUIPMENT_OWNER` | LOV on `business_type`: static list INDIVIDUAL/COOPERATIVE/DEALER |
| 17 – Activities | `BOOKING` | See "Calling procedures instead of raw DML" below — **do this one last** |
| 18 – Customers | `FARMER` | Straightforward wizard generation |
| 19 – Sales/Payments | `PAYMENT` | LOV on `booking_id` filtered to bookings with no existing payment: `SELECT booking_id FROM BOOKING b WHERE NOT EXISTS (SELECT 1 FROM PAYMENT p WHERE p.booking_id=b.booking_id)` |

**Page 15 (Inventory/Availability)** is deliberately not a table-based form (see Phase XVI reasoning — it would duplicate Equipment). Build it as **Create Page → Interactive Report**, source:
```sql
SELECT ec.category_name, fn_available_equipment_count(ec.category_id) AS available_units
FROM EQUIPMENT_CATEGORY ec
```

### Calling procedures instead of raw DML (important — do this for Page 17 Activities)

The auto-generated form's Save button does a raw `INSERT`/`UPDATE`, which bypasses the overlap-conflict check in `sp_create_booking`. Fix this:

1. Open Page 17 → the form page (not the grid).
2. Go to the **Processing** section → find the automatically created **"Automatic Row Processing (DML)"** process for the Create case.
3. **Uncheck/disable** it (or delete it) for INSERT only — keep it for UPDATE/DELETE if you're not routing those through packages too.
4. **Create a new page process**: type **PL/SQL Code**, positioned where the DML process was, condition: "When Button Pressed = CREATE":
   ```sql
   PKG_FARM_OPERATIONS.sp_schedule_activity(
       p_farmer_id      => :P17_FARMER_ID,
       p_equipment_id   => :P17_EQUIPMENT_ID,
       p_start_date     => :P17_START_DATE,
       p_end_date       => :P17_END_DATE,
       p_new_booking_id => :P17_BOOKING_ID
   );
   ```
5. Add an **Error Handling Function** (Page Attributes → Error Handling) that catches `ORA-20010` (overlap) and `ORA-20030`/`ORA-20031` (weekday/holiday) and rewrites the message to plain English before it reaches the user — this is what the Phase XVI design document promises ("friendly message surfaces the error in plain language").

Do the same substitution for **Page 19 (Sales/Payments)**, calling `sp_record_payment` instead of raw DML.

---

## 6. Reports (Pages 20–25)

**Create Page → Interactive Report**, SQL source pulled directly from your Phase XV/VII work — copy-paste, don't retype:

| Page | Source |
|---|---|
| 20 – Worker Activities | `SELECT * FROM (`your ManagementReports.sql Report 3 query`)` |
| 21 – Equipment Maintenance | `SELECT * FROM VW_SERVICE_DUE_REMINDER` |
| 22 – Crop Production | `SELECT * FROM (`ManagementReports Report 1`)` |
| 23 – Harvest Summary | `SELECT * FROM (`ManagementReports Report 2`)` |
| 24 – Farm Revenue | `SELECT * FROM (`ManagementReports Report 6`)` + a Chart region below it, same source |
| 25 – Farm Performance Dashboard | `SELECT * FROM (`ManagementReports Report 10`)` |

For Page 21, add a **Conditional Format** rule on the Interactive Report: `days_since_last_service > 180` → row highlighted red. (Format menu on the column → Conditional Formatting.)

---

## 7. Administration (Pages 30–33)

Same Form-wizard pattern as Section 5, but attach Authorization Scheme **`Is Administrator`** to all four pages (Page Attributes → Security → Authorization Scheme):

| Page | Source |
|---|---|
| 30 – Users & Roles | This is really just documentation of your 3 workspace accounts + Authorization Schemes from Section 2 — a static Text region explaining the mapping is enough; APEX doesn't need a CRUD page for its own accounts |
| 31 – Public Holidays | Form wizard on `PUBLIC_HOLIDAY` |
| 32 – Audit Log | Interactive Report (read-only) on `AUDIT_LOG`, default sort `changed_at DESC` |
| 33 – Equipment Categories | Form wizard on `EQUIPMENT_CATEGORY` |

**Important test:** log in as `staff_test` and try to browse directly to Page 32 by editing the URL. You should get an "Access Denied" / not-authorized page, not the audit log. If you see the data, the Authorization Scheme isn't attached — check Page Attributes → Security on that page.

---

## 8. Testing pass (do this before taking screenshots)

Walk through your own **Manual APEX UI Test Cases** table from the Testing Plan document (M01–M10) end to end, logged in as each of the three test accounts. Specifically confirm:

- [ ] `staff_test` cannot see the Administration menu item at all
- [ ] `staff_test` cannot reach Page 30–33 by direct URL
- [ ] Creating a booking on a weekday shows a readable error, not a raw ORA- stack trace
- [ ] Creating a booking that overlaps an existing one (try farmer 2, equipment 5, dates `12-JUN-2026` to `14-JUN-2026` against the Phase V sample data) is rejected with a clear message
- [ ] The Home Dashboard KPI numbers match what you get running the equivalent `SELECT COUNT(*)` manually in SQL Developer

---

## 9. Screenshot checklist (matches your README Section 5)

Take these now, while everything is fresh and working:
1. Login page
2. Home Dashboard (KPIs + both charts visible)
3. Activities (Page 17) form showing the weekday/overlap error message triggered live
4. Any Interactive Report (Page 21 or 24 recommended — both have visual formatting to show off)
5. SQL Developer window showing `Testing.sql`'s PASS/FAIL/SKIP summary
6. The ERD (already available from earlier in this project)

Save them into `screenshots/` in your submission folder, replacing the placeholder file there.

---

## 10. Realistic time estimate

If you're doing this for the first time in APEX: roughly 3–5 hours for a working end-to-end app across all pages, most of it in Sections 5–6 (the wizard-generated forms/reports are fast; the manual procedure-call substitutions in Section 5 are the slow part). Budget extra time if this is your first time in App Builder — the wizards are fast once you've done two or three, slower on the first one while you're getting oriented.
