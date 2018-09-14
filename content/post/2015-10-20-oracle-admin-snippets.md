---
date: "2015-10-20"
title: Oracle Administration Snippets
layout: post
---

On this page I am collecting bits and pieces which help with Oracle database administration. I have collected them from over the internet, so thanks a lot to all those people providing these helpful examples. In case you are the author of one of them and would like some credit, please let me know and I will mention the source gladly.

<!--more-->

## Locks

### Check for blocking locks

        select s1.username || '@' || s1.machine
         || ' ( SID=' || s1.sid || ' )  is blocking '
            || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status
            from v$lock l1, v$session s1, v$lock l2, v$session s2
            where s1.sid=l1.sid and s2.sid=l2.sid
            and l1.BLOCK=1 and l2.request > 0
            and l1.id1 = l2.id1
            and l2.id2 = l2.id2;

## Sessions

### Check / kill user sessions

#### Show all sessions

        select * from v$session;

#### Session details

        SELECT se.osuser,se.username,se.status,se.sid "O-sid",
        p.pid "O-pid" ,se.process "user pid", p.spid "wkg-pid",
        to_char(se.logon_time,'MM/DD/YY HH24:MI') "logon",se.machine
        FROM v$session se, v$process p
        WHERE addr=paddr AND se.osuser IS NOT NULL AND se.username IS NOT NULL
        ORDER BY se.osuser

#### Kill session (sid & serial# from v$session mentioned above, execute as SYSTEM)

        ALTER SYSTEM KILL SESSION 'sid,serial#';

#### Kill session the hard way (parameters as above)

        ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;

## SQL Statements

### Display SQL for sql_id

        -- sql_id can be determined from v$session
        select * from v$sqlarea where sql_id= '3fmfmpj2kuuf7';

### Locked tables and objects

        -- Locks by type
        SELECT session_id,lock_type, mode_held, mode_requested, blocking_others, lock_id1
        FROM dba_lock l
        WHERE lock_type NOT IN ('Media Recovery', 'Redo Thread');
        
        -- generally locked objects
        SELECT oracle_username USERNAME, owner OBJECT_OWNER,
        object_name, object_type, s.osuser,
        DECODE(l.block,
          0, 'Not Blocking',
          1, 'Blocking',
          2, 'Global') STATUS,
          DECODE(v.locked_mode,
            0, 'None',
            1, 'Null',
            2, 'Row-S (SS)',
            3, 'Row-X (SX)',
            4, 'Share',
            5, 'S/Row-X (SSX)',
            6, 'Exclusive', TO_CHAR(lmode)
          ) MODE_HELD
        FROM gv$locked_object v, dba_objects d,
        gv$lock l, gv$session s
        WHERE v.object_id = d.object_id
        AND (v.object_id = l.id1)
        and v.session_id = s.sid

        -- lock details
        SELECT SUBSTR(TO_CHAR(w.session_id),1,5) WSID, p1.spid WPID,
          SUBSTR(s1.username,1,12) "WAITING User",
          SUBSTR(s1.osuser,1,8) "OS User",
          SUBSTR(s1.program,1,20) "WAITING Program",
          s1.client_info "WAITING Client",
          SUBSTR(TO_CHAR(h.session_id),1,5) HSID, p2.spid HPID,
          SUBSTR(s2.username,1,12) "HOLDING User",
          SUBSTR(s2.osuser,1,8) "OS User",
          SUBSTR(s2.program,1,20) "HOLDING Program",
          s2.client_info "HOLDING Client",
          o.object_name "HOLDING Object"
        FROM gv$process p1, gv$process p2, gv$session s1,
          gv$session s2, dba_locks w, dba_locks h, dba_objects o
        WHERE w.last_convert > 120
        AND h.mode_held != 'None'
        AND h.mode_held != 'Null'
        AND w.mode_requested != 'None'
        AND s1.row_wait_obj# = o.object_id
        AND w.lock_type(+) = h.lock_type
        AND w.lock_id1(+) = h.lock_id1
        AND w.lock_id2 (+) = h.lock_id2
        AND w.session_id = s1.sid (+)
        AND h.session_id = s2.sid (+)
        AND s1.paddr = p1.addr (+)
        AND s2.paddr = p2.addr (+)
        ORDER BY w.last_convert desc;

