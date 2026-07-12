--------------------------------------------------------------------------------
-- DPR400210 Capstone Project
-- Smart Agricultural Resource and Farm Operations Management System (SARFOMS)
-- Student: Ruben King | Student ID: 29761/2025
-- Oracle Username: 29761_2025 | Schema/Project Name: 29761_2025_RubenKing_DB
-- Phase V: Table Implementation
--------------------------------------------------------------------------------
-- Run this script AFTER connecting as the project's own Oracle user/schema.
-- Example (run once as SYSTEM/SYS, then reconnect as this user):
--   CREATE USER "29761_2025" IDENTIFIED BY YourPassword123;
--   GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE, CREATE TRIGGER TO "29761_2025";
--   ALTER USER "29761_2025" QUOTA UNLIMITED ON USERS;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. FARMER  (renter of equipment, owner of one or more farm plots)
--------------------------------------------------------------------------------
CREATE TABLE FARMER (
    farmer_id           NUMBER(6)       CONSTRAINT pk_farmer PRIMARY KEY,
    first_name          VARCHAR2(50)    NOT NULL,
    last_name           VARCHAR2(50)    NOT NULL,
    phone               VARCHAR2(15)    NOT NULL,
    email               VARCHAR2(100),
    national_id         VARCHAR2(20)    NOT NULL,
    address             VARCHAR2(150),
    registration_date   DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_farmer_phone       UNIQUE (phone),
    CONSTRAINT uq_farmer_email       UNIQUE (email),
    CONSTRAINT uq_farmer_national_id UNIQUE (national_id)
);

--------------------------------------------------------------------------------
-- 2. FARM  (a physical plot belonging to a farmer)
--------------------------------------------------------------------------------
CREATE TABLE FARM (
    farm_id         NUMBER(6)       CONSTRAINT pk_farm PRIMARY KEY,
    farmer_id       NUMBER(6)       NOT NULL,
    location        VARCHAR2(100)   NOT NULL,
    size_hectares   NUMBER(6,2)     NOT NULL,
    soil_type       VARCHAR2(30),
    CONSTRAINT fk_farm_farmer     FOREIGN KEY (farmer_id) REFERENCES FARMER(farmer_id),
    CONSTRAINT chk_farm_size      CHECK (size_hectares > 0)
);

--------------------------------------------------------------------------------
-- 3. CROP  (what is planted on a farm plot for a given season)
--------------------------------------------------------------------------------
CREATE TABLE CROP (
    crop_id         NUMBER(6)       CONSTRAINT pk_crop PRIMARY KEY,
    farm_id         NUMBER(6)       NOT NULL,
    crop_name       VARCHAR2(50)    NOT NULL,
    planting_date   DATE            NOT NULL,
    harvest_date    DATE,
    season          VARCHAR2(1),
    CONSTRAINT fk_crop_farm        FOREIGN KEY (farm_id) REFERENCES FARM(farm_id),
    CONSTRAINT chk_crop_season     CHECK (season IN ('A','B','C')),
    CONSTRAINT chk_crop_dates      CHECK (harvest_date IS NULL OR harvest_date > planting_date)
);

--------------------------------------------------------------------------------
-- 4. EQUIPMENT_CATEGORY  (Tractor / Pump / Drone / Sensor Kit, etc.)
--------------------------------------------------------------------------------
CREATE TABLE EQUIPMENT_CATEGORY (
    category_id     NUMBER(4)       CONSTRAINT pk_equipment_category PRIMARY KEY,
    category_name   VARCHAR2(50)    NOT NULL,
    description     VARCHAR2(200),
    CONSTRAINT uq_category_name UNIQUE (category_name)
);

