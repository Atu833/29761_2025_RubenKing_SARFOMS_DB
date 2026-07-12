--------------------------------------------------------------------------------
-- DPR400210 Capstone Project - SARFOMS Equipment Rental & Crop Monitoring
-- Student: Ruben King | Student ID: 29761/2025
-- Phase V (continued): INSERT Sample Data
-- Run AFTER 29761_2025_RubenKing_SARFOMS_CreateTables.sql
-- Note: IDs are hand-assigned here because Phase 6 (Sequences) comes next in
-- our build order; once sequences exist, future application INSERTs should
-- use them instead of literal numbers.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- FARMER (15 rows)
--------------------------------------------------------------------------------
INSERT INTO FARMER VALUES (1,'Jean Bosco','Habimana','0788111001','jbhabimana@gmail.com','1198010010001','Kinigi, Musanze',DATE '2025-01-10');
INSERT INTO FARMER VALUES (2,'Alice','Uwimana','0788111002','auwimana@gmail.com','1198510010002','Rwimiyaga, Nyagatare',DATE '2025-01-12');
INSERT INTO FARMER VALUES (3,'Emmanuel','Ndayisenga','0788111003','endayisenga@gmail.com','1199010010003','Tumba, Huye',DATE '2025-01-15');
INSERT INTO FARMER VALUES (4,'Claudine','Mukamana','0788111004','cmukamana@gmail.com','1199210010004','Fumbwe, Rwamagana',DATE '2025-01-18');
INSERT INTO FARMER VALUES (5,'Patrick','Nsengiyumva','0788111005','pnsengiyumva@gmail.com','1198810010005','Nyamata, Bugesera',DATE '2025-01-20');
INSERT INTO FARMER VALUES (6,'Solange','Uwase','0788111006','suwase@gmail.com','1199510010006','Mukarange, Kayonza',DATE '2025-02-01');
INSERT INTO FARMER VALUES (7,'Vincent','Rugamba','0788111007','vrugamba@gmail.com','1198610010007','Kibungo, Ngoma',DATE '2025-02-05');
INSERT INTO FARMER VALUES (8,'Beatrice','Mukashyaka','0788111008','bmukashyaka@gmail.com','1199310010008','Nasho, Kirehe',DATE '2025-02-08');
INSERT INTO FARMER VALUES (9,'Innocent','Habyarimana','0788111009','ihabyarimana@gmail.com','1198910010009','Base, Rulindo',DATE '2025-02-10');
INSERT INTO FARMER VALUES (10,'Diane','Ingabire','0788111010','dingabire@gmail.com','1199410010010','Byumba, Gicumbi',DATE '2025-02-14');
INSERT INTO FARMER VALUES (11,'Eric','Nshimiyimana','0788111011','enshimiyimana@gmail.com','1198710010011','Nyamabuye, Muhanga',DATE '2025-02-18');
INSERT INTO FARMER VALUES (12,'Josiane','Umutoni','0788111012','jumutoni@gmail.com','1199610010012','Bwishyura, Karongi',DATE '2025-03-01');
INSERT INTO FARMER VALUES (13,'Fabrice','Niyonzima','0788111013','fniyonzima@gmail.com','1199110010013','Nyundo, Rubavu',DATE '2025-03-05');
INSERT INTO FARMER VALUES (14,'Grace','Mutesi','0788111014','gmutesi@gmail.com','1199710010014','Kibirizi, Nyamagabe',DATE '2025-03-10');
INSERT INTO FARMER VALUES (15,'Samuel','Bizimana','0788111015','sbizimana@gmail.com','1198410010015','Save, Gisagara',DATE '2025-03-15');

--------------------------------------------------------------------------------
-- EQUIPMENT_CATEGORY (7 rows)
--------------------------------------------------------------------------------
INSERT INTO EQUIPMENT_CATEGORY VALUES (1,'Tractor','Multi-purpose farm tractors for ploughing and hauling');
INSERT INTO EQUIPMENT_CATEGORY VALUES (2,'Irrigation Pump','Water pumping equipment for irrigation');
INSERT INTO EQUIPMENT_CATEGORY VALUES (3,'Drone Sprayer','Aerial spraying drones for pesticide/fertilizer application');
INSERT INTO EQUIPMENT_CATEGORY VALUES (4,'Harvester','Mechanical harvesting equipment');
INSERT INTO EQUIPMENT_CATEGORY VALUES (5,'Sensor Kit','Soil moisture, temperature and humidity monitoring kits');
INSERT INTO EQUIPMENT_CATEGORY VALUES (6,'Plough','Soil tillage implements');
INSERT INTO EQUIPMENT_CATEGORY VALUES (7,'Seeder','Precision seeding and planting equipment');

