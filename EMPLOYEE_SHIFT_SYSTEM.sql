CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    hire_date DATE,
    hourly_rate DECIMAL(10,2)
);

CREATE TABLE shifts (
    shift_id SERIAL PRIMARY KEY,
    shift_name VARCHAR(50),
    start_time TIME,
    end_time TIME,
    shift_multiplier DECIMAL(3,2)
);

CREATE TABLE shift_assignments (
    assignment_id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES employees(emp_id),
    shift_id INT REFERENCES shifts(shift_id),
    assignment_date DATE
);

CREATE TABLE attendance (
    attendance_id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES employees(emp_id),
    clock_in TIMESTAMP,
    clock_out TIMESTAMP,
    date DATE
);
INSERT INTO employees
(emp_id,name,department,hire_date,hourly_rate)
VALUES
(1,'Rahul Sharma','IT','2023-01-10',500),
(2,'Priya Singh','HR','2023-02-15',450),
(3,'Amit Verma','IT','2023-03-20',550),
(4,'Sneha Gupta','Finance','2023-04-05',600),
(5,'Rohan Kumar','IT','2023-05-12',500),
(6,'Anjali Jain','HR','2023-06-18',470),
(7,'Vikas Mehta','Finance','2023-07-01',620),
(8,'Neha Kapoor','Sales','2023-08-10',480),
(9,'Arjun Malhotra','Sales','2023-09-15',500),
(10,'Pooja Sharma','IT','2023-10-20',530);
INSERT INTO shifts
(shift_id,shift_name,start_time,end_time,shift_multiplier)
VALUES
(1,'Morning','08:00','16:00',1.00),
(2,'Evening','16:00','00:00',1.20),
(3,'Night','00:00','08:00',1.50);
INSERT INTO shift_assignments
(assignment_id,emp_id,shift_id,assignment_date)
VALUES
(1,1,1,'2026-06-01'),
(2,2,2,'2026-06-01'),
(3,3,3,'2026-06-01'),
(4,4,1,'2026-06-01'),
(5,5,2,'2026-06-01'),
(6,6,1,'2026-06-02'),
(7,7,3,'2026-06-02'),
(8,8,2,'2026-06-02'),
(9,9,1,'2026-06-02'),
(10,10,3,'2026-06-02');
INSERT INTO attendance
(attendance_id,emp_id,clock_in,clock_out,date)
VALUES
(1,1,'2026-06-01 08:00','2026-06-01 17:00','2026-06-01'),
(2,2,'2026-06-01 16:00','2026-06-02 01:00','2026-06-01'),
(3,3,'2026-06-01 00:00','2026-06-01 09:00','2026-06-01'),
(4,4,'2026-06-01 08:00','2026-06-01 16:00','2026-06-01'),
(5,5,'2026-06-01 16:00','2026-06-02 00:00','2026-06-01');
SELECT * FROM employees;
SELECT * FROM shifts;
SELECT * FROM shift_assignments;
SELECT * FROM attendance;
CREATE OR REPLACE FUNCTION calculate_payroll(
employee_id INT
)
RETURNS NUMERIC
AS
$$
DECLARE
    total_hours NUMERIC;
    rate NUMERIC;
BEGIN

    SELECT
    SUM(EXTRACT(EPOCH FROM (clock_out-clock_in))/3600)
    INTO total_hours
    FROM attendance
    WHERE emp_id=employee_id;

    SELECT hourly_rate
    INTO rate
    FROM employees
    WHERE emp_id=employee_id;

    RETURN total_hours * rate;

END;
$$
LANGUAGE plpgsql;
SELECT calculate_payroll(1);
CREATE OR REPLACE FUNCTION prevent_duplicate_shift()
RETURNS TRIGGER AS
$$
BEGIN

IF EXISTS
(
SELECT 1
FROM shift_assignments
WHERE emp_id=NEW.emp_id
AND shift_id=NEW.shift_id
AND assignment_date=NEW.assignment_date
)
THEN
RAISE EXCEPTION
'Duplicate shift assignment not allowed';
END IF;

RETURN NEW;

END;
$$
LANGUAGE plpgsql;
CREATE TRIGGER trg_prevent_duplicate_shift
BEFORE INSERT
ON shift_assignments
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_shift();
SELECT
e.emp_id,
e.name,
SUM(EXTRACT(EPOCH FROM
(a.clock_out-a.clock_in))/3600)
AS total_hours
FROM employees e
JOIN attendance a
ON e.emp_id=a.emp_id
GROUP BY e.emp_id,e.name;

SELECT
e.name,
a.date,
EXTRACT(EPOCH FROM
(a.clock_out-a.clock_in))/3600
AS hours_worked
FROM employees e
JOIN attendance a
ON e.emp_id=a.emp_id
WHERE EXTRACT(EPOCH FROM
(a.clock_out-a.clock_in))/3600 > 8;

SELECT
sa1.emp_id,
sa1.assignment_date
FROM shift_assignments sa1
JOIN shift_assignments sa2
ON sa1.emp_id=sa2.emp_id
AND sa1.assignment_date=sa2.assignment_date
AND sa1.assignment_id<>sa2.assignment_id;

SELECT
department,
name,
total_hours,
RANK() OVER
(
PARTITION BY department
ORDER BY total_hours DESC
)
AS rank_in_department
FROM
(
SELECT
e.department,
e.name,
SUM(EXTRACT(EPOCH FROM
(a.clock_out-a.clock_in))/3600)
AS total_hours
FROM employees e
JOIN attendance a
ON e.emp_id=a.emp_id
GROUP BY e.department,e.name
) t;

WITH RECURSIVE week_schedule AS
(
SELECT DATE '2026-06-01' AS work_day

UNION ALL

SELECT work_day + 1
FROM week_schedule
WHERE work_day < DATE '2026-06-07'
)

SELECT *
FROM week_schedule;