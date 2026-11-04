-- =====================================================================
-- Procedure : drop_enrollment
-- Concepts  : implicit cursor on DELETE, SQL%ROWCOUNT / SQL%FOUND /
--             SQL%NOTFOUND, user-defined exceptions
-- Rule      : only UNGRADED enrollments may be dropped.
-- Errors    : -20011 enrollment does not exist
--             -20012 enrollment already graded, cannot be dropped
-- Note      : does not commit; the caller controls the transaction.
-- =====================================================================
CREATE OR REPLACE PROCEDURE drop_enrollment (
  p_enrollment_id IN  enrollments.enrollment_id%TYPE,
  o_rows_deleted  OUT NUMBER
)
IS
  l_exists         NUMBER;
  e_not_found      EXCEPTION;
  e_already_graded EXCEPTION;
BEGIN
  DELETE FROM enrollments
   WHERE enrollment_id = p_enrollment_id
     AND score IS NULL;

  o_rows_deleted := SQL%ROWCOUNT;

  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Enrollment ' || p_enrollment_id ||
      ' dropped (' || o_rows_deleted || ' row deleted).');
  ELSE  -- SQL%NOTFOUND: work out WHY nothing was deleted
    SELECT COUNT(*) INTO l_exists
      FROM enrollments
     WHERE enrollment_id = p_enrollment_id;

    IF l_exists = 0 THEN
      RAISE e_not_found;
    ELSE
      RAISE e_already_graded;
    END IF;
  END IF;
EXCEPTION
  WHEN e_not_found THEN
    RAISE_APPLICATION_ERROR(-20011,
      'Enrollment ' || p_enrollment_id || ' does not exist; nothing dropped.');
  WHEN e_already_graded THEN
    RAISE_APPLICATION_ERROR(-20012,
      'Enrollment ' || p_enrollment_id || ' already has a grade and cannot be dropped.');
END drop_enrollment;
/
SHOW ERRORS