--------------------------------------------------------------------------------
-- EQUIPMENT_OWNER (8 rows)
--------------------------------------------------------------------------------
INSERT INTO EQUIPMENT_OWNER VALUES (1,'Musanze Farmers Cooperative','0788222001','musanzecoop@gmail.com','COOPERATIVE');
INSERT INTO EQUIPMENT_OWNER VALUES (2,'AgriTech Rwanda Ltd','0788222002','info@agritechrw.com','DEALER');
INSERT INTO EQUIPMENT_OWNER VALUES (3,'Nyagatare Agro Dealers','0788222003','sales@nyagatareagro.rw','DEALER');
INSERT INTO EQUIPMENT_OWNER VALUES (4,'Jean Claude Rukundo','0788222004','jcrukundo@gmail.com','INDIVIDUAL');
INSERT INTO EQUIPMENT_OWNER VALUES (5,'Huye Equipment Cooperative','0788222005','huyecoop@gmail.com','COOPERATIVE');
INSERT INTO EQUIPMENT_OWNER VALUES (6,'Eastern Province AgriMachines Ltd','0788222006','contact@epagrimachines.rw','DEALER');
INSERT INTO EQUIPMENT_OWNER VALUES (7,'Marie Grace Uwera','0788222007','mguwera@gmail.com','INDIVIDUAL');
INSERT INTO EQUIPMENT_OWNER VALUES (8,'Kigali Smart Farm Solutions','0788222008','hello@smartfarmkgl.com','DEALER');

--------------------------------------------------------------------------------
-- TECHNICIAN (6 rows)
--------------------------------------------------------------------------------
INSERT INTO TECHNICIAN VALUES (1,'David Habimana','0788333001','Tractor engines');
INSERT INTO TECHNICIAN VALUES (2,'Alphonsine Mukamurenzi','0788333002','Irrigation systems');
INSERT INTO TECHNICIAN VALUES (3,'Robert Kagabo','0788333003','Drone electronics');
INSERT INTO TECHNICIAN VALUES (4,'Chantal Nyirahabimana','0788333004','Sensor calibration');
INSERT INTO TECHNICIAN VALUES (5,'Placide Bizimana','0788333005','General mechanics');
INSERT INTO TECHNICIAN VALUES (6,'Yvonne Mukandayisenga','0788333006','Harvester maintenance');

--------------------------------------------------------------------------------
-- PUBLIC_HOLIDAY (10 rows - Rwanda 2026)
--------------------------------------------------------------------------------
INSERT INTO PUBLIC_HOLIDAY VALUES (1,DATE '2026-01-01','New Year''s Day');
INSERT INTO PUBLIC_HOLIDAY VALUES (2,DATE '2026-01-02','Day after New Year');
INSERT INTO PUBLIC_HOLIDAY VALUES (3,DATE '2026-02-01','Heroes'' Day');
INSERT INTO PUBLIC_HOLIDAY VALUES (4,DATE '2026-04-03','Good Friday');
INSERT INTO PUBLIC_HOLIDAY VALUES (5,DATE '2026-04-07','Genocide Memorial Day');
INSERT INTO PUBLIC_HOLIDAY VALUES (6,DATE '2026-05-01','Labour Day');
INSERT INTO PUBLIC_HOLIDAY VALUES (7,DATE '2026-07-01','Independence Day');
INSERT INTO PUBLIC_HOLIDAY VALUES (8,DATE '2026-07-04','Liberation Day');
INSERT INTO PUBLIC_HOLIDAY VALUES (9,DATE '2026-08-15','Assumption Day');
INSERT INTO PUBLIC_HOLIDAY VALUES (10,DATE '2026-12-25','Christmas Day');