--------------------------------------------------------------------------------
-- 5. EQUIPMENT_OWNER  (individual, cooperative, or dealer who lists equipment)
--------------------------------------------------------------------------------
CREATE TABLE EQUIPMENT_OWNER (
    owner_id        NUMBER(6)       CONSTRAINT pk_equipment_owner PRIMARY KEY,
    owner_name      VARCHAR2(80)    NOT NULL,
    phone           VARCHAR2(15)    NOT NULL,
    email           VARCHAR2(100),
    business_type   VARCHAR2(30)    DEFAULT 'INDIVIDUAL',
    CONSTRAINT uq_owner_phone     UNIQUE (phone),
    CONSTRAINT chk_owner_type     CHECK (business_type IN ('INDIVIDUAL','COOPERATIVE','DEALER'))
);

--------------------------------------------------------------------------------
-- 6. EQUIPMENT  (the rentable asset itself)
--------------------------------------------------------------------------------
CREATE TABLE EQUIPMENT (
    equipment_id        NUMBER(6)      CONSTRAINT pk_equipment PRIMARY KEY,
    category_id         NUMBER(4)      NOT NULL,
    owner_id            NUMBER(6)      NOT NULL,
    equipment_name      VARCHAR2(80)   NOT NULL,
    model               VARCHAR2(50),
    daily_rate          NUMBER(10,2)   NOT NULL,
    status              VARCHAR2(20)   DEFAULT 'AVAILABLE' NOT NULL,
    acquisition_date    DATE           DEFAULT SYSDATE,
    CONSTRAINT fk_equipment_category  FOREIGN KEY (category_id) REFERENCES EQUIPMENT_CATEGORY(category_id),
    CONSTRAINT fk_equipment_owner     FOREIGN KEY (owner_id)    REFERENCES EQUIPMENT_OWNER(owner_id),
    CONSTRAINT chk_equipment_rate     CHECK (daily_rate > 0),
    CONSTRAINT chk_equipment_status   CHECK (status IN ('AVAILABLE','RENTED','MAINTENANCE','RETIRED'))
);

--------------------------------------------------------------------------------
-- 7. BOOKING  (the rental transaction; where conflict-checking logic lives)
--------------------------------------------------------------------------------
CREATE TABLE BOOKING (
    booking_id      NUMBER(8)       CONSTRAINT pk_booking PRIMARY KEY,
    farmer_id       NUMBER(6)       NOT NULL,
    equipment_id    NUMBER(6)       NOT NULL,
    start_date      DATE            NOT NULL,
    end_date        DATE            NOT NULL,
    status          VARCHAR2(20)    DEFAULT 'PENDING' NOT NULL,
    created_at      DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_booking_farmer     FOREIGN KEY (farmer_id)    REFERENCES FARMER(farmer_id),
    CONSTRAINT fk_booking_equipment  FOREIGN KEY (equipment_id) REFERENCES EQUIPMENT(equipment_id),
    CONSTRAINT chk_booking_dates     CHECK (end_date >= start_date),
    CONSTRAINT chk_booking_status    CHECK (status IN ('PENDING','CONFIRMED','COMPLETED','CANCELLED'))
);

--------------------------------------------------------------------------------
-- 8. PAYMENT  (1:1 with BOOKING, kept separate deliberately -- see notes below)
--------------------------------------------------------------------------------
CREATE TABLE PAYMENT (
    payment_id      NUMBER(8)       CONSTRAINT pk_payment PRIMARY KEY,
    booking_id      NUMBER(8)       NOT NULL,
    amount          NUMBER(10,2)    NOT NULL,
    payment_date    DATE,
    payment_method  VARCHAR2(20),
    status          VARCHAR2(20)    DEFAULT 'UNPAID' NOT NULL,
    CONSTRAINT fk_payment_booking   FOREIGN KEY (booking_id) REFERENCES BOOKING(booking_id),
    CONSTRAINT uq_payment_booking   UNIQUE (booking_id),
    CONSTRAINT chk_payment_amount   CHECK (amount > 0),
    CONSTRAINT chk_payment_method   CHECK (payment_method IN ('CASH','MOBILE_MONEY','BANK_TRANSFER')),
    CONSTRAINT chk_payment_status   CHECK (status IN ('UNPAID','PAID','REFUNDED'))
);

