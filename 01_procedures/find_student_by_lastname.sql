-- =====================================================================
-- Procedure : find_student_by_lastname
-- Concepts  : %ROWTYPE record as an OUT parameter, predefined exceptions
--             NO_DATA_FOUND and TOO_MANY_ROWS, RAISE_APPLICATION_ERROR
-- Errors    : ORA-20020 last name is NULL
--             ORA-20021 no student has that last name   (NO_DATA_FOUND)
--             ORA-20022 several students share that name (TOO_MANY_ROWS)
-- =====================================================================
CREATE OR REPLACE PROCEDURE find_student_by_lastname (
  p_last_name IN  students.last_name%TYPE,
  o_student   OUT students%ROWTYPE
)
IS
BEGIN
  IF p_last_name IS NULL THEN
    RAISE_APPLICATION_ERROR(-20020, 'Last name must not be NULL.');
  END IF;

  SELECT *
    INTO o_student
    FROM students
   WHERE UPPER(last_name) = UPPER(p_last_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20021,
      'No student found with last name ''' || p_last_name || '''.');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20022,
      'More than one student has last name ''' || p_last_name ||
      '''; look the student up by student ID instead.');
END find_student_by_lastname;
/
SHOW ERRORS
