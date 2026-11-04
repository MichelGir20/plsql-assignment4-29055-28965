-- =====================================================================
-- Function : get_top_students
-- Purpose  : Return the top-N scoring students of a course/semester as a
--            nested-table collection (built with BULK COLLECT).
-- Errors   : ORA-20002 course does not exist
--            ORA-20040 p_limit is NULL or less than 1
-- Usage    : SELECT * FROM TABLE(get_top_students(101, 'Fall2026', 3));
-- =====================================================================
CREATE OR REPLACE FUNCTION get_top_students (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN enrollments.semester%TYPE,
  p_limit     IN NUMBER DEFAULT 3
) RETURN t_top_student_tab
IS
  l_dummy  NUMBER;
  l_result t_top_student_tab;
BEGIN
  IF p_limit IS NULL OR p_limit < 1 THEN
    RAISE_APPLICATION_ERROR(-20040,
      'p_limit must be a positive number (received ' || NVL(TO_CHAR(p_limit), 'NULL') || ').');
  END IF;

  SELECT 1 INTO l_dummy
    FROM courses
   WHERE course_id = p_course_id;

  SELECT t_top_student_obj(s.student_id,
                           s.first_name || ' ' || s.last_name,
                           e.score)
    BULK COLLECT INTO l_result
    FROM enrollments e
    JOIN students s ON s.student_id = e.student_id
   WHERE e.course_id = p_course_id
     AND e.semester  = p_semester
     AND e.score IS NOT NULL
   ORDER BY e.score DESC, s.last_name
   FETCH FIRST p_limit ROWS ONLY;

  RETURN l_result;   -- an empty collection is a valid answer, not an error
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002,
      'Course ' || p_course_id || ' does not exist.');
END get_top_students;
/
SHOW ERRORS