--------------------------------------------------------------------------------
-- FARM (18 rows)
--------------------------------------------------------------------------------
INSERT INTO FARM VALUES (1,1,'Kinigi Sector, Musanze',2.5,'Volcanic');
INSERT INTO FARM VALUES (2,1,'Shingiro Sector, Musanze',1.2,'Volcanic');
INSERT INTO FARM VALUES (3,2,'Rwimiyaga, Nyagatare',5.0,'Sandy loam');
INSERT INTO FARM VALUES (4,3,'Tumba, Huye',1.8,'Clay');
INSERT INTO FARM VALUES (5,4,'Fumbwe, Rwamagana',3.2,'Loam');
INSERT INTO FARM VALUES (6,5,'Nyamata, Bugesera',4.0,'Sandy');
INSERT INTO FARM VALUES (7,6,'Mukarange, Kayonza',2.2,'Loam');
INSERT INTO FARM VALUES (8,7,'Kibungo, Ngoma',1.5,'Clay loam');
INSERT INTO FARM VALUES (9,8,'Nasho, Kirehe',6.0,'Sandy');
INSERT INTO FARM VALUES (10,9,'Base, Rulindo',1.0,'Volcanic');
INSERT INTO FARM VALUES (11,10,'Byumba, Gicumbi',2.8,'Loam');
INSERT INTO FARM VALUES (12,11,'Nyamabuye, Muhanga',1.6,'Clay');
INSERT INTO FARM VALUES (13,12,'Bwishyura, Karongi',2.0,'Volcanic');
INSERT INTO FARM VALUES (14,13,'Nyundo, Rubavu',1.4,'Volcanic');
INSERT INTO FARM VALUES (15,14,'Kibirizi, Nyamagabe',3.5,'Clay loam');
INSERT INTO FARM VALUES (16,15,'Save, Gisagara',2.6,'Loam');
INSERT INTO FARM VALUES (17,2,'Karangazi, Nyagatare',3.0,'Sandy');
INSERT INTO FARM VALUES (18,5,'Ruhuha, Bugesera',2.0,'Sandy loam');

--------------------------------------------------------------------------------
-- CROP (20 rows) - includes perennials and still-growing crops (harvest_date NULL)
--------------------------------------------------------------------------------
INSERT INTO CROP VALUES (1,1,'Irish Potatoes',DATE '2026-02-01',DATE '2026-05-15','A');
INSERT INTO CROP VALUES (2,1,'Maize',DATE '2026-09-01',NULL,'C');
INSERT INTO CROP VALUES (3,2,'Beans',DATE '2026-02-10',DATE '2026-04-20','A');
INSERT INTO CROP VALUES (4,4,'Maize',DATE '2026-02-15',DATE '2026-06-01','A');
INSERT INTO CROP VALUES (5,5,'Rice',DATE '2026-01-20',DATE '2026-06-10','A');
INSERT INTO CROP VALUES (6,6,'Cassava',DATE '2025-08-01',DATE '2026-06-01','B');
INSERT INTO CROP VALUES (7,7,'Sorghum',DATE '2026-02-05',DATE '2026-05-30','A');
INSERT INTO CROP VALUES (8,8,'Tomatoes',DATE '2026-03-01',DATE '2026-05-15','A');
INSERT INTO CROP VALUES (9,9,'Beans',DATE '2026-02-12',DATE '2026-04-25','A');
INSERT INTO CROP VALUES (10,9,'Maize',DATE '2026-09-10',NULL,'C');
INSERT INTO CROP VALUES (11,10,'Irish Potatoes',DATE '2026-02-20',DATE '2026-05-25','A');
INSERT INTO CROP VALUES (12,11,'Coffee',DATE '2020-01-01',NULL,'B');
INSERT INTO CROP VALUES (13,12,'Tea',DATE '2018-01-01',NULL,'B');
INSERT INTO CROP VALUES (14,13,'Banana',DATE '2019-06-01',NULL,'B');
INSERT INTO CROP VALUES (15,14,'Maize',DATE '2026-02-18',DATE '2026-06-05','A');
INSERT INTO CROP VALUES (16,15,'Beans',DATE '2026-02-22',DATE '2026-04-30','A');
INSERT INTO CROP VALUES (17,16,'Sorghum',DATE '2026-02-08',DATE '2026-05-28','A');
INSERT INTO CROP VALUES (18,17,'Rice',DATE '2026-01-25',DATE '2026-06-15','A');
INSERT INTO CROP VALUES (19,18,'Cassava',DATE '2025-09-01',DATE '2026-07-01','B');
INSERT INTO CROP VALUES (20,3,'Maize',DATE '2026-09-05',NULL,'C');

