create database pharma;
use pharma;
	Create  table  Medicine(medicine_id varchar(6), medicine_name varchar(20), category varchar(20),
    price_per_unit int, stock_quantity int, expiry_date date);
    
Create  table  doctor(doctor_id varchar(6), name varchar(20), specialization varchar(20), hospital_name varchar(20));

Create  table  patient(patient_id varchar(6), name varchar(20), gender varchar(16), dob date, city varchar(60));

Create  table  prescription(prescription_id varchar(6), doctor_id varchar(6), patient_id varchar(6), prescription_date date, diagnosis varchar(60 ));

Create  table  prescription_detail(prescription_detail_id varchar(6), prescription_id varchar(6), medicine_id varchar(6), dosage varchar(60), duration int);
    
    Create  table  sales(sale_id varchar(6), patient_id varchar(6), medicine_id varchar(6), quantity int, sale_date date, payment_method varchar(60));

Create  table  suppliers(supplier_id varchar(6), supplier_name varchar(60), contact_number int, location varchar(60));

insert into Medicine values("M001","Paracetamol","Analgesic"	,1.50	,200,"2026-03-15"),
("M002","Amoxicillin","	Antibiotic",	3.20,	150,	"2025-12-01"),
("M003"	,"Cetirizine","Antihistamine	",2.00	,80	,"2024-11-30"),
("M004","	Metformin","	Antidiabetic ",5.00,	50,"2027-05-20"),
("M005","	Ibuprofen","	Analgesic	",1.75	,0,	"2024-08-01");

insert into doctor values("D101","	Dr. Anjali Verma","	General	","City Care Hospital"),
("D102","Dr. Rakesh Nair","	Pediatrics","	Rainbow Clinic"),
("D103","	Dr. Kavita Shah","	ENT	","Health  Hospital");

insert into patient values("P001","	Rohit Mehra","	Male","	1985-06-15","Delhi"),
("P002","Neha Sharma","Female","1992-09-21","Mumbai"),
("P003","Suresh Iyer","Male	","1978-12-03","Bengaluru");


insert into prescription values("PR001","	D101","	P001","2024-10-12","	Fever"),
("PR002","	D102","P002","	2024-11-05","Cold"),
("PR003	","D101	","P003","2025-01-18","	Diabetes");

insert into prescription_detail values("PD001","	PR001","	M001","	2 tablets/day",	5),
("PD002","	PR002	","M003	","1 tablet/day",	3),
("PD003	","PR003","	M004","	1 tablet/day",	30);
select * from prescription_detail;

insert into suppliers values("S001","Medico Distributors",	20204	,"Mumbai"),
("S002","HealthPlus Pharma",	202025	,"Delhi"),
("S003","LifeCare Suppliers	",15152,"	Bengaluru"),
("S004","Apollo Wholesalers	",0515,"Chennai"),
("S005","Zenith Pharma Corp",	15541	,"Hyderabad");



use pharma;
select * from doctor;
#1	List medicines that are below minimum stock level (e.g., stock_quantity < 10
select * from medicine;
select medicine_name from medicine where stock_quantity<10 ;

#2.	Identify medicines that have expired as of today.
select * from medicine where expiry_date<current_date() ;


#3 	Retrieve the top 3 most sold medicines by total quantity.
select medicine_id ,sum(quantity) as total_quantity from sales group by medicine_id  limit 3;

#4.	Calculate total revenue generated per medicine.
SELECT medicine_id, SUM(quantity * price_per_unit) AS total_revenue
FROM sales
JOIN medicine USING(medicine_id)
GROUP BY medicine_id;


#5.	Number of distinct patients each doctor has treated
select doctor_id,count(patient_id) as patients from prescription group by doctor_id;

#6.	Daily sales totals for the last 30 days:
SELECT sale_date, SUM(quantity * price_per_unit) AS daily_total
FROM sales
JOIN medicine USING(medicine_id)
WHERE sale_date >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY sale_date
ORDER BY sale_date;

# 7.	Medicines never sold but were prescribed:
select prescription_detail. medicine_id  from prescription_detail left join sales on prescription_detail.medicine_id =sales.medicine_id
where sales.medicine_id is null;

#8.	Retrieve the number of prescriptions issued by each doctor in the last 6 months.
select doctor_id ,count(*) from prescription where prescription_date>=current_date-interval 6 month group by doctor_id;

#9.	Medicines that are sold but never prescribed
select sales.medicine_id from sales left join prescription_detail on Sales.medicine_id =prescription_detail.medicine_id
where prescription_detail.medicine_id is null;
#10.	Prescriptions with more than 3 different medicines:
select prescription_id from precription_details group by prescription_id having count(medicine_id) >3;

#11.	Patients who purchased medicines from more than one city
select patient_id from(select sales.patient_id,count(patient.city)as city_count from sales join patient on sales.patient_id=patient.patient_id
group by sales.patient_id)as sub;

#14.	Total quantity of each medicine sold in each city:
SELECT patient.city, sales.medicine_id, SUM(sales.quantity) AS total_quantity
FROM Sales 
JOIN patient  ON sales.patient_id = patient.patient_id
GROUP BY Patient.city, sales.medicine_id;

