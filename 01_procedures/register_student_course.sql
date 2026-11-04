-- =====================================================================
-- Procedure : register_student_course
-- Concepts  : %ROWTYPE records, user-defined RECORD type, OUT parameter,
--             implicit INSERT ... RETURNING, predefined exceptions
--             (NO_DATA_FOUND, DUP_VAL_ON_INDEX), user-defined exceptions,
--             RAISE_APPLICATION_ERROR
-- Business rules: student and course must exist, student must be ACTIVE,
--             course must have a free seat, no duplicate registration.
-- Errors    : -20001 student not found     -20002 course not found
--             -20003 student not ACTIVE    -20004 already registered
--             -20005 course is full        -20006 semester is NULL
-- Note      : The procedure does NOT commit; the caller controls the
--             transaction. The course row is locked (FOR UPDATE) so two
--             sessions cannot take the last seat at the same time.
-- =====================================================================
CREATE OR REPLACE PROCEDURE register_student_course (
  p_student_id    IN  students.student_id%TYPE,
  p_course_id     IN  courses.course_id%TYPE,
  p_semester      IN  enrollments.semester%TYPE,
  o_enrollment_id OUT enrollments.enrollment_id%TYPE
)
IS
  l_student students%ROWTYPE;               -- %ROWTYPE record
  l_course  courses%ROWTYPE;                -- %ROWTYPE record

  TYPE t_seat_info IS RECORD (              -- user-defined record
    seats_taken NUMBER,
    seats_free  NUMBER
  );
  l_seats t_seat_info;

  e_student_inactive EXCEPTION;             -- user-defined exceptions
  e_course_full      EXCEPTION;
BEGIN
  IF p_semester IS NULL THEN
    RAISE_APPLICATION_ERROR(-20006, 'Semester must not be NULL.');
  END IF;

  BEGIN
    SELECT * INTO l_student
      FROM students
     WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001,
        'Student ' || p_student_id || ' does not exist.');
  END;

  BEGIN
    SELECT * INTO l_course
      FROM courses
     WHERE course_id = p_course_id
       FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002,
        'Course ' || p_course_id || ' does not exist.');
  END;

  IF l_student.status <> 'ACTIVE' THEN
    RAISE e_student_inactive;
  END IF;

  l_seats.seats_taken := get_course_enrollment_count(p_course_id, p_semester);
  l_seats.seats_free  := l_course.max_capacity - l_seats.seats_taken;

  IF l_seats.seats_free <= 0 THEN
    RAISE e_course_full;
  END IF;

  INSERT INTO enrollments (student_id, course_id, semester)
  VALUES (p_student_id, p_course_id, p_semester)
  RETURNING enrollment_id INTO o_enrollment_id;

  DBMS_OUTPUT.PUT_LINE('Registered ' || l_student.first_name || ' ' ||
    l_student.last_name || ' in ' || l_course.course_code || ' (' ||
    p_semester || '). Enrollment ID = ' || o_enrollment_id ||
    '. Seats left: ' || (l_seats.seats_free - 1));
EXCEPTION
  WHEN e_student_inactive THEN
    RAISE_APPLICATION_ERROR(-20003,
      'Student ' || p_student_id || ' has status ' || l_student.status ||
      ' and cannot register for courses.');
  WHEN e_course_full THEN
    RAISE_APPLICATION_ERROR(-20005,
      'Course ' || l_course.course_code || ' is full (' ||
      l_course.max_capacity || ' seats) for ' || p_semester || '.');
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20004,
      'Student ' || p_student_id || ' is already registered for course ' ||
      p_course_id || ' in ' || p_semester || '.');
END register_student_course;
/
SHOW ERRORS
