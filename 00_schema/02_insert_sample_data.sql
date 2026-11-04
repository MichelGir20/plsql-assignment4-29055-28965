-- =====================================================================
-- File    : 00_schema/02_insert_sample_data.sql
-- Purpose : Sample data (departments, students, courses, enrollments)
-- Note    : grade_letter is hard-coded here because the grading function
--           is compiled AFTER this script. Scale: A>=90, B>=80, C>=70,
--           D>=60, F<60 (same as calc_letter_grade).
-- =====================================================================

-- Departments
INSERT INTO departments (dept_id, dept_name) VALUES (10, 'Information Systems');
INSERT INTO departments (dept_id, dept_name) VALUES (20, 'Software Engineering');
INSERT INTO departments (dept_id, dept_name) VALUES (30, 'Networks and Security');
INSERT INTO departments (dept_id, dept_name) VALUES (40, 'Business Administration');

-- Students (30012 is SUSPENDED, 30015 is GRADUATED; 30001 and 30003
-- share the last name Uwase on purpose, to demonstrate TOO_MANY_ROWS)
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30001, 'Aline',     'Uwase',       'aline.uwase@student.auca.ac.rw',       10, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30002, 'Eric',      'Mugisha',     'eric.mugisha@student.auca.ac.rw',      10, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30003, 'Grace',     'Uwase',       'grace.uwase@student.auca.ac.rw',       20, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30004, 'Jean',      'Niyonzima',   'jean.niyonzima@student.auca.ac.rw',    20, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30005, 'Diane',     'Ingabire',    'diane.ingabire@student.auca.ac.rw',    30, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30006, 'Patrick',   'Habimana',    'patrick.habimana@student.auca.ac.rw',  30, DATE '2025-01-13', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30007, 'Sandrine',  'Mukamana',    'sandrine.mukamana@student.auca.ac.rw', 10, DATE '2025-01-13', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30008, 'Olivier',   'Nshuti',      'olivier.nshuti@student.auca.ac.rw',    20, DATE '2025-01-13', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30009, 'Claudine',  'Umutoni',     'claudine.umutoni@student.auca.ac.rw',  40, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30010, 'David',     'Kamanzi',     'david.kamanzi@student.auca.ac.rw',     40, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30011, 'Esther',    'Mutesi',      'esther.mutesi@student.auca.ac.rw',     10, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30012, 'Fabrice',   'Bizimana',    'fabrice.bizimana@student.auca.ac.rw',  20, DATE '2025-09-01', 'SUSPENDED');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30013, 'Joyce',     'Iradukunda',  'joyce.iradukunda@student.auca.ac.rw',  30, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30014, 'Kevin',     'Rugamba',     'kevin.rugamba@student.auca.ac.rw',     30, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (30015, 'Laetitia',  'Mukeshimana', 'laetitia.mukeshimana@student.auca.ac.rw', 10, DATE '2022-09-05', 'GRADUATED');

-- Courses (106 has only 3 seats so "course full" can be demonstrated)
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, max_capacity)
VALUES (101, 'INSY8311', 'Database Development with PL/SQL', 3, 10, 40);
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, max_capacity)
VALUES (102, 'INSY8211', 'Systems Analysis and Design',      3, 10, 40);
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, max_capacity)
VALUES (103, 'SENG8101', 'Software Engineering',            4, 20, 35);
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, max_capacity)
VALUES (104, 'NETW8201', 'Computer Networks',               3, 30, 35);
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, max_capacity)
VALUES (105, 'BUSA8001', 'Business Communication',          2, 40, 30);
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, max_capacity)
VALUES (106, 'INSY8399', 'Capstone Seminar',                2, 10, 3);

-- Spring 2026: completed, graded enrollments (history for GPA / transcript)
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30001, 102, 'Spring2026', 92,   'A', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30001, 103, 'Spring2026', 85.5, 'B', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30002, 102, 'Spring2026', 78,   'C', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30002, 104, 'Spring2026', 64,   'D', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30003, 103, 'Spring2026', 55,   'F', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30003, 105, 'Spring2026', 88,   'B', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30004, 104, 'Spring2026', 71,   'C', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30004, 102, 'Spring2026', 95,   'A', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30005, 105, 'Spring2026', 69,   'D', DATE '2026-02-02');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30015, 103, 'Spring2026', 81,   'B', DATE '2026-02-02');

-- Fall 2026: current semester. Course 101 has 4 graded and 2 ungraded rows.
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30001, 101, 'Fall2026', 88,   'B', DATE '2026-09-07');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30002, 101, 'Fall2026', 74,   'C', DATE '2026-09-07');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30003, 101, 'Fall2026', 62,   'D', DATE '2026-09-07');
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter, enroll_date) VALUES (30004, 101, 'Fall2026', 91,   'A', DATE '2026-09-07');
INSERT INTO enrollments (student_id, course_id, semester, enroll_date)                      VALUES (30005, 101, 'Fall2026', DATE '2026-09-07');
INSERT INTO enrollments (student_id, course_id, semester, enroll_date)                      VALUES (30006, 101, 'Fall2026', DATE '2026-09-07');

-- Fall 2026: Capstone Seminar is FULL (3 of 3 seats taken)
INSERT INTO enrollments (student_id, course_id, semester, enroll_date) VALUES (30001, 106, 'Fall2026', DATE '2026-09-07');
INSERT INTO enrollments (student_id, course_id, semester, enroll_date) VALUES (30002, 106, 'Fall2026', DATE '2026-09-07');
INSERT INTO enrollments (student_id, course_id, semester, enroll_date) VALUES (30003, 106, 'Fall2026', DATE '2026-09-07');

-- Fall 2026: one more ungraded enrollment elsewhere
INSERT INTO enrollments (student_id, course_id, semester, enroll_date) VALUES (30007, 103, 'Fall2026', DATE '2026-09-07');

COMMIT;

SELECT 'DEPARTMENTS' AS tbl, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'STUDENTS',    COUNT(*) FROM students
UNION ALL SELECT 'COURSES',     COUNT(*) FROM courses
UNION ALL SELECT 'ENROLLMENTS', COUNT(*) FROM enrollments;