--------------------------------------------------------------------------------
-- EQUIPMENT (20 rows) - includes MAINTENANCE and RETIRED edge cases
--------------------------------------------------------------------------------
INSERT INTO EQUIPMENT VALUES (1,1,1,'Kubota L3901 Tractor','L3901',45000,'AVAILABLE',DATE '2022-03-01');
INSERT INTO EQUIPMENT VALUES (2,1,2,'Massey Ferguson 240','MF240',50000,'RENTED',DATE '2021-06-15');
INSERT INTO EQUIPMENT VALUES (3,2,2,'Honda WB30 Irrigation Pump','WB30',15000,'AVAILABLE',DATE '2023-01-10');
INSERT INTO EQUIPMENT VALUES (4,2,3,'Briggs Stratton Pump Set','BS-450',12000,'MAINTENANCE',DATE '2020-05-20');
INSERT INTO EQUIPMENT VALUES (5,3,8,'DJI Agras T30 Sprayer Drone','T30',60000,'RENTED',DATE '2023-08-01');
INSERT INTO EQUIPMENT VALUES (6,3,8,'XAG P100 Drone','P100',65000,'AVAILABLE',DATE '2024-01-15');
INSERT INTO EQUIPMENT VALUES (7,4,6,'John Deere Mini Combine','JD-Mini',80000,'AVAILABLE',DATE '2022-11-01');
INSERT INTO EQUIPMENT VALUES (8,4,6,'Claas Harvester Model C','Claas-C',85000,'RETIRED',DATE '2016-02-01');
INSERT INTO EQUIPMENT VALUES (9,5,8,'SoilSense Pro Kit','SS-Pro',8000,'AVAILABLE',DATE '2024-03-01');
INSERT INTO EQUIPMENT VALUES (10,5,8,'AgriMonitor IoT Kit','AM-IoT',9000,'RENTED',DATE '2024-05-10');
INSERT INTO EQUIPMENT VALUES (11,6,1,'Disc Plough Heavy Duty','DP-HD',10000,'AVAILABLE',DATE '2021-09-01');
INSERT INTO EQUIPMENT VALUES (12,6,5,'Mouldboard Plough Set','MP-Set',9500,'AVAILABLE',DATE '2022-02-15');
INSERT INTO EQUIPMENT VALUES (13,7,5,'Precision Seed Drill','PSD-1',20000,'AVAILABLE',DATE '2023-04-01');
INSERT INTO EQUIPMENT VALUES (14,1,4,'New Holland TT75','TT75',48000,'RENTED',DATE '2021-12-01');
INSERT INTO EQUIPMENT VALUES (15,2,3,'Solar Irrigation Pump Kit','SIP-Kit',18000,'AVAILABLE',DATE '2023-06-01');
INSERT INTO EQUIPMENT VALUES (16,3,2,'AgroDrone Mini Sprayer','AD-Mini',55000,'MAINTENANCE',DATE '2023-10-01');
INSERT INTO EQUIPMENT VALUES (17,4,7,'Compact Rice Harvester','CRH-1',75000,'AVAILABLE',DATE '2022-07-01');
INSERT INTO EQUIPMENT VALUES (18,5,4,'WeatherLink Farm Sensor','WL-Sensor',8500,'AVAILABLE',DATE '2024-02-01');
INSERT INTO EQUIPMENT VALUES (19,6,1,'Chisel Plough','CP-1',9000,'RETIRED',DATE '2015-01-01');
INSERT INTO EQUIPMENT VALUES (20,7,6,'Row Crop Planter','RCP-1',22000,'RENTED',DATE '2023-03-01');

