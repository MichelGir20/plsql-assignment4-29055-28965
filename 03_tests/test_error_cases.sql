-- =====================================================================
-- File    : 03_tests/test_error_cases.sql
-- Purpose : Every error path. Each block prints PASS when the EXPECTED
--           error code is raised and FAIL otherwise (including when no
--           error is raised at all).
-- Needs   : the original sample data (run test_success_cases.sql first
--           or not - it rolls back, so either order works).
-- Re-run  : ends with ROLLBACK.
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100

PROMPT
PROMPT ===== TEST E1: student does not exist (expect -20001) =====
DECLARE
  l_id NUMBER;
BEGIN
  register_student_course(99999, 101, 'Fall2026', l_id);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20001 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E2: course does not exist (expect -20002) =====
DECLARE
  l_id NUMBER;
BEGIN
  register_student_course(30007, 999, 'Fall2026', l_id);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20002 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E3: suspended student (user-defined exception -> -20003) =====
DECLARE
  l_id NUMBER;
BEGIN
  register_student_course(30012, 101, 'Fall2026', l_id);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20003 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E4: duplicate registration (DUP_VAL_ON_INDEX -> -20004) =====
DECLARE
  l_id NUMBER;
BEGIN
  register_student_course(30001, 101, 'Fall2026', l_id);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20004 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E5: course full (user-defined exception -> -20005) =====
DECLARE
  l_id NUMBER;
BEGIN
  register_student_course(30004, 106, 'Fall2026', l_id);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20005 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E6: invalid score 150 (expect -20010) =====
DECLARE
  l_letter VARCHAR2(1);
  l_rows   NUMBER;
  l_enr_id NUMBER;
BEGIN
  SELECT enrollment_id INTO l_enr_id FROM enrollments
   WHERE student_id = 30005 AND course_id = 101 AND semester = 'Fall2026';
  record_grade(l_enr_id, 150, l_letter, l_rows);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20010 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E7: grade for unknown enrollment (SQL%NOTFOUND -> -20011) =====
DECLARE
  l_letter VARCHAR2(1);
  l_rows   NUMBER;
BEGIN
  record_grade(999999, 75, l_letter, l_rows);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20011 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E8: drop an already graded enrollment (expect -20012) =====
DECLARE
  l_rows   NUMBER;
  l_enr_id NUMBER;
BEGIN
  SELECT enrollment_id INTO l_enr_id FROM enrollments
   WHERE student_id = 30001 AND course_id = 101 AND semester = 'Fall2026';
  drop_enrollment(l_enr_id, l_rows);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20012 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E9: drop an unknown enrollment (expect -20011) =====
DECLARE
  l_rows NUMBER;
BEGIN
  drop_enrollment(999999, l_rows);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20011 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E10: NO_DATA_FOUND translated to -20021 =====
DECLARE
  l_student students%ROWTYPE;
BEGIN
  find_student_by_lastname('Nobody', l_student);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20021 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E11: TOO_MANY_ROWS translated to -20022 (two students named Uwase) =====
DECLARE
  l_student students%ROWTYPE;
BEGIN
  find_student_by_lastname('Uwase', l_student);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20022 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E12: calc_student_gpa - student without grades (expect -20030) =====
DECLARE
  l_gpa NUMBER;
BEGIN
  l_gpa := calc_student_gpa(30013);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised (returned ' || l_gpa || ')');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20030 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E13: calc_student_gpa - unknown student (expect -20001) =====
DECLARE
  l_gpa NUMBER;
BEGIN
  l_gpa := calc_student_gpa(99999);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20001 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E14: calc_letter_grade with invalid score (expect -20010) =====
DECLARE
  l_letter VARCHAR2(1);
BEGIN
  l_letter := calc_letter_grade(-5);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised (returned ' || l_letter || ')');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20010 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E15: get_course_enrollment_count - unknown course (expect -20002) =====
DECLARE
  l_n NUMBER;
BEGIN
  l_n := get_course_enrollment_count(999, 'Fall2026');
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20002 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E16: get_top_students - invalid limit (expect -20040) =====
DECLARE
  l_top t_top_student_tab;
BEGIN
  l_top := get_top_students(101, 'Fall2026', 0);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20040 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E17: print_course_roster - unknown course (expect -20002, cursor not leaked) =====
BEGIN
  print_course_roster(999, 'Fall2026');
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20002 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E18: bulk_enroll_students with bad rows (FORALL SAVE EXCEPTIONS / ORA-24381) =====
PROMPT 30011 and 30013 are valid; 99999 does not exist (ORA-02291); 30001 is already enrolled (ORA-00001)
DECLARE
  l_inserted NUMBER;
  l_failed   NUMBER;
BEGIN
  bulk_enroll_students(101, 'Fall2026',
                       t_number_list(30011, 99999, 30001, 30013),
                       l_inserted, l_failed);
  DBMS_OUTPUT.PUT_LINE(CASE WHEN l_inserted = 2 AND l_failed = 2 THEN 'PASS' ELSE 'FAIL' END ||
    ' | inserted=' || l_inserted || ' failed=' || l_failed);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/
SELECT log_id, source_proc, item_index, item_key, error_code, error_message
  FROM bulk_error_log
 ORDER BY log_id;

PROMPT
PROMPT ===== TEST E19: bulk_enroll_students - empty list (expect -20050) =====
DECLARE
  l_inserted NUMBER;
  l_failed   NUMBER;
BEGIN
  bulk_enroll_students(101, 'Fall2026', t_number_list(), l_inserted, l_failed);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20050 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E20: bulk_enroll_students - not enough seats (expect -20005) =====
DECLARE
  l_inserted NUMBER;
  l_failed   NUMBER;
BEGIN
  bulk_enroll_students(106, 'Fall2026', t_number_list(30004, 30005), l_inserted, l_failed);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20005 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E21: bulk_apply_grade_curve - invalid bonus (expect -20060) =====
DECLARE
  l_rows NUMBER;
BEGIN
  bulk_apply_grade_curve(101, 'Fall2026', -5, l_rows);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20060 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E22: bulk_apply_grade_curve - unknown course (expect -20002) =====
DECLARE
  l_rows NUMBER;
BEGIN
  bulk_apply_grade_curve(999, 'Fall2026', 5, l_rows);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20002 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== TEST E23: benchmark_bulk_vs_row - invalid row count (expect -20070) =====
DECLARE
  l_row_ms  NUMBER;
  l_bulk_ms NUMBER;
BEGIN
  benchmark_bulk_vs_row(0, l_row_ms, l_bulk_ms);
  DBMS_OUTPUT.PUT_LINE('FAIL: no error raised');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20070 THEN 'PASS' ELSE 'FAIL' END ||
      ' | SQLCODE=' || SQLCODE || ' | ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== Cleaning up: ROLLBACK restores the original sample data =====
ROLLBACK;
