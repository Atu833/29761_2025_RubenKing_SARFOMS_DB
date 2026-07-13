--------------------------------------------------------------------------------
-- DPR400210 Capstone Project
-- Smart Agricultural Resource and Farm Operations Management System (SARFOMS)
-- Student: Ruben King | Student ID: 29761/2025
-- Phase IV: Database Creation
--------------------------------------------------------------------------------
-- Run this FIRST, before CreateTables.sql, connected as a privileged account
-- (SYSTEM, SYS AS SYSDBA, or your instructor-provided admin account) --
-- NOT as the 29761_2025 user itself, since that user doesn't exist yet.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. CREATE THE ORACLE USER / SCHEMA
-- Naming convention per assignment brief: StudentID_FirstName_Project_DB
-- Oracle usernames cannot contain "/", so the student ID's slash is replaced
-- with an underscore: 29761/2025 -> 29761_2025 (documented and approved in
-- an earlier phase of this project).
--------------------------------------------------------------------------------
CREATE USER "29761_2025" IDENTIFIED BY YourPassword123;

--------------------------------------------------------------------------------
-- 2. ASSIGN PRIVILEGES
-- CONNECT  - allows the user to log in and create a session
-- RESOURCE - allows creating tables, procedures, functions, triggers, etc.
-- Additional explicit grants below cover object types RESOURCE does not
-- reliably include across all Oracle versions (view and sequence creation
-- in particular are inconsistently bundled into RESOURCE depending on
-- version/edition, so they are granted explicitly rather than assumed).
--------------------------------------------------------------------------------
GRANT CONNECT, RESOURCE TO "29761_2025";
GRANT CREATE VIEW TO "29761_2025";
GRANT CREATE SEQUENCE TO "29761_2025";
GRANT CREATE TRIGGER TO "29761_2025";
GRANT CREATE PROCEDURE TO "29761_2025";
GRANT CREATE SESSION TO "29761_2025";

-- Optional but recommended for the live demonstration: lets the student
-- query their own session's execution plans and use DBMS_OUTPUT/DBMS_XPLAN
-- without needing further ad-hoc grants mid-demo.
GRANT SELECT ON V_$SESSION TO "29761_2025";

--------------------------------------------------------------------------------
-- 3. CONFIGURE ACCESS (storage quota + default tablespace)
-- Without a quota grant, every CREATE TABLE in Phase V would fail with
-- ORA-01950 ("no privileges on tablespace") the moment real data is
-- inserted -- this step is not cosmetic, the schema is non-functional
-- without it.
--------------------------------------------------------------------------------
ALTER USER "29761_2025" QUOTA UNLIMITED ON USERS;
ALTER USER "29761_2025" DEFAULT TABLESPACE USERS;
ALTER USER "29761_2025" TEMPORARY TABLESPACE TEMP;

--------------------------------------------------------------------------------
-- 4. VERIFY THE USER WAS CREATED CORRECTLY
-- Run this as the SAME privileged account used above, immediately after
-- the grants, to confirm everything landed before handing off to Phase V.
--------------------------------------------------------------------------------
SELECT username, account_status, default_tablespace, temporary_tablespace, created
FROM dba_users
WHERE username = '29761_2025';

SELECT grantee, privilege
FROM dba_sys_privs
WHERE grantee = '29761_2025'
ORDER BY privilege;

SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee = '29761_2025';

--------------------------------------------------------------------------------
-- 5. RECONNECT AS THE NEW USER
-- From this point on, EVERY subsequent script in this project
-- (CreateTables.sql onward) must be run while connected AS "29761_2025",
-- not as the privileged account used above.
--------------------------------------------------------------------------------
-- In SQL Developer: create a new connection --
--   Username: 29761_2025
--   Password: YourPassword123  (the one you actually set in Step 1)
--   Role: default
--   Connection Type: Basic
--   Hostname / Port / Service Name: same as your existing SYSTEM connection
--
-- Confirm you're connected as the right user before continuing:
SELECT USER FROM DUAL;
-- Expected result: 29761_2025

--------------------------------------------------------------------------------
-- 6. OEM SCREENSHOT CHECKLIST (per assignment brief: "if available")
-- If your Oracle instance has Enterprise Manager (OEM) access, capture:
--   [ ] The new 29761_2025 user visible in OEM's Security > Users list
--   [ ] The user's assigned tablespace quota screen
--   [ ] The user's granted roles/privileges screen
-- If OEM is not available on your instance (common on shared/cloud
-- training environments), the SELECT statements in Section 4 above are
-- your evidence instead -- screenshot the SQL Developer query results
-- showing the user, privileges, and roles as a substitute. This is
-- explicitly permitted by the brief's "if available" qualifier.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- End of Phase IV: Database Creation
--------------------------------------------------------------------------------
