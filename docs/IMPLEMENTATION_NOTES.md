# Implementation Notes

## 1. Design overview

The application models student registration and grading. All business logic lives in stored procedures and functions; tables only enforce structural rules (keys, uniqueness, CHECK constraints).

Design decisions:

- **Procedures do not COMMIT.** The caller owns the transaction, which lets the test scripts `ROLLBACK` and stay re-runnable. The one exception is `benchmark_bulk_vs_row`, which uses `PRAGMA AUTONOMOUS_TRANSACTION` so it can manage its own scratch table without touching the caller's work.
- **Schema-level collection types** (`T_NUMBER_LIST`, `T_TOP_STUDENT_TAB`) are required whenever a collection crosses a procedure boundary or is queried with `TABLE()`. Types that are only used inside one procedure are declared locally.
- **Constraints are the last line of defence; procedures check first.** For example the capacity rule and student status rule are checked in `register_student_course` to give clear messages, while the unique constraint still protects against duplicates created by any other route.
- **Seat limit under concurrency.** `register_student_course` and `bulk_enroll_students` lock the course row with `SELECT ... FOR UPDATE` before counting seats, so two sessions cannot both take the last seat.
- **Functions never return misleading values.** `calc_letter_grade` raises ORA-20010 for out-of-range scores (instead of returning 'F'); `calc_student_gpa` raises ORA-20030 for a student with no grades (instead of returning 0.00).

## 2. Exception handling strategy

| Code | Raised by | Meaning | Mechanism |
|------|-----------|---------|-----------|
| -20001 | register_student_course, calc_student_gpa, print_student_transcript | Student not found | `NO_DATA_FOUND` translated |
| -20002 | register_student_course, get_course_enrollment_count, get_top_students, print_course_roster, bulk_enroll_students, bulk_apply_grade_curve | Course not found | `NO_DATA_FOUND` translated |
| -20003 | register_student_course | Student not ACTIVE | user-defined `e_student_inactive` |
| -20004 | register_student_course | Already registered | `DUP_VAL_ON_INDEX` translated |
| -20005 | register_student_course, bulk_enroll_students | Course full / not enough seats | user-defined `e_course_full` |
| -20006 | register_student_course | Semester is NULL | direct `RAISE_APPLICATION_ERROR` |
| -20010 | record_grade, calc_letter_grade | Invalid score | user-defined `e_invalid_score` / direct |
| -20011 | record_grade, drop_enrollment | Enrollment not found | `SQL%NOTFOUND` + user-defined exception |
| -20012 | drop_enrollment | Graded enrollment cannot be dropped | user-defined `e_already_graded` |
| -20020 | find_student_by_lastname | NULL last name | direct |
| -20021 | find_student_by_lastname | No student with that name | `NO_DATA_FOUND` translated |
| -20022 | find_student_by_lastname | Several students share the name | `TOO_MANY_ROWS` translated |
| -20030 | calc_student_gpa | No graded courses | user-defined `e_no_grades` |
| -20040 | get_top_students | Invalid limit | direct |
| -20050 | bulk_enroll_students | Empty student list | user-defined `e_empty_list` |
| -20060 | bulk_apply_grade_curve | Invalid bonus | user-defined `e_bad_bonus` |
| -20070 | benchmark_bulk_vs_row | Invalid row count | direct |

Principles:

1. **Translate, don't swallow.** Predefined exceptions are converted to specific application errors with the offending values in the message.
2. **No silent `WHEN OTHERS`.** Where a catch-all exists (`print_course_roster`, `bulk_apply_grade_curve`, `benchmark_bulk_vs_row`) it only releases resources (close cursor / rollback the autonomous transaction) and then `RAISE`s again.
3. **Partial success is reported, not hidden.** `bulk_enroll_students` continues past bad rows (`SAVE EXCEPTIONS`) but returns `o_inserted` / `o_failed`, prints each rejected student and writes it to `bulk_error_log`.
4. Because `SQLERRM` cannot be used inside a SQL statement, its value is first copied to a local variable before being inserted into the log.