--------------------------------------------------------------------------------
-- 9. TECHNICIAN  (staff who service equipment)
--------------------------------------------------------------------------------
CREATE TABLE TECHNICIAN (
    technician_id   NUMBER(6)       CONSTRAINT pk_technician PRIMARY KEY,
    full_name       VARCHAR2(80)    NOT NULL,
    phone           VARCHAR2(15)    NOT NULL,
    specialty       VARCHAR2(50),
    CONSTRAINT uq_technician_phone UNIQUE (phone)
);

--------------------------------------------------------------------------------
-- 10. MAINTENANCE_RECORD  (service history per equipment item)
--------------------------------------------------------------------------------
CREATE TABLE MAINTENANCE_RECORD (
    maintenance_id  NUMBER(8)       CONSTRAINT pk_maintenance_record PRIMARY KEY,
    equipment_id    NUMBER(6)       NOT NULL,
    technician_id   NUMBER(6)       NOT NULL,
    service_date    DATE            NOT NULL,
    description     VARCHAR2(300),
    cost            NUMBER(10,2),
    CONSTRAINT fk_maintenance_equipment  FOREIGN KEY (equipment_id)  REFERENCES EQUIPMENT(equipment_id),
    CONSTRAINT fk_maintenance_technician FOREIGN KEY (technician_id) REFERENCES TECHNICIAN(technician_id),
    CONSTRAINT chk_maintenance_cost      CHECK (cost >= 0)
);

--------------------------------------------------------------------------------
-- 11. SENSOR_READING  (time-series soil/crop monitoring data)
--------------------------------------------------------------------------------
CREATE TABLE SENSOR_READING (
    reading_id          NUMBER(10)      CONSTRAINT pk_sensor_reading PRIMARY KEY,
    farm_id             NUMBER(6)       NOT NULL,
    crop_id             NUMBER(6),
    reading_timestamp   TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    soil_moisture       NUMBER(5,2),
    temperature         NUMBER(5,2),
    humidity            NUMBER(5,2),
    CONSTRAINT fk_reading_farm     FOREIGN KEY (farm_id) REFERENCES FARM(farm_id),
    CONSTRAINT fk_reading_crop     FOREIGN KEY (crop_id) REFERENCES CROP(crop_id),
    CONSTRAINT chk_reading_moisture CHECK (soil_moisture BETWEEN 0 AND 100),
    CONSTRAINT chk_reading_humidity CHECK (humidity BETWEEN 0 AND 100)
);

--------------------------------------------------------------------------------
-- 12. PUBLIC_HOLIDAY  (reference table for the mandatory weekday/holiday lock)
--------------------------------------------------------------------------------
CREATE TABLE PUBLIC_HOLIDAY (
    holiday_id      NUMBER(4)       CONSTRAINT pk_public_holiday PRIMARY KEY,
    holiday_date    DATE            NOT NULL,
    description     VARCHAR2(100),
    CONSTRAINT uq_holiday_date UNIQUE (holiday_date)
);

--------------------------------------------------------------------------------
-- 13. AUDIT_LOG  (generic audit trail populated by triggers in Phase VII)
--------------------------------------------------------------------------------
CREATE TABLE AUDIT_LOG (
    audit_id        NUMBER(10)      CONSTRAINT pk_audit_log PRIMARY KEY,
    table_name      VARCHAR2(30)    NOT NULL,
    operation       VARCHAR2(10)    NOT NULL,
    record_id       NUMBER(10),
    changed_by      VARCHAR2(50)    DEFAULT USER NOT NULL,
    changed_at      DATE            DEFAULT SYSDATE NOT NULL,
    old_value       VARCHAR2(4000),
    new_value       VARCHAR2(4000),
    CONSTRAINT chk_audit_operation CHECK (operation IN ('INSERT','UPDATE','DELETE'))
);

--------------------------------------------------------------------------------
-- End of Phase V: Table Implementation
--------------------------------------------------------------------------------