--------------------------------------------------------------------------------
-- BOOKING (20 rows)
-- NOTE: booking_id 3 and 4 deliberately book the SAME equipment (5) over
-- OVERLAPPING dates (Jun 10-15 vs Jun 13-18). This is intentional test data
-- for the Phase VI conflict-checking procedure and Phase VII trigger -- the
-- conflict rule does not exist yet at the table level, so this insert is
-- expected to succeed now and should be CAUGHT later by application logic.
--------------------------------------------------------------------------------
INSERT INTO BOOKING VALUES (1,1,1,DATE '2026-03-01',DATE '2026-03-05','CONFIRMED',DATE '2026-02-25');
INSERT INTO BOOKING VALUES (2,2,2,DATE '2026-02-10',DATE '2026-02-14','COMPLETED',DATE '2026-02-05');
INSERT INTO BOOKING VALUES (3,3,5,DATE '2026-06-10',DATE '2026-06-15','CONFIRMED',DATE '2026-06-01');
INSERT INTO BOOKING VALUES (4,8,5,DATE '2026-06-13',DATE '2026-06-18','CONFIRMED',DATE '2026-06-02');
INSERT INTO BOOKING VALUES (5,4,7,DATE '2026-05-01',DATE '2026-05-03','COMPLETED',DATE '2026-04-25');
INSERT INTO BOOKING VALUES (6,5,9,DATE '2026-04-01',DATE '2026-04-10','CONFIRMED',DATE '2026-03-28');
INSERT INTO BOOKING VALUES (7,6,11,DATE '2026-03-15',DATE '2026-03-17','COMPLETED',DATE '2026-03-10');
INSERT INTO BOOKING VALUES (8,7,13,DATE '2026-02-20',DATE '2026-02-25','COMPLETED',DATE '2026-02-15');
INSERT INTO BOOKING VALUES (9,9,3,DATE '2026-03-05',DATE '2026-03-08','CONFIRMED',DATE '2026-03-01');
INSERT INTO BOOKING VALUES (10,10,15,DATE '2026-04-15',DATE '2026-04-20','PENDING',DATE '2026-04-10');
INSERT INTO BOOKING VALUES (11,11,17,DATE '2026-05-10',DATE '2026-05-12','CONFIRMED',DATE '2026-05-05');
INSERT INTO BOOKING VALUES (12,12,18,DATE '2026-03-25',DATE '2026-04-05','CONFIRMED',DATE '2026-03-20');
INSERT INTO BOOKING VALUES (13,13,20,DATE '2026-02-01',DATE '2026-02-10','COMPLETED',DATE '2026-01-28');
INSERT INTO BOOKING VALUES (14,14,12,DATE '2026-03-20',DATE '2026-03-22','COMPLETED',DATE '2026-03-15');
INSERT INTO BOOKING VALUES (15,15,6,DATE '2026-06-01',DATE '2026-06-04','CONFIRMED',DATE '2026-05-25');
INSERT INTO BOOKING VALUES (16,1,10,DATE '2026-05-15',DATE '2026-05-20','CONFIRMED',DATE '2026-05-10');
INSERT INTO BOOKING VALUES (17,2,14,DATE '2026-02-15',DATE '2026-02-28','COMPLETED',DATE '2026-02-10');
INSERT INTO BOOKING VALUES (18,3,2,DATE '2026-07-01',DATE '2026-07-05','PENDING',DATE '2026-06-25');
INSERT INTO BOOKING VALUES (19,6,9,DATE '2026-04-08',DATE '2026-04-12','CANCELLED',DATE '2026-04-01');
INSERT INTO BOOKING VALUES (20,8,19,DATE '2026-01-05',DATE '2026-01-06','CANCELLED',DATE '2026-01-02');

