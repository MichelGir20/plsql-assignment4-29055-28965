-- =====================================================================
-- File    : 03_tests/test_success_cases.sql
-- Purpose : Successful execution of every procedure and function.
-- Re-run  : The script ends with ROLLBACK, so the sample data is back to
--           its original state and the script can be run again.
-- Screenshot: take one per TEST (name it <test_name>_output.png).
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100

PROMPT
PROMPT ===== TEST S1: register_student_course (user-defined + %ROWTYPE records) =====
DECLARE
  l_enr_id enrollments.enrollment_id%TYPE;
BEGIN
  register_student_course(30007, 101, 'Fall2026', l_enr_id);
  DBMS_OUTPUT.PUT_LINE('OUT parameter o_enrollment_id = ' || l_enr_id);
END;
/

PROMPT
PROMPT ===== TEST S2: record_grade (implicit UPDATE: SQL%FOUND / SQL%ROWCOUNT) =====
DECLARE
  l_enr_id enrollments.enrollment_id%TYPE;
  l_letter VARCHAR2(1);
  l_rows   NUMBER;
BEGIN
  SELECT enrollment_id INTO l_enr_id
    FROM enrollments
   WHERE student_id = 30005 AND course_id = 101 AND semester = 'Fall2026';

  record_grade(l_enr_id, 79.5, l_letter, l_rows);
  DBMS_OUTPUT.PUT_LINE('Letter = ' || l_letter || ', rows updated = ' || l_rows);
END;
/
SELECT audit_id, enrollment_id, old_score, new_score, changed_by FROM grade_audit;

PROMPT
PROMPT ===== TEST S3: drop_enrollment (implicit DELETE) =====
DECLARE
  l_enr_id enrollments.enrollment_id%TYPE;
  l_rows   NUMBER;
BEGIN
  SELECT enrollment_id INTO l_enr_id
    FROM enrollments
   WHERE student_id = 30007 AND course_id = 101 AND semester = 'Fall2026';

  drop_enrollment(l_enr_id, l_rows);
  DBMS_OUTPUT.PUT_LINE('Rows deleted = ' || l_rows);
END;
/

PROMPT
PROMPT ===== TEST S4: find_student_by_lastname (%ROWTYPE OUT parameter) =====
DECLARE
  l_student students%ROWTYPE;
BEGIN
  find_student_by_lastname('Mugisha', l_student);
  DBMS_OUTPUT.PUT_LINE('Found: ' || l_student.student_id || ' ' ||
    l_student.first_name || ' ' || l_student.last_name ||
    ' <' || l_student.email || '> status=' || l_student.status);
END;
/

PROMPT
PROMPT ===== TEST S5: print_course_roster (explicit cursor OPEN/FETCH/CLOSE) =====
BEGIN
  print_course_roster(101, 'Fall2026');
END;
/

PROMPT
PROMPT ===== TEST S6: print_student_transcript (cursor FOR loop + associative array) =====
BEGIN
  print_student_transcript(30001);
END;
/

PROMPT
PROMPT ===== TEST S7: functions called from SQL =====
SELECT student_id, first_name, last_name,
       calc_student_gpa(student_id) AS gpa
  FROM students
 WHERE student_id IN (30001, 30002, 30004)
 ORDER BY student_id;

SELECT e.student_id, e.score, calc_letter_grade(e.score) AS letter_from_function, e.grade_letter AS stored_letter
  FROM enrollments e
 WHERE e.course_id = 101 AND e.semester = 'Fall2026' AND e.score IS NOT NULL
 ORDER BY e.score DESC;

SELECT get_course_enrollment_count(101, 'Fall2026') AS enrolled_in_101,
       get_course_enrollment_count(106, 'Fall2026') AS enrolled_in_106
  FROM dual;

PROMPT
PROMPT ===== TEST S8: get_top_students (collection returned by a function) =====
SELECT * FROM TABLE(get_top_students(101, 'Fall2026', 3));

PROMPT
PROMPT ===== TEST S9: functions called from an anonymous block =====
DECLARE
  l_gpa    NUMBER;
  l_letter VARCHAR2(1);
  l_top    t_top_student_tab;
BEGIN
  l_gpa    := calc_student_gpa(30004);
  l_letter := calc_letter_grade(88.5);
  DBMS_OUTPUT.PUT_LINE('GPA of student 30004 = ' || l_gpa);
  DBMS_OUTPUT.PUT_LINE('calc_letter_grade(88.5) = ' || l_letter);

  l_top := get_top_students(101, 'Fall2026', 2);
  FOR i IN 1 .. l_top.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Top ' || i || ': ' || l_top(i).full_name || ' - ' || l_top(i).score);
  END LOOP;
END;
/

PROMPT
PROMPT ===== TEST S10: bulk_enroll_students (FORALL INSERT, all rows valid) =====
DECLARE
  l_inserted NUMBER;
  l_failed   NUMBER;
BEGIN
  bulk_enroll_students(101, 'Fall2026',
                       t_number_list(30008, 30009, 30010, 30011, 30013),
                       l_inserted, l_failed);
  DBMS_OUTPUT.PUT_LINE('inserted=' || l_inserted || ' failed=' || l_failed);
END;
/
BEGIN
  print_course_roster(101, 'Fall2026');
END;
/

PROMPT
PROMPT ===== TEST S11: bulk_apply_grade_curve (BULK COLLECT LIMIT + FORALL UPDATE) =====
DECLARE
  l_rows NUMBER;
BEGIN
  bulk_apply_grade_curve(101, 'Fall2026', 5, l_rows);
  DBMS_OUTPUT.PUT_LINE('rows updated = ' || l_rows);
END;
/
BEGIN
  print_course_roster(101, 'Fall2026');
END;
/
SELECT enrollment_id, old_score, new_score FROM grade_audit ORDER BY audit_id;

PROMPT
PROMPT ===== TEST S12: benchmark_bulk_vs_row (row-by-row vs FORALL) =====
DECLARE
  l_row_ms  NUMBER;
  l_bulk_ms NUMBER;
BEGIN
  benchmark_bulk_vs_row(50000, l_row_ms, l_bulk_ms);
END;
/

PROMPT
PROMPT ===== Cleaning up: ROLLBACK restores the original sample data =====
ROLLBACK;
