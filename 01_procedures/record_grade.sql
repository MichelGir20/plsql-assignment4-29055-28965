-- =====================================================================
-- Procedure : record_grade
-- Concepts  : implicit cursor on INSERT..SELECT and UPDATE, cursor
--             attributes SQL%FOUND, SQL%NOTFOUND, SQL%ROWCOUNT,
--             OUT parameters, user-defined exceptions
-- Effect    : stores score + letter grade and writes a grade_audit row.
-- Errors    : -20010 score NULL or outside 0-100
--             -20011 enrollment does not exist
-- Note      : does not commit; the caller controls the transaction.
-- =====================================================================
CREATE OR REPLACE PROCEDURE record_grade (
  p_enrollment_id IN  enrollments.enrollment_id%TYPE,
  p_score         IN  enrollments.score%TYPE,
  o_letter        OUT enrollments.grade_letter%TYPE,
  o_rows_updated  OUT NUMBER
)
IS
  e_invalid_score        EXCEPTION;
  e_enrollment_not_found EXCEPTION;
BEGIN
  o_rows_updated := 0;

  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE e_invalid_score;
  END IF;

  o_letter := calc_letter_grade(p_score);

  -- Audit first so the OLD score is captured; inserts 0 rows if the
  -- enrollment does not exist.
  INSERT INTO grade_audit (enrollment_id, old_score, new_score)
  SELECT enrollment_id, score, p_score
    FROM enrollments
   WHERE enrollment_id = p_enrollment_id;

  UPDATE enrollments
     SET score        = p_score,
         grade_letter = o_letter
   WHERE enrollment_id = p_enrollment_id;

  o_rows_updated := SQL%ROWCOUNT;           -- read straight after the UPDATE

  IF SQL%NOTFOUND THEN
    RAISE e_enrollment_not_found;
  END IF;

  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Grade recorded for enrollment ' || p_enrollment_id ||
      ': score=' || p_score || ', letter=' || o_letter ||
      ', rows updated=' || o_rows_updated);
  END IF;
EXCEPTION
  WHEN e_invalid_score THEN
    RAISE_APPLICATION_ERROR(-20010,
      'Score must be between 0 and 100 (received ' ||
      NVL(TO_CHAR(p_score), 'NULL') || ').');
  WHEN e_enrollment_not_found THEN
    RAISE_APPLICATION_ERROR(-20011,
      'Enrollment ' || p_enrollment_id || ' does not exist; no grade recorded.');
END record_grade;
/
SHOW ERRORS
