-- =====================================================================
-- Function : calc_letter_grade
-- Purpose  : Convert a numeric score (0-100) to a letter grade.
--            A>=90, B>=80, C>=70, D>=60, otherwise F.
-- Returns  : 'A'..'F', or NULL when the score is NULL (not graded yet).
-- Errors   : ORA-20010 when the score is outside 0-100. An invalid score
--            is never converted to a misleading grade.
-- Usage    : SELECT calc_letter_grade(85) FROM dual;
-- =====================================================================
CREATE OR REPLACE FUNCTION calc_letter_grade (
  p_score IN NUMBER
) RETURN VARCHAR2
  DETERMINISTIC
IS
BEGIN
  IF p_score IS NULL THEN
    RETURN NULL;                      -- ungraded work has no letter
  ELSIF p_score < 0 OR p_score > 100 THEN
    RAISE_APPLICATION_ERROR(-20010,
      'Invalid score ' || p_score || ': a score must be between 0 and 100.');
  ELSIF p_score >= 90 THEN
    RETURN 'A';
  ELSIF p_score >= 80 THEN
    RETURN 'B';
  ELSIF p_score >= 70 THEN
    RETURN 'C';
  ELSIF p_score >= 60 THEN
    RETURN 'D';
  ELSE
    RETURN 'F';
  END IF;
END calc_letter_grade;
/
SHOW ERRORS
