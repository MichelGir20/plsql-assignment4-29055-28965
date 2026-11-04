-- =====================================================================
-- Procedure : bulk_apply_grade_curve
-- Concepts  : explicit cursor + BULK COLLECT ... LIMIT, associative
--             arrays, FORALL UPDATE and FORALL INSERT,
--             SQL%BULK_ROWCOUNT, SQL%ROWCOUNT, user-defined exception
-- Effect    : adds p_bonus points (capped at 100) to every graded
--             enrollment of the course/semester, recalculates the letter
--             grade and writes one grade_audit row per change.
-- Errors    : -20002 course does not exist
--             -20060 bonus is NULL, <= 0 or > 20
-- Note      : does not commit; the caller controls the transaction.
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_apply_grade_curve (
  p_course_id    IN  courses.course_id%TYPE,
  p_semester     IN  enrollments.semester%TYPE,
  p_bonus        IN  NUMBER,
  o_rows_updated OUT NUMBER
)
IS
  CURSOR c_graded IS
    SELECT enrollment_id, score
      FROM enrollments
     WHERE course_id = p_course_id
       AND semester  = p_semester
       AND score IS NOT NULL
       FOR UPDATE;

  TYPE t_id_tab     IS TABLE OF enrollments.enrollment_id%TYPE INDEX BY PLS_INTEGER;
  TYPE t_score_tab  IS TABLE OF enrollments.score%TYPE         INDEX BY PLS_INTEGER;
  TYPE t_letter_tab IS TABLE OF enrollments.grade_letter%TYPE  INDEX BY PLS_INTEGER;

  l_ids     t_id_tab;
  l_old     t_score_tab;
  l_new     t_score_tab;
  l_letters t_letter_tab;

  c_batch_size CONSTANT PLS_INTEGER := 100;   -- LIMIT keeps PGA memory bounded
  l_dummy      NUMBER;
  e_bad_bonus  EXCEPTION;
BEGIN
  o_rows_updated := 0;

  IF p_bonus IS NULL OR p_bonus <= 0 OR p_bonus > 20 THEN
    RAISE e_bad_bonus;
  END IF;

  BEGIN
    SELECT 1 INTO l_dummy
      FROM courses
     WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002,
        'Course ' || p_course_id || ' does not exist.');
  END;

  OPEN c_graded;
  LOOP
    FETCH c_graded BULK COLLECT INTO l_ids, l_old LIMIT c_batch_size;
    EXIT WHEN l_ids.COUNT = 0;

    -- Compute new scores in memory (no SQL involved here)
    FOR i IN 1 .. l_ids.COUNT LOOP
      l_new(i)     := LEAST(l_old(i) + p_bonus, 100);
      l_letters(i) := calc_letter_grade(l_new(i));
    END LOOP;

    -- One bulk UPDATE per batch
    FORALL i IN 1 .. l_ids.COUNT
      UPDATE enrollments
         SET score        = l_new(i),
             grade_letter = l_letters(i)
       WHERE enrollment_id = l_ids(i);

    -- SQL%BULK_ROWCOUNT(i) = rows touched by the i-th execution
    FOR i IN 1 .. l_ids.COUNT LOOP
      IF SQL%BULK_ROWCOUNT(i) = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Warning: enrollment ' || l_ids(i) || ' was not updated.');
      ELSE
        o_rows_updated := o_rows_updated + SQL%BULK_ROWCOUNT(i);
      END IF;
    END LOOP;

    -- One bulk INSERT per batch for the audit trail
    FORALL i IN 1 .. l_ids.COUNT
      INSERT INTO grade_audit (enrollment_id, old_score, new_score)
      VALUES (l_ids(i), l_old(i), l_new(i));
  END LOOP;
  CLOSE c_graded;

  DBMS_OUTPUT.PUT_LINE('Curve of +' || p_bonus || ' applied to ' ||
    o_rows_updated || ' enrollment(s) in course ' || p_course_id ||
    ' (' || p_semester || ').');
EXCEPTION
  WHEN e_bad_bonus THEN
    RAISE_APPLICATION_ERROR(-20060,
      'Bonus must be greater than 0 and at most 20 (received ' ||
      NVL(TO_CHAR(p_bonus), 'NULL') || ').');
  WHEN OTHERS THEN
    IF c_graded%ISOPEN THEN
      CLOSE c_graded;
    END IF;
    RAISE;                                    -- never hide unexpected errors
END bulk_apply_grade_curve;
/
SHOW ERRORS