--------------------------------------------------------------------------------
-- PAYMENT (20 rows, 1:1 with BOOKING) - includes UNPAID and REFUNDED edge cases
--------------------------------------------------------------------------------
INSERT INTO PAYMENT VALUES (1,1,225000,DATE '2026-03-01','MOBILE_MONEY','PAID');
INSERT INTO PAYMENT VALUES (2,2,200000,DATE '2026-02-10','CASH','PAID');
INSERT INTO PAYMENT VALUES (3,3,300000,DATE '2026-06-10','MOBILE_MONEY','PAID');
INSERT INTO PAYMENT VALUES (4,4,300000,DATE '2026-06-13','BANK_TRANSFER','PAID');
INSERT INTO PAYMENT VALUES (5,5,240000,DATE '2026-05-01','CASH','PAID');
INSERT INTO PAYMENT VALUES (6,6,72000,DATE '2026-04-01','MOBILE_MONEY','PAID');
INSERT INTO PAYMENT VALUES (7,7,20000,DATE '2026-03-15','CASH','PAID');
INSERT INTO PAYMENT VALUES (8,8,100000,DATE '2026-02-20','MOBILE_MONEY','PAID');
INSERT INTO PAYMENT VALUES (9,9,45000,NULL,NULL,'UNPAID');
INSERT INTO PAYMENT VALUES (10,10,90000,NULL,NULL,'UNPAID');
INSERT INTO PAYMENT VALUES (11,11,150000,DATE '2026-05-10','BANK_TRANSFER','PAID');
INSERT INTO PAYMENT VALUES (12,12,93500,DATE '2026-03-25','MOBILE_MONEY','PAID');
INSERT INTO PAYMENT VALUES (13,13,220000,DATE '2026-02-01','CASH','PAID');
INSERT INTO PAYMENT VALUES (14,14,19000,DATE '2026-03-20','MOBILE_MONEY','PAID');
INSERT INTO PAYMENT VALUES (15,15,260000,DATE '2026-06-01','BANK_TRANSFER','PAID');
INSERT INTO PAYMENT VALUES (16,16,45000,DATE '2026-05-15','MOBILE_MONEY','PAID');
INSERT INTO PAYMENT VALUES (17,17,624000,DATE '2026-02-15','CASH','PAID');
INSERT INTO PAYMENT VALUES (18,18,250000,NULL,NULL,'UNPAID');
INSERT INTO PAYMENT VALUES (19,19,72000,DATE '2026-04-02','MOBILE_MONEY','REFUNDED');
INSERT INTO PAYMENT VALUES (20,20,9000,DATE '2026-01-03','CASH','REFUNDED');

--------------------------------------------------------------------------------
-- MAINTENANCE_RECORD (15 rows) - includes overdue/pending service edge cases
--------------------------------------------------------------------------------
INSERT INTO MAINTENANCE_RECORD VALUES (1,2,1,DATE '2026-01-15','Engine oil change and filter replacement',25000);
INSERT INTO MAINTENANCE_RECORD VALUES (2,4,2,DATE '2026-06-20','Pump seal replacement - currently in progress',40000);
INSERT INTO MAINTENANCE_RECORD VALUES (3,5,3,DATE '2026-02-01','Battery and rotor calibration',30000);
INSERT INTO MAINTENANCE_RECORD VALUES (4,7,6,DATE '2025-11-10','Blade sharpening and belt replacement',55000);
INSERT INTO MAINTENANCE_RECORD VALUES (5,8,6,DATE '2019-03-01','Last recorded service before retirement',20000);
INSERT INTO MAINTENANCE_RECORD VALUES (6,10,4,DATE '2026-03-05','Sensor firmware update',5000);
INSERT INTO MAINTENANCE_RECORD VALUES (7,14,1,DATE '2025-12-01','Clutch adjustment',35000);
INSERT INTO MAINTENANCE_RECORD VALUES (8,16,3,DATE '2026-06-25','Nozzle replacement - currently in progress',18000);
INSERT INTO MAINTENANCE_RECORD VALUES (9,19,5,DATE '2018-06-01','Final service before retirement',12000);
INSERT INTO MAINTENANCE_RECORD VALUES (10,1,1,DATE '2025-09-01','Routine 500-hour service',22000);
INSERT INTO MAINTENANCE_RECORD VALUES (11,3,2,DATE '2026-01-20','Hose replacement',8000);
INSERT INTO MAINTENANCE_RECORD VALUES (12,11,5,DATE '2025-10-15','Disc sharpening',6000);
INSERT INTO MAINTENANCE_RECORD VALUES (13,13,5,DATE '2026-02-10','Calibration of seed spacing mechanism',15000);
INSERT INTO MAINTENANCE_RECORD VALUES (14,17,6,DATE '2024-12-01','Overdue annual service - not yet rescheduled',NULL);
INSERT INTO MAINTENANCE_RECORD VALUES (15,20,1,DATE '2026-05-01','Planter tine replacement',27000);

