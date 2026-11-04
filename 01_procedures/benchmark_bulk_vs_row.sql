-- =====================================================================
-- Procedure : benchmark_bulk_vs_row
-- Concepts  : performance comparison of row-by-row UPDATE (FOR loop,
--             one SQL call per row) versus FORALL UPDATE (one SQL call
--             for the whole collection), BULK COLLECT, autonomous
--             transaction
-- Why autonomous? The benchmark fills and empties its own scratch table
--             (perf_test) and commits, so it can never commit or roll
--             back the caller's unfinished work.
-- Errors    : -20070 p_rows is NULL or not between 1 and 1,000,000
-- Timer     : DBMS_UTILITY.GET_TIME has 10 ms resolution.
-- =====================================================================
CREATE OR REPLACE PROCEDURE benchmark_bulk_vs_row (
  p_rows          IN  PLS_INTEGER,
  o_row_by_row_ms OUT NUMBER,
  o_bulk_ms       OUT NUMBER
)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;

  TYPE t_num_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  l_ids   t_num_tab;
  l_start NUMBER;
BEGIN
  IF p_rows IS NULL OR p_rows < 1 OR p_rows > 1000000 THEN
    RAISE_APPLICATION_ERROR(-20070,
      'p_rows must be between 1 and 1,000,000 (received ' ||
      NVL(TO_CHAR(p_rows), 'NULL') || ').');
  END IF;

  -- Prepare test data
  DELETE FROM perf_test;
  INSERT INTO perf_test (id, val)
  SELECT LEVEL, 0 FROM dual CONNECT BY LEVEL <= p_rows;
  COMMIT;

  SELECT id BULK COLLECT INTO l_ids FROM perf_test ORDER BY id;

  -- 1) Row-by-row: one context switch PL/SQL -> SQL per row
  l_start := DBMS_UTILITY.GET_TIME;
  FOR i IN 1 .. l_ids.COUNT LOOP
    UPDATE perf_test SET val = val + 1 WHERE id = l_ids(i);
  END LOOP;
  o_row_by_row_ms := (DBMS_UTILITY.GET_TIME - l_start) * 10;

  UPDATE perf_test SET val = 0;             -- reset (not timed)

  -- 2) Bulk: a single context switch for the whole collection
  l_start := DBMS_UTILITY.GET_TIME;
  FORALL i IN 1 .. l_ids.COUNT
    UPDATE perf_test SET val = val + 1 WHERE id = l_ids(i);
  o_bulk_ms := (DBMS_UTILITY.GET_TIME - l_start) * 10;

  -- Leave the scratch table empty
  DELETE FROM perf_test;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Rows updated per method : ' || p_rows);
  DBMS_OUTPUT.PUT_LINE('Row-by-row (FOR loop)   : ' || o_row_by_row_ms || ' ms');
  DBMS_OUTPUT.PUT_LINE('Bulk (FORALL)           : ' || o_bulk_ms || ' ms');
  IF o_bulk_ms > 0 THEN
    DBMS_OUTPUT.PUT_LINE('FORALL was about ' ||
      ROUND(o_row_by_row_ms / o_bulk_ms, 1) || 'x faster.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('FORALL finished below the 10 ms timer resolution; ' ||
      'increase p_rows for a measurable ratio.');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;                               -- end the autonomous transaction cleanly
    RAISE;
END benchmark_bulk_vs_row;
/
SHOW ERRORS