## 3. Bulk processing and performance

### The problem with row-by-row processing

```sql
FOR i IN 1 .. l_ids.COUNT LOOP
  UPDATE perf_test SET val = val + 1 WHERE id = l_ids(i);
END LOOP;
```

PL/SQL and SQL are separate engines. Each `UPDATE` inside a loop makes the PL/SQL engine hand the statement to the SQL engine and wait for the result: one **context switch per row**. For 50,000 rows that is 50,000 switches, and the switching overhead is often larger than the cost of the update itself.

### What bulk processing changes

- `BULK COLLECT` fetches many rows into a collection with **one** switch.
- `FORALL` sends the whole collection of bind values to the SQL engine in **one** switch, which then executes the statement for each element.

```sql
FORALL i IN 1 .. l_ids.COUNT
  UPDATE perf_test SET val = val + 1 WHERE id = l_ids(i);
```

`benchmark_bulk_vs_row(50000, ...)` measures both approaches on the same data. Measured results on our machine *(run test S12 and paste your numbers here)*:

| Rows | Row-by-row (ms) | FORALL (ms) | Speed-up |
|------|-----------------|-------------|----------|
| 50,000 | *(fill in)* | *(fill in)* | *(fill in)* |

Timings vary with hardware and caching. `DBMS_UTILITY.GET_TIME` has 10 ms resolution, so use a large enough row count.

### Practices used

- **`LIMIT` in `bulk_apply_grade_curve`.** A plain `BULK COLLECT` on a huge table can exhaust session (PGA) memory. Fetching in batches of 100 keeps memory bounded while still avoiding row-by-row switches.
- **`SAVE EXCEPTIONS` in `bulk_enroll_students`.** Without it the first failing row aborts the `FORALL` and rolls back that statement. With it, Oracle processes every element, then raises ORA-24381 and exposes each failure in `SQL%BULK_EXCEPTIONS` (index and error code).
- **`SQL%BULK_ROWCOUNT`** shows how many rows each individual execution touched, so a "successful" bulk update that matched nothing is still noticed.
- Computation that needs no SQL (new score, letter grade) is done in a PL/SQL loop over the collection *before* the `FORALL`, because a `FORALL` can only contain one DML statement.

### Limitations

- `bulk_apply_grade_curve` holds row locks (`FOR UPDATE`) until the caller commits or rolls back.
- `bulk_enroll_students` validates only seat count; student status is enforced in the single-row procedure. A production version could pre-filter the list with a `BULK COLLECT` query joining `students`.
- Rows written to `bulk_error_log` share the caller's transaction, so a `ROLLBACK` also removes the log. A production system would log through an autonomous-transaction procedure.

## 4. Requirement coverage checklist

| Checklist item | Done | Evidence |
|----------------|------|----------|
| Tables, relationships, constraints | yes | `00_schema/01_create_tables.sql` |
| Sample data | yes | `00_schema/02_insert_sample_data.sql` |
| Records (user-defined and `%ROWTYPE`) | yes | see README section 5 |
| Collections (associative array, nested table) | yes | see README section 5 |
| Implicit cursors with `SQL%ROWCOUNT`, `%FOUND`, `%NOTFOUND` | yes | `record_grade`, `drop_enrollment` |
| Explicit cursors (OPEN/FETCH/CLOSE and FOR loop) | yes | `print_course_roster`, `print_student_transcript` |
| BULK COLLECT + FORALL + bulk DML error handling | yes | `bulk_enroll_students`, `bulk_apply_grade_curve` |
| Procedures and functions compile | yes | `user_objects` check returns no invalid objects |
| Predefined / user-defined exceptions, `RAISE_APPLICATION_ERROR` | yes | section 2 |
| Success and error tests with screenshots | yes | `03_tests/`, `screenshots/` |
| Implementation and performance notes | yes | this file |