#15.	Doctors who have never prescribed any medicine:
select d.doctor_id, d.name from doctor d left join prescription pr ON d.doctor_id = pr.doctor_id
left join prescription_detail pd ON pr.prescription_id = pd.prescription_id
where pd.prescription_detail_id is null;

#16.	Medicines prescribed and sold on the same day to the same patient:
SELECT  s.patient_id, s.medicine_id, s.sale_date
FROM sales s
JOIN prescription pr ON s.patient_id = pr.patient_id AND s.sale_date = pr.prescription_date
JOIN prescription_detail pd ON pr.prescription_id = pd.prescription_id AND pd.medicine_id = s.medicine_id;

#17.	Patients who purchased medicine more than 15 days after it was prescribed:
SELECT DISTINCT s.patient_id, s.medicine_id
FROM Sales s
JOIN prescription pr ON s.patient_id = pr.patient_id
JOIN prescription_detail pd ON pr.prescription_id = pd.prescription_id AND s.medicine_id = pd.medicine_id
WHERE DATEDIFF(s.sale_date, pr.prescription_date) > 15;

#18.	Doctors who prescribed the most medicines overall:
SELECT doctor_id, COUNT(pd.medicine_id) AS total_medicines
FROM prescription pr
JOIN prescription_detail pd ON pr.prescription_id = pd.prescription_id
GROUP BY doctor_id
ORDER BY total_medicines DESC
LIMIT 1;

#19.	Patients who purchased a medicine not prescribed to them:
SELECT  s.patient_id, s.medicine_id
FROM sales s
LEFT JOIN (
    SELECT p.patient_id, pd.medicine_id
    FROM prescription p
    JOIN prescription_detail pd ON p.prescription_id = pd.prescription_id
) pm ON s.patient_id = pm.patient_id AND s.medicine_id = pm.medicine_id
WHERE pm.medicine_id IS NULL;

##=======================triggers===
#1.	Trigger to reduce stock after sale:
delimiter //
CREATE TRIGGER reduce_stock
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    UPDATE medicine
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE medicine_id = NEW.medicine_id;
END //
delimiter ;

#2.	Trigger to update last prescribed date:
delimiter //
ALTER TABLE medicine ADD COLUMN last_prescribed_date DATE;

CREATE TRIGGER update_last_prescribed
AFTER INSERT ON prescription_detail
FOR EACH ROW
BEGIN
    UPDATE medicine
    SET last_prescribed_date = CURRENT_DATE
    WHERE medicine_id = NEW.medicine_id;
END //
delimiter ;


#3.	Trigger to insert restock alert when stock < 10:
delimiter //
CREATE TRIGGER restock_alert
AFTER UPDATE ON medicine
FOR EACH ROW
BEGIN
    IF NEW.stock_quantity < 10 THEN
        INSERT INTO Restock_Alerts (alert_id, medicine_id, alert_date, note)
        VALUES (UUID(), NEW.medicine_id, CURRENT_DATE, 'Stock is below threshold');
    END IF;
end //
delimiter;

#5.	Procedure to generate bill for a patient:
DELIMITER //

CREATE PROCEDURE GenerateBill(IN patientId VARCHAR(10), IN billDate DATE)
BEGIN
    SELECT s.medicine_id, m.medicine_name, s.quantity, m.price_per_unit, 
           (s.quantity * m.price_per_unit) AS total_price
    FROM Sales s
    JOIN medicine m ON s.medicine_id = m.medicine_id
    WHERE s.patient_id = patientId AND s.sale_date = billDate;
END //

DELIMITER ;

#6.	Procedure to return patients per doctor with total prescriptions:
DELIMITER //

CREATE PROCEDURE get_pateint_by_doc(IN doc_id VARCHAR(10))
BEGIN
    SELECT p.patient_id, p.name, COUNT(pr.prescription_id) AS total_prescriptions
    FROM Patients p
    JOIN prescription pr ON pr.patient_id = p.patient_id
    WHERE pr.doctor_id = doc_id
    GROUP BY p.patient_id;
END //

DELIMITER ;
#7.	Procedure to expire medicines:


delimiter //

CREATE PROCEDURE ExpireMedicines()
BEGIN
    INSERT INTO Expired_Stock SELECT * FROM medicine WHERE expiry_date < CURRENT_DATE;
    DELETE FROM medicine WHERE expiry_date < CURRENT_DATE;
END //

delimiter ;
#8.	Procedure for sales summary by date range and category:
DELIMITER //

CREATE PROCEDURE salesSummary(IN startDate DATE, IN endDate DATE, IN category VARCHAR(50))
BEGIN
    SELECT s.medicine_id, SUM(s.quantity) AS total_quantity, SUM(s.quantity * m.price_per_unit) AS total_revenue
    FROM Sales s
    JOIN medicine m ON s.medicine_id = m.medicine_id
    WHERE s.sale_date BETWEEN startDate AND endDate AND m.category = category
    GROUP BY s.medicine_id;
END //

DELIMITER ;




