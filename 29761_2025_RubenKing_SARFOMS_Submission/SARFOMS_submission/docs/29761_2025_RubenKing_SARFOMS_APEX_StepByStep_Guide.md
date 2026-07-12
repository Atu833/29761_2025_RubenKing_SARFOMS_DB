# SARFOMS — Step-by-Step Oracle APEX Build Guide (First-Time Builder Edition)

**Student:** Ruben King | **Student ID:** 29761/2025
**Assumes:** you have never opened App Builder before. Every click is spelled out. Follow top to bottom — don't skip ahead.

---

## 1. Create the Application

1. Log into your Oracle APEX workspace at your instance's URL (e.g. `https://apex.oracle.com/pls/apex/workspace_login`, or your institution's URL).
2. On the **Workspace Home** page, click the **App Builder** icon (large blue icon near the top).
3. Click the orange **Create** button (top-right).
4. You'll see two tiles: **New Application** and **Import**. Click **New Application**.
5. On the "Create Application" screen:
   - **Name:** type `SARFOMS`
   - **Appearance → Theme Style:** leave the default (Redwood or Vita, whichever your version shows) — don't change this
   - Scroll down to **Pages**: you'll see it auto-added a "Home" page (Page 1) and possibly "Login" — leave these, we'll rebuild Page 1's content in Section 4 below
   - Ignore "Features" toggles (Login, etc.) — leave defaults checked
6. Click **Create Application** (top-right button). Wait for the spinner — this takes 10–30 seconds.
7. You land on the **App Builder → SARFOMS** overview page (a grid of page thumbnails). This is your app's home base — you'll return here constantly.

**Checkpoint:** you should see "Application 100 (or similar number) — SARFOMS" in the page title, with at least a "Home" page tile visible.

---

## 2. Configure Authentication

1. From the App Builder → SARFOMS overview page, click **Shared Components** (left sidebar, or top icon row).
2. Under the **Security** heading, click **Authentication Schemes**.
3. Click **Create** (top-right).
4. Choose **Based on a pre-configured scheme from the gallery** → click **Next**.
5. **Scheme Type:** select **Application Express Accounts** from the dropdown.
6. **Name:** type `SARFOMS Login`.
7. Click **Create Authentication Scheme**.
8. Back on the Authentication Schemes list, find `SARFOMS Login`, click the small checkbox/star icon or use the **Make Current** button to activate it as the app's active scheme (if it isn't already marked "Current").

### Create your 3 test user accounts

