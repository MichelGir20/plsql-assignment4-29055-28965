-- =====================================================================
-- Procedure : print_course_roster
-- Concepts  : explicit parameterised cursor with OPEN / FETCH / CLOSE,
--             user-defined RECORD type, cursor attributes %NOTFOUND and
--             %ISOPEN, cleanup in the exception handler
-- Errors    : -20002 course does not exist (any other error is re-raised
--             after the cursor is closed; nothing is swallowed)
-- =====================================================================
CREATE OR REPLACE PROCEDURE print_course_roster (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN enrollments.semester%TYPE
)
IS
  CURSOR c_roster (cp_course_id courses.course_id%TYPE,
                   cp_semester  enrollments.semester%TYPE) IS
    SELECT s.student_id,
           s.first_name || ' ' || s.last_name AS full_name,
           e.score,
           e.grade_letter
      FROM enrollments e
      JOIN students s ON s.student_id = e.student_id
     WHERE e.course_id = cp_course_id
       AND e.semester  = cp_semester
     ORDER BY s.last_name, s.first_name;

  TYPE t_roster_rec IS RECORD (
    student_id   students.student_id%TYPE,
    full_name    VARCHAR2(81),
    score        enrollments.score%TYPE,
    grade_letter enrollments.grade_letter%TYPE
  );
  l_row    t_roster_rec;
  l_course courses%ROWTYPE;
  l_count  PLS_INTEGER := 0;
BEGIN
  BEGIN
    SELECT * INTO l_course
      FROM courses
     WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002,
        'Course ' || p_course_id || ' does not exist.');
  END;

  DBMS_OUTPUT.PUT_LINE('ROSTER: ' || l_course.course_code || ' - ' ||
    l_course.course_title || ' | ' || p_semester);
  DBMS_OUTPUT.PUT_LINE(RPAD('ID', 8) || RPAD('Student', 30) ||
    LPAD('Score', 8) || LPAD('Grade', 7));
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 53, '-'));

  OPEN c_roster(p_course_id, p_semester);
  LOOP
    FETCH c_roster INTO l_row;
    EXIT WHEN c_roster%NOTFOUND;

    l_count := l_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      RPAD(TO_CHAR(l_row.student_id), 8) ||
      RPAD(l_row.full_name, 30) ||
      LPAD(NVL(TO_CHAR(l_row.score, 'FM990.00'), 'n/a'), 8) ||
      LPAD(NVL(l_row.grade_letter, '-'), 7));
  END LOOP;
  CLOSE c_roster;

  IF l_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('(no students enrolled)');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Total students: ' || l_count);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    IF c_roster%ISOPEN THEN
      CLOSE c_roster;
    END IF;
    RAISE;                                   -- never hide the error
END print_course_roster;
/
SHOW ERRORS
