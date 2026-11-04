-- =====================================================================
-- Procedure : print_student_transcript
-- Concepts  : explicit cursor with a cursor FOR loop, associative array
--             (INDEX BY VARCHAR2) to total credits per semester,
--             %ROWTYPE record, function call, EXCEPTION_INIT on a
--             user-defined error code
-- Errors    : -20001 student does not exist
--             (-20030 "no graded courses" from calc_student_gpa is caught
--              and reported as a message, because a new student with no
--              grades is a normal situation for a transcript)
-- =====================================================================
CREATE OR REPLACE PROCEDURE print_student_transcript (
  p_student_id IN students.student_id%TYPE
)
IS
  CURSOR c_transcript (cp_student_id students.student_id%TYPE) IS
    SELECT c.course_code,
           c.course_title,
           c.credits,
           e.semester,
           e.score,
           e.grade_letter
      FROM enrollments e
      JOIN courses c ON c.course_id = e.course_id
     WHERE e.student_id = cp_student_id
     ORDER BY e.enroll_date, c.course_code;

  TYPE t_credit_map IS TABLE OF NUMBER INDEX BY VARCHAR2(12);  -- key = semester
  l_sem_credits t_credit_map;
  l_key         VARCHAR2(12);

  l_student students%ROWTYPE;
  l_gpa     NUMBER;
  l_rows    PLS_INTEGER := 0;

  e_no_grades EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_no_grades, -20030);
BEGIN
  BEGIN
    SELECT * INTO l_student
      FROM students
     WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001,
        'Student ' || p_student_id || ' does not exist.');
  END;

  DBMS_OUTPUT.PUT_LINE('TRANSCRIPT: ' || l_student.first_name || ' ' ||
    l_student.last_name || ' (ID ' || l_student.student_id || ', ' ||
    l_student.status || ')');
  DBMS_OUTPUT.PUT_LINE(RPAD('Semester', 12) || RPAD('Course', 10) ||
    RPAD('Title', 34) || LPAD('Cr', 4) || LPAD('Score', 8) || LPAD('Grade', 7));
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));

  FOR r IN c_transcript(p_student_id) LOOP
    l_rows := l_rows + 1;

    IF l_sem_credits.EXISTS(r.semester) THEN
      l_sem_credits(r.semester) := l_sem_credits(r.semester) + r.credits;
    ELSE
      l_sem_credits(r.semester) := r.credits;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
      RPAD(r.semester, 12) || RPAD(r.course_code, 10) ||
      RPAD(SUBSTR(r.course_title, 1, 32), 34) || LPAD(r.credits, 4) ||
      LPAD(NVL(TO_CHAR(r.score, 'FM990.00'), 'n/a'), 8) ||
      LPAD(NVL(r.grade_letter, '-'), 7));
  END LOOP;

  IF l_rows = 0 THEN
    DBMS_OUTPUT.PUT_LINE('(no enrollments)');
  ELSE
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));
    l_key := l_sem_credits.FIRST;
    WHILE l_key IS NOT NULL LOOP
      DBMS_OUTPUT.PUT_LINE('Credits registered in ' || l_key || ': ' ||
        l_sem_credits(l_key));
      l_key := l_sem_credits.NEXT(l_key);
    END LOOP;
  END IF;

  BEGIN
    l_gpa := calc_student_gpa(p_student_id);
    DBMS_OUTPUT.PUT_LINE('Cumulative GPA: ' || TO_CHAR(l_gpa, 'FM0.00'));
  EXCEPTION
    WHEN e_no_grades THEN
      DBMS_OUTPUT.PUT_LINE('Cumulative GPA: not available (no graded courses yet).');
  END;
END print_student_transcript;
/
SHOW ERRORS
