WITH RECURSIVE lock_tree AS (
    
    SELECT DISTINCT
        a.pid,
        a.usename,
        a.application_name,
        a.client_addr,
        a.state,
        a.query,
        a.query_start,
        a.xact_start,
        NULL::integer AS blocked_by,
        0 AS level
    FROM pg_stat_activity a
    JOIN pg_locks l ON l.pid = a.pid
    WHERE l.granted
      AND EXISTS (
          SELECT 1
          FROM pg_locks bl
          WHERE bl.locktype = l.locktype
            AND bl.database    IS NOT DISTINCT FROM l.database
            AND bl.relation    IS NOT DISTINCT FROM l.relation
            AND bl.page        IS NOT DISTINCT FROM l.page
            AND bl.tuple       IS NOT DISTINCT FROM l.tuple
            AND bl.virtualxid  IS NOT DISTINCT FROM l.virtualxid
            AND bl.transactionid IS NOT DISTINCT FROM l.transactionid
            AND bl.classid     IS NOT DISTINCT FROM l.classid
            AND bl.objid       IS NOT DISTINCT FROM l.objid
            AND bl.objsubid    IS NOT DISTINCT FROM l.objsubid
            AND bl.pid <> l.pid
            AND NOT bl.granted
      )

    UNION ALL

    SELECT DISTINCT
        ba.pid,
        ba.usename,
        ba.application_name,
        ba.client_addr,
        ba.state,
        ba.query,
        ba.query_start,
        ba.xact_start,
        lt.pid AS blocked_by,
        lt.level + 1 AS level
    FROM pg_stat_activity ba
    JOIN pg_locks bl ON bl.pid = ba.pid
    JOIN pg_locks l
      ON l.locktype      = bl.locktype
     AND l.database      IS NOT DISTINCT FROM bl.database
     AND l.relation      IS NOT DISTINCT FROM bl.relation
     AND l.page          IS NOT DISTINCT FROM bl.page
     AND l.tuple         IS NOT DISTINCT FROM bl.tuple
     AND l.virtualxid    IS NOT DISTINCT FROM bl.virtualxid
     AND l.transactionid IS NOT DISTINCT FROM bl.transactionid
     AND l.classid       IS NOT DISTINCT FROM bl.classid
     AND l.objid         IS NOT DISTINCT FROM bl.objid
     AND l.objsubid      IS NOT DISTINCT FROM bl.objsubid
    JOIN lock_tree lt ON lt.pid = l.pid
    WHERE l.granted
      AND NOT bl.granted
)
SELECT
    now() AS ts,                         
    pid,
    blocked_by AS blocker_pid,
    level,
    repeat('  ', level) || pid::text AS pid_tree,
    usename,
    application_name,
    client_addr,
    state,
    now() - query_start AS query_age,
    now() - xact_start  AS xact_age,
    query
FROM lock_tree
ORDER BY level, query_start;
