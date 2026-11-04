-- =====================================================================
-- Function : get_course_enrollment_count
-- Purpose  : Number of students enrolled in a course for a semester.
-- Errors   : ORA-20002 when the course does not exist (NO_DATA_FOUND is
--            translated into a meaningful application error).
-- Usage    : SELECT get_course_enrollment_count(101, 'Fall2026') FROM dual;
-- =====================================================================
CREATE OR REPLACE FUNCTION get_course_enrollment_count (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN enrollments.semester%TYPE
) RETURN NUMBER
IS
  l_dummy NUMBER;
  l_count NUMBER;
BEGIN
  -- Existence check: an unknown course must not silently return 0.
  SELECT 1 INTO l_dummy
    FROM courses
   WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO l_count
    FROM enrollments
   WHERE course_id = p_course_id
     AND semester  = p_semester;

  RETURN l_count;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002,
      'Course ' || p_course_id || ' does not exist.');
END get_course_enrollment_count;
/
SHOW ERRORS