--------------------------------------------------------------------------------
-- SENSOR_READING (25 rows) - includes drought-stress and waterlogging edge cases
--------------------------------------------------------------------------------
INSERT INTO SENSOR_READING VALUES (1,1,1,TIMESTAMP '2026-03-01 08:00:00',42.5,22.1,65);
INSERT INTO SENSOR_READING VALUES (2,1,1,TIMESTAMP '2026-03-05 08:00:00',38.0,23.4,60);
INSERT INTO SENSOR_READING VALUES (3,1,2,TIMESTAMP '2026-09-10 08:00:00',55.0,19.8,70);
INSERT INTO SENSOR_READING VALUES (4,1,NULL,TIMESTAMP '2026-01-15 08:00:00',30.0,20.0,55);
INSERT INTO SENSOR_READING VALUES (5,4,4,TIMESTAMP '2026-03-10 07:30:00',45.2,24.0,68);
INSERT INTO SENSOR_READING VALUES (6,5,5,TIMESTAMP '2026-02-20 08:00:00',60.5,21.3,75);
INSERT INTO SENSOR_READING VALUES (7,6,6,TIMESTAMP '2026-04-01 08:00:00',12.0,34.5,30);
INSERT INTO SENSOR_READING VALUES (8,7,7,TIMESTAMP '2026-03-15 08:00:00',40.0,23.0,62);
INSERT INTO SENSOR_READING VALUES (9,8,8,TIMESTAMP '2026-03-20 08:00:00',50.0,22.5,66);
INSERT INTO SENSOR_READING VALUES (10,9,9,TIMESTAMP '2026-03-01 08:00:00',35.5,24.8,58);
INSERT INTO SENSOR_READING VALUES (11,9,NULL,TIMESTAMP '2026-08-01 08:00:00',25.0,26.0,45);
INSERT INTO SENSOR_READING VALUES (12,10,11,TIMESTAMP '2026-03-05 08:00:00',48.0,20.5,70);
INSERT INTO SENSOR_READING VALUES (13,11,12,TIMESTAMP '2026-06-01 08:00:00',55.0,18.9,80);
INSERT INTO SENSOR_READING VALUES (14,12,13,TIMESTAMP '2026-06-01 08:00:00',60.0,17.5,82);
INSERT INTO SENSOR_READING VALUES (15,13,14,TIMESTAMP '2026-06-01 08:00:00',58.0,19.0,78);
INSERT INTO SENSOR_READING VALUES (16,14,15,TIMESTAMP '2026-03-10 08:00:00',33.0,25.2,55);
INSERT INTO SENSOR_READING VALUES (17,15,16,TIMESTAMP '2026-03-12 08:00:00',41.0,23.7,63);
INSERT INTO SENSOR_READING VALUES (18,16,17,TIMESTAMP '2026-03-14 08:00:00',44.0,22.9,64);
INSERT INTO SENSOR_READING VALUES (19,17,18,TIMESTAMP '2026-02-25 08:00:00',62.0,20.1,77);
INSERT INTO SENSOR_READING VALUES (20,18,19,TIMESTAMP '2026-03-18 08:00:00',37.0,24.1,59);
INSERT INTO SENSOR_READING VALUES (21,6,6,TIMESTAMP '2026-04-05 14:00:00',8.5,36.2,22);
INSERT INTO SENSOR_READING VALUES (22,2,3,TIMESTAMP '2026-03-02 08:00:00',46.0,21.8,67);
INSERT INTO SENSOR_READING VALUES (23,3,20,TIMESTAMP '2026-09-08 08:00:00',29.0,24.5,50);
INSERT INTO SENSOR_READING VALUES (24,8,8,TIMESTAMP '2026-05-01 15:00:00',5.0,38.0,18);
INSERT INTO SENSOR_READING VALUES (25,7,7,TIMESTAMP '2026-05-20 06:00:00',95.0,16.5,96);

--------------------------------------------------------------------------------
-- AUDIT_LOG left empty on purpose -- Phase VII triggers will populate this
-- table automatically whenever INSERT/UPDATE/DELETE occurs on audited tables.
-- Seeding it manually now would just be fake data unrelated to real changes.
--------------------------------------------------------------------------------

COMMIT;

--------------------------------------------------------------------------------
-- End of Phase V: INSERT Sample Data
--------------------------------------------------------------------------------