## Tablespaces

### Tablespace Informations

        select
           fs.tablespace_name                          "Tablespace",
           (df.totalspace - fs.freespace)              "Used MB",
           fs.freespace                                "Free MB",
           df.totalspace                               "Total MB",
           round(100 * (fs.freespace / df.totalspace)) "Pct. Free"
        from
           (select
              tablespace_name,
              round(sum(bytes) / 1048576) TotalSpace
           from
              dba_data_files
           group by
              tablespace_name
           ) df,
           (select
              tablespace_name,
              round(sum(bytes) / 1048576) FreeSpace
           from
              dba_free_space
           group by
              tablespace_name
           ) fs
        where
           df.tablespace_name = fs.tablespace_name;

### Table sizes for the current schema

        SET serveroutput ON
        DECLARE
          CURSOR tabs
          IS
            SELECT object_name FROM user_objects WHERE object_type = 'TABLE';
          table_size_meg pls_integer := 0;
        BEGIN
          FOR t IN tabs
          LOOP
            BEGIN
              SELECT SUM(bytes)/(1024*1024)
              INTO table_size_meg
              FROM user_extents
              WHERE segment_type='TABLE'
              AND segment_name  = t.object_name
              GROUP BY segment_name;
              dbms_output.put_line(t.object_name || ': ' || table_size_meg || ' MB');
            EXCEPTION
            WHEN no_data_found THEN
              dbms_output.put_line('No data found.');
            END;
          END LOOP;
        END;
        /

## Database objects

### Reverse Engineering of DB objects

        select DBMS_METADATA.GET_DDL('TABLE','table_name') from dual;

### Create DB links

        CREATE DATABASE LINK "link_name"
          CONNECT TO schema_name 
          IDENTIFIED BY pass
          USING 'tns definition (e. g. from tnsnames.ora)';

### Determine table size (MB)

        SELECT
          segment_name AS table_name,   
          Sum(bytes)/(1024*1024) table_size_meg
        FROM user_extents
        WHERE segment_type='TABLE'
        AND segment_name = 'table_name'
        GROUP BY segment_name

### Check compile state of DB objects

        SELECT o.object_type, o.object_name
        FROM user_objects o
        WHERE o.status <> 'VALID'
        AND o.object_type IN ('VIEW','PROCEDURE','FUNCTION','PACKAGE','TRIGGER')

### Check long operations

        SELECT v.sid, se.osuser, se.machine, se.program, v.target, v.opname
        FROM V$SESSION_LONGOPS v, v$session se
        WHERE v.sid = se.sid
        AND v.username = 'user_name'
        ORDER BY se.machine 

        -- determine progress and remaining time
        SELECT
          To_Char(Floor(elapsed_seconds / 3600), 'FM09') || ':' || 
          To_Char(Floor(Mod(elapsed_seconds, 3600) / 60), 'FM09') || ':' || 
          To_Char(Mod(elapsed_seconds, 60), 'FM09') AS runtime,
          To_Char(Floor(time_remaining / 3600), 'FM09') || ':' || 
          To_Char(Floor(Mod(time_remaining, 3600) / 60), 'FM09') || ':' || 
          To_Char(Mod(time_remaining, 60), 'FM09') AS remaining,
          To_Char(((sofar / totalwork) * 100), 'FM99.99') || ' %' AS done_pct 
        FROM V$SESSION_LONGOPS v, v$session se
        WHERE v.sid = se.sid 
        AND v.target = 'schema_name.object_name'
        AND v.username = 'schema_name'
        AND se.sid = '<sid>';

### Check where the trace file for current session is

        select 
          u_dump.value   || '/'     || 
          db_name.value  || '_ora_' || 
          v$process.spid || 
          nvl2(v$process.traceid,  '_' || v$process.traceid, null ) 
          || '.trc'  "Trace File"
        from 
                     v$parameter u_dump 
          cross join v$parameter db_name
          cross join v$process 
                join v$session 
                  on v$process.addr = v$session.paddr
        where 
         u_dump.name   = 'user_dump_dest' and 
         db_name.name  = 'db_name'        and
         v$session.audsid=sys_context('userenv','sessionid');
        
        (from http://www.adp-gmbh.ch/ora/misc/find_trace_file.html)