1. Go back to **Workspace Home** (click the house icon top-left, or your workspace name).
2. Click **Administration** → **Manage Users and Groups** (this may instead be under a gear/Administration icon depending on your version).
3. Click **Create User**, and create these three, one at a time (set any password you'll remember, e.g. `Sarfoms2026!`):
   - Username: `ADMIN_RUBEN`
   - Username: `MANAGER_TEST`
   - Username: `STAFF_TEST`
4. Click **Create User** after filling each one in.

**Checkpoint:** Manage Users list shows all 3 accounts. Try logging out and back in as `ADMIN_RUBEN` to confirm the password works before continuing.

---

## 3. Authorization Schemes (the 3 roles)

1. Back in **App Builder → SARFOMS → Shared Components → Security → Authorization Schemes**.
2. Click **Create** → **From Scratch**.
3. Fill in:
   - **Name:** `Is Administrator`
   - **Scheme Type:** `Exists SQL Query`
   - **SQL Query:** `SELECT 1 FROM DUAL WHERE :APP_USER = 'ADMIN_RUBEN'`
   - **Error Message:** `You do not have permission to access this page.`
4. Click **Create Authorization Scheme**.
5. Repeat **Create → From Scratch** two more times:
   - Name: `Is Farm Manager`, Query: `SELECT 1 FROM DUAL WHERE :APP_USER IN ('ADMIN_RUBEN','MANAGER_TEST')`
   - Name: `Is Staff`, Query: `SELECT 1 FROM DUAL WHERE :APP_USER IN ('ADMIN_RUBEN','MANAGER_TEST','STAFF_TEST')`

You'll attach these to individual pages in Section 4 (look for "Attach Authorization Scheme" instructions per page).

---

## 4. Build Each Page

**The general pattern you'll repeat:** App Builder → SARFOMS overview → **Create Page** (orange button, top-right) → pick a page type → wizard.

### 4A. Home Dashboard (Page 1) — full click path

1. From the SARFOMS overview, if a "Home" page (Page 1) already exists from the create-app wizard, click its thumbnail to open it in **Page Designer**. Otherwise click **Create Page → Blank Page**, name it `Home Dashboard`.
2. In Page Designer, look at the **Rendering** tree on the far left — right-click the page name → **Create Region** (or click the small `+` icon next to Content Body).
3. **Region 1 — KPI card:**
   - Title: `Total Crops`
   - Type: change the "Type" dropdown (right-hand Property panel) to **Value** (sometimes listed under "KPI" region types, or use a "Card" region — pick whichever your version offers under Region Type)
   - Under **Source**, SQL Query: `SELECT COUNT(*) FROM CROP`
4. Repeat step 3 three more times for:
   - `Total Workers` → `SELECT COUNT(*) FROM TECHNICIAN`
   - `Total Equipment` → `SELECT COUNT(*) FROM EQUIPMENT`
   - `Total Harvests` → `SELECT COUNT(*) FROM CROP WHERE harvest_date IS NOT NULL`
5. **Region 5 — Bar Chart:** right-click Content Body → **Create Region** → Title `Bookings by Category` → Type: **Chart**. In the chart's series editor (click the chart region, then the "Series" sub-node that appears under it in the tree), set the SQL:
   ```sql
   SELECT c.category_name, COUNT(b.booking_id) total_bookings
   FROM EQUIPMENT_CATEGORY c JOIN EQUIPMENT e ON c.category_id=e.category_id
   LEFT JOIN BOOKING b ON e.equipment_id=b.equipment_id
   GROUP BY c.category_name
   ```
   Chart Type: **Bar**.
6. **Region 6 — Interactive Report "Upcoming Activities":** Create Region → Type: **Interactive Report** → SQL Query:
   ```sql
   SELECT * FROM VW_FARMER_BOOKING_ASSIGNMENT
   WHERE start_date BETWEEN SYSDATE AND SYSDATE+7
   ```
7. Click **Save and Run Page** (top-right, or the "play" icon) to preview.
8. **Attach security:** click the page name at the top of the tree (the root node) → in the Property panel on the right, find **Security → Authorization Scheme** → select `Is Staff`.
9. Click **Save**.

**Checkpoint:** running the page shows 4 numbers, a bar chart, and a small report — even if some are zero/empty, that's fine, it means the query ran.

### 4B. Forms (Pages 10–19) — the fast, wizard-driven pattern

Do this once fully for **Crops**, then repeat identically (swapping the table/settings per the table in Section 4C) for the rest.

1. From SARFOMS overview → **Create Page** → choose **Form**.
2. Choose **Form on a Table or View**.
3. **Table/View Name:** select `CROP` from the dropdown (it lists your schema's objects — type to filter).
4. It auto-detects the primary key (`CROP_ID`) — leave as-is.
5. **Page Name (Report):** `Crops` — this creates TWO pages automatically: one Interactive Grid/Report (the list) and one Form (the detail/edit screen). Note both page numbers it assigns you (e.g., 10 and 11) — write these down, you'll need them for navigation later.
6. Click **Next**, review, click **Create**.
7. It drops you into Page Designer for the report page. Click **Save and Run Page** to see the auto-generated list — click any row (or the **Create** button on that page) to see the auto-generated form.
8. **Fix the lookup field:** back in Page Designer for the *Form* page, find the `FARM_ID` item in the tree (left side, under a "Farmer Info" or similar region). Click it. In the Property panel:
   - **Type:** change from "Number Field" to **Select List**
   - **List of Values → Type:** SQL Query
   - **SQL Query:** `SELECT location d, farm_id r FROM FARM`
9. Click **Save**.

**Checkpoint:** open the Crops list page, click Create, confirm the Farm field now shows a dropdown of farm locations instead of a raw number box.

### 4C. Remaining Forms — table/view + specific tweaks

Repeat the Section 4B pattern (Create Page → Form → Form on a Table or View) for each row below. The "Tweak" column tells you what to change afterward, using the same Property-panel technique from step 8 above.

| Form | Source | Tweak after generation |
|---|---|---|
| Fields | `FARM` | `FARMER_ID` → Select List, LOV SQL: `SELECT first_name\|\|' '\|\|last_name d, farmer_id r FROM FARMER` |
| Workers | `TECHNICIAN` | None needed — plain text fields are fine |
| Equipment | `EQUIPMENT` | `CATEGORY_ID` → Select List (`SELECT category_name d, category_id r FROM EQUIPMENT_CATEGORY`); `OWNER_ID` → Select List (`SELECT owner_name d, owner_id r FROM EQUIPMENT_OWNER`); on the **report** page, click the `STATUS` column → Property panel → **Type: Badge List**, add 4 List entries (AVAILABLE=green, RENTED=blue, MAINTENANCE=orange, RETIRED=grey) |
| Suppliers | `EQUIPMENT_OWNER` | `BUSINESS_TYPE` → Select List, **List of Values Type: Static Values**, add 3 entries: INDIVIDUAL, COOPERATIVE, DEALER |
| Customers | `FARMER` | None needed |
| Sales / Payments | `PAYMENT` | `BOOKING_ID` → Select List, LOV SQL: `SELECT booking_id d, booking_id r FROM BOOKING b WHERE NOT EXISTS (SELECT 1 FROM PAYMENT p WHERE p.booking_id=b.booking_id)` |
| Harvests | `CROP` (same table as Crops, different page) | On the **report** page: click the region → Property panel → **Source → Where Clause**: `harvest_date IS NULL`. On the **form** page: delete/hide every field except `HARVEST_DATE` and `SEASON` (click each unwanted item → Delete, or set **Identification → Type** to "Display Only" if you'd rather keep them visible but locked) |
| Activities | `BOOKING` | **Do this one last — see Section 5, it needs a different process, not just a field tweak** |

### 4D. Inventory / Availability (Page 15) — not table-based

1. Create Page → **Interactive Report** (not Form this time).
2. SQL Query:
   ```sql
   SELECT ec.category_name, fn_available_equipment_count(ec.category_id) AS available_units
   FROM EQUIPMENT_CATEGORY ec
   ```
3. Save and Run to confirm it lists your 7 categories with counts.

### 4E. Reports (Pages 20–25)

Same click path each time: **Create Page → Interactive Report → SQL Query** (type or paste it in).

| Page | SQL source |
|---|---|
| Worker Activities | Copy the query from `ManagementReports.sql`, Report 3 |
| Equipment Maintenance | `SELECT * FROM VW_SERVICE_DUE_REMINDER` |
| Crop Production | `ManagementReports.sql`, Report 1 |
| Harvest Summary | `ManagementReports.sql`, Report 2 |
| Farm Revenue | `ManagementReports.sql`, Report 6 |
| Farm Performance Dashboard | `ManagementReports.sql`, Report 10 |

**Conditional formatting on Equipment Maintenance:** in Page Designer, click the `DAYS_SINCE_LAST_SERVICE` column in the report region → right-click → **Create Format Rule** (or find "Column Formatting" in the Property panel) → Condition: `days_since_last_service > 180` → Highlight: red background.

### 4F. Administration Pages (30–33)

Same Form/Interactive Report pattern as above, on `PUBLIC_HOLIDAY`, `AUDIT_LOG` (Interactive Report, read-only — don't run the Form wizard, just Interactive Report, since nobody should hand-edit audit rows), and `EQUIPMENT_CATEGORY`.

**Critical extra step for all 4 admin pages:** click the page name (root of the tree) → Property panel → **Security → Authorization Scheme** → select `Is Administrator`. Do this for every one of the 4 admin pages individually — it does not inherit automatically.

### 4G. Navigation Menu

1. **Shared Components → Navigation → Navigation Menu**.
2. Click **Create Entry** for each item, filling in **Name** and **Target → Page** (pick from the dropdown, which lists pages by number and name — this is why you wrote down page numbers earlier).
3. To create a sub-item (e.g., "Crops" under "Crop Management"), set its **Parent Entry** dropdown to the parent item.
4. Build the full structure from the walkthrough document's Section 3 tree (Home Dashboard, Crop Management → Crops/Fields/Harvests, etc.).
5. For the **Administration** top-level entry itself: click it, Property panel → **Authorization Scheme** → `Is Administrator` (this hides the whole menu branch, not just the pages, for non-admins).

---

## 5. Replace Automatic Row Processing on the Activities Page

This is the step that makes your booking form actually enforce `sp_schedule_activity`'s conflict checks instead of silently bypassing them.

1. Open **Page Designer** for the Activities **Form** page (the detail/edit page, not the list — check the page number you wrote down for it).
2. Look at the left-hand tree. Find the **Processing** section (below Rendering). Expand it.
3. You'll see a process usually named **"Process Row of BOOKING"** or **"Automatic Row Processing (DML)"**. Click it.
4. In the Property panel, find **Server-side Condition → When Button Pressed**. Note it's currently set to fire on both Create and Update (or "SAVE" generically).
5. Change **Type** (top of Property panel) from "Automatic Row Processing (DML)" to restrict it — the simplest safe approach: click the process, then in **Server-side Condition**, change **When Button Pressed** so it only fires for **Delete** (if you still want automatic delete handling) or disable it entirely by toggling the process to **Disabled** at the top of the Property panel if you're routing Delete through a procedure too.

   *If your APEX version won't let you narrow an auto-generated DML process to "Delete only," the simpler route: right-click the process → **Delete**, removing it completely, and handle Delete via a second PL/SQL process later if you need it (optional for this project — Delete on Activities isn't a required page action).

6. **Create the replacement process:** right-click **Processing** → **Create Process**.
   - **Name:** `Schedule Activity via Package`
   - **Type:** **PL/SQL Code**
   - **PL/SQL Code** box:
     ```sql
     PKG_FARM_OPERATIONS.sp_schedule_activity(
         p_farmer_id      => :P17_FARMER_ID,
         p_equipment_id   => :P17_EQUIPMENT_ID,
         p_start_date     => :P17_START_DATE,
         p_end_date       => :P17_END_DATE,
         p_new_booking_id => :P17_BOOKING_ID
     );
     ```
     (Replace `P17_` with your actual page-item prefix — Page Designer shows each item's exact name in the tree; it's always `P` + page number + `_` + column name in uppercase.)
   - **Server-side Condition → When Button Pressed:** `CREATE` (or whatever your Create button's static ID is — check the Buttons node in the tree).
   - **Execution Options → Sequence:** give it a number lower than any other process on the page if there are others, so it runs first.
7. Click **Save**.

### Add friendly error rewriting

1. Still in Page Designer, click the page name (root of tree) → Property panel → **Error Handling** section → **Error Handling Function**.
2. Type a PL/SQL function reference, e.g. `sarfoms_pkg_error_handler.rewrite_error` — but since that's a new function, simplest for a capstone deadline: **skip the custom function** and instead just confirm the raw message is already readable. Test it: try creating a conflicting booking and read what APEX shows. Because `sp_schedule_activity` now raises specific messages like *"Equipment 5 already has a conflicting booking for that date range"* (from your Phase corrections), APEX's default error display already shows this text directly — a custom Error Handling Function is a nice-to-have polish step, not a requirement, since the underlying message is already friendly.
3. Click **Save**.

**Checkpoint:** run the Activities page, submit a booking with the same equipment/overlapping dates as an existing one (try farmer 2, equipment 5, dates `12-JUN-2026` to `14-JUN-2026`, which conflicts with your Phase V sample data). You should see the friendly conflict message, not a raw ORA- stack trace, and no new row should appear in the report afterward.

---

## 6. Test Every Page

Go through this checklist logged in as each of your 3 test accounts (log out and back in between):

| # | Test | Logged in as | Expected result |
|---|---|---|---|
| 1 | Open Home Dashboard | staff_test | KPIs and charts load |
| 2 | Browse to Administration menu | staff_test | Menu item is not visible |
| 3 | Type the Administration page's URL directly (`f?p=100:30`) | staff_test | "You do not have permission" message, page does not load |
| 4 | Open Administration → Audit Log | admin_ruben | Loads, shows rows |
| 5 | Create a Crop with harvest_date before planting_date | manager_test | Rejected (either inline validation or the database CHECK constraint message) |
| 6 | Create a Booking on a weekday | manager_test | Friendly weekday-lock message from `trg_booking_biud_rules` |
| 7 | Create a Booking overlapping an existing one | manager_test | Friendly conflict message from `sp_schedule_activity` (`ORA-20057` text) |
| 8 | Create a Booking for RETIRED equipment (e.g. equipment_id 8 or 19) | manager_test | Friendly rejection message (`ORA-20062`) |
| 9 | Create a Booking with an invalid farmer_id (shouldn't be reachable via the Select List, but test by temporarily typing one if your form allows) | manager_test | Friendly rejection (`ORA-20060`), not a raw FK error |
| 10 | Open each of the 6 Report pages | manager_test | Each loads without error |
| 11 | Sort/filter an Interactive Report column | manager_test | Works (built into APEX automatically) |
| 12 | Compare a Home Dashboard KPI number to a manual `SELECT COUNT(*)` in SQL Developer | admin_ruben | Numbers match exactly |

---

## 7. Screenshots to Take (for the Final Report and GitHub)

Capture these once everything above passes:

1. **Login page**
2. **Home Dashboard** — all 4 KPI cards + both charts visible in one shot
3. **Activities form showing the overlap-conflict error message live** (test #7 above, screenshotted at the moment the error displays)
4. **Activities form showing the weekday-lock error message live** (test #6 above)
5. **Equipment report** with the status Badge List column visible (color-coded AVAILABLE/RENTED/MAINTENANCE/RETIRED)
6. **Equipment Maintenance report** with the red conditional-formatting row visible
7. **Administration → Audit Log**, logged in as admin_ruben
8. **Attempted direct URL access to Administration as staff_test**, showing the access-denied message (test #3)
9. **SQL Developer window** running `29761_2025_RubenKing_SARFOMS_Testing.sql` with the PASS/FAIL/SKIP summary visible in the Script Output pane
10. **The ERD** (already available from earlier in this project)

Save all of these into the `screenshots/` folder in your submission ZIP, replacing the placeholder file, and reference them by filename in the Final Report where relevant (e.g., in the Innovation Component section).

---

## Quick troubleshooting

- **"LOV query returns no rows"** — double-check you typed `d` and `r` (or `DISPLAY`/`RETURN`) aliases correctly; some APEX versions require them, others infer from column position, but aliasing is always safe.
- **Page item name doesn't match `:P17_...`** — click the item in the Page Designer tree; its exact name is shown at the top of the Property panel under "Identification → Name." Always copy it from there rather than guessing.
- **"ORA-06550" on your new PL/SQL process** — almost always a typo in a page-item name or a missing package recompile. Re-run `29761_2025_RubenKing_SARFOMS_Packages.sql` in SQL Developer first, then re-check your item names.
- **Trigger blocks everything during testing** — remember `trg_booking_biud_rules` blocks BOOKING changes on weekdays/holidays. If you're testing on a weekday and need to freely create/edit bookings for UI testing, temporarily run `ALTER TRIGGER trg_booking_biud_rules DISABLE;` in SQL Developer, test, then **immediately** `ALTER TRIGGER trg_booking_biud_rules ENABLE;` afterward — never leave it disabled.
