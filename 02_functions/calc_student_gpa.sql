-- =====================================================================
-- Function : calc_student_gpa
-- Purpose  : Credit-weighted GPA on a 4.0 scale (A=4, B=3, C=2, D=1, F=0)
--            over all graded enrollments of a student.
-- Errors   : ORA-20001 student does not exist
--            ORA-20030 student has no graded courses (a GPA of 0 would be
--                      misleading, so an error is raised instead)
-- Usage    : SELECT calc_student_gpa(30001) FROM dual;
-- =====================================================================
CREATE OR REPLACE FUNCTION calc_student_gpa (
  p_student_id IN students.student_id%TYPE
) RETURN NUMBER
IS
  l_dummy   NUMBER;
  l_points  NUMBER;
  l_credits NUMBER;
  e_no_grades EXCEPTION;
BEGIN
  SELECT 1 INTO l_dummy
    FROM students
   WHERE student_id = p_student_id;

  SELECT SUM(CASE e.grade_letter
               WHEN 'A' THEN 4
               WHEN 'B' THEN 3
               WHEN 'C' THEN 2
               WHEN 'D' THEN 1
               ELSE 0
             END * c.credits),
         SUM(c.credits)
    INTO l_points, l_credits
    FROM enrollments e
    JOIN courses c ON c.course_id = e.course_id
   WHERE e.student_id   = p_student_id
     AND e.grade_letter IS NOT NULL;

  IF l_credits IS NULL OR l_credits = 0 THEN
    RAISE e_no_grades;
  END IF;

  RETURN ROUND(l_points / l_credits, 2);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001,
      'Student ' || p_student_id || ' does not exist.');
  WHEN e_no_grades THEN
    RAISE_APPLICATION_ERROR(-20030,
      'Student ' || p_student_id || ' has no graded courses; GPA cannot be computed.');
END calc_student_gpa;
/
SHOW ERRORS
