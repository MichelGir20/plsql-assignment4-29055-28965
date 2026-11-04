-- =====================================================================
-- Procedure : bulk_enroll_students
-- Concepts  : nested-table collection as IN parameter, FORALL INSERT with
--             SAVE EXCEPTIONS, SQL%BULK_EXCEPTIONS, ORA-24381 handling,
--             associative array of user-defined records, error logging
-- Behaviour : valid students are enrolled; invalid ones (unknown student,
--             duplicate registration, ...) are skipped, counted in
--             o_failed and written to bulk_error_log. Nothing is hidden.
-- Errors    : -20002 course does not exist
--             -20005 not enough free seats for the whole list
--             -20050 empty or NULL student list
-- Note      : does not commit. The error-log rows belong to the caller's
--             transaction (query them before ROLLBACK).
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_enroll_students (
  p_course_id   IN  courses.course_id%TYPE,
  p_semester    IN  enrollments.semester%TYPE,
  p_student_ids IN  t_number_list,
  o_inserted    OUT NUMBER,
  o_failed      OUT NUMBER
)
IS
  l_course courses%ROWTYPE;
  l_free   NUMBER;

  TYPE t_err_rec IS RECORD (
    item_index PLS_INTEGER,
    error_code PLS_INTEGER
  );
  TYPE t_err_tab IS TABLE OF t_err_rec INDEX BY PLS_INTEGER;
  l_errors t_err_tab;
  l_err    t_err_rec;
  l_msg    VARCHAR2(4000);

  e_dml_errors  EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_dml_errors, -24381);   -- raised by SAVE EXCEPTIONS
  e_empty_list  EXCEPTION;
  e_course_full EXCEPTION;
BEGIN
  o_inserted := 0;
  o_failed   := 0;

  IF p_student_ids IS NULL OR p_student_ids.COUNT = 0 THEN
    RAISE e_empty_list;
  END IF;

  BEGIN
    SELECT * INTO l_course
      FROM courses
     WHERE course_id = p_course_id
       FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002,
        'Course ' || p_course_id || ' does not exist.');
  END;

  l_free := l_course.max_capacity -
            get_course_enrollment_count(p_course_id, p_semester);

  IF p_student_ids.COUNT > l_free THEN
    RAISE e_course_full;
  END IF;

  -- One round trip to the SQL engine for the whole list.
  FORALL i IN 1 .. p_student_ids.COUNT SAVE EXCEPTIONS
    INSERT INTO enrollments (student_id, course_id, semester)
    VALUES (p_student_ids(i), p_course_id, p_semester);

  o_inserted := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('Bulk enrol finished: ' || o_inserted ||
    ' inserted, 0 failed.');
EXCEPTION
  WHEN e_dml_errors THEN
    o_failed   := SQL%BULK_EXCEPTIONS.COUNT;
    o_inserted := p_student_ids.COUNT - o_failed;

    -- Copy the exception details first, then log them.
    FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      l_err.item_index := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
      l_err.error_code := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;
      l_errors(j)      := l_err;
    END LOOP;

    FOR j IN 1 .. l_errors.COUNT LOOP
      l_msg := SQLERRM(-l_errors(j).error_code);   -- SQLERRM is not allowed inside SQL
      INSERT INTO bulk_error_log
        (source_proc, item_index, item_key, error_code, error_message)
      VALUES
        ('BULK_ENROLL_STUDENTS', l_errors(j).item_index,
         TO_CHAR(p_student_ids(l_errors(j).item_index)),
         l_errors(j).error_code, l_msg);

      DBMS_OUTPUT.PUT_LINE('  skipped student ' ||
        p_student_ids(l_errors(j).item_index) || ' -> ' || l_msg);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Bulk enrol finished: ' || o_inserted ||
      ' inserted, ' || o_failed || ' failed (see bulk_error_log).');
  WHEN e_empty_list THEN
    RAISE_APPLICATION_ERROR(-20050, 'The student list is empty; nothing to enrol.');
  WHEN e_course_full THEN
    RAISE_APPLICATION_ERROR(-20005,
      'Course ' || l_course.course_code || ' has only ' || l_free ||
      ' free seat(s) for ' || p_semester || ' but ' || p_student_ids.COUNT ||
      ' students were submitted. Nobody was enrolled.');
END bulk_enroll_students;
/
SHOW ERRORS
