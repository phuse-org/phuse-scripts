/* $Header: sp_dump_sp.sql 1.001 2008/02/14 12:10:10 cc$ 
PURPOSE
  This stored procedure dump selected records to a text file

REQUIRED:
  sp_colname_fn  - get column names
  sp_output_sp   - output to a file

NOTES
  1. Make sure the output directory is defined in the database

HISTORY   MM/DD/YYYY (developer) 
  02/14/2008 (htu) - initial creation 
  03/25/2008 (htu) - added cc_name space
  ---------
  02/26/2009 (htu) - fixed the cc_output_sp input variables
  02/18/2010 (htu) - added check in step 2 for p_sch = USER
                     added HTMLONLY for p_fmt
                     allowed char 'null' for p_cns and p_whr
  05/13/2010 (htu) - added dbms_lob.isopen in the exception block  
  07/21/2010 (htu) - changed p_sch.all_objects to sys.dba_objects
  07/22/2010 (htu) - 
    1. changed '=' to 'like' in step 2
    2. added GOTO end_all to skip writing to file
    3. changed output file extend to '.htm' while 'htmlonly'
  06/14/2011 (htu) - removed echo proc and used cc_pkg.echo instead of it                         

*/

CREATE OR REPLACE PROCEDURE sp_dump_sp (
    p_obj  VARCHAR2 DEFAULT NULL	-- table or view name
  , p_cns  VARCHAR2 DEFAULT NULL	-- column names separated by comma
  , p_whr  VARCHAR2 DEFAULT NULL	-- where clause
  , p_ofs  VARCHAR2 DEFAULT ','		-- output field separator
  , p_ors  VARCHAR2 DEFAULT CHR(10)	-- output record separator
  , p_fqt  VARCHAR2 DEFAULT '"'		-- field quotes
  , p_dft  VARCHAR2 DEFAULT 'YYYYMMDD.HH24MISS'	-- date format
  , p_typ  VARCHAR2 DEFAULT 'TABLE'	-- object type: table or view
  , p_sch  VARCHAR2 DEFAULT USER	-- schema name
  , p_dbl  VARCHAR2 DEFAULT NULL	-- database link
  , p_ofn  VARCHAR2 DEFAULT NULL	-- output file name
  , p_dir  VARCHAR2 DEFAULT NULL	-- output directory
  , p_fmt  VARCHAR2 DEFAULT 'csv'	-- output format: CSV, HTML, HTMLONLY
  , p_tbf  VARCHAR2 DEFAULT 'border="1"'	-- table tags
  , p_out  INTEGER  DEFAULT 2		-- output option
  , p_opt  INTEGER  DEFAULT 0		-- file: 0 - new/ow; 1 - append
  , p_hdr  INTEGER  DEFAULT 1		-- whether to add header: yes(1) or no (0)
  , p_lvl  INTEGER  DEFAULT 0		-- message level
) IS
  v_prg  VARCHAR2(100) := 'sp_dump_sp';
  sqt    CHAR(1) := CHR(39);
  dqt    CHAR(1) := CHR(34);
  cma    CHAR(1) := CHR(44);
  cr     CHAR(1) := CHR(10);
  s      VARCHAR2(4000); 
  n      NUMBER;
  v_obj  VARCHAR2(200);
  v_cns  VARCHAR2(2000) := NULL;   -- select statement
  TYPE   a_refcur IS REF CURSOR;
  c      a_refcur;
  v_col  VARCHAR2(100);            -- column name
  v_typ  VARCHAR2(100);            -- data type 
  v_ofn  VARCHAR2(100);            -- output file name
  x      VARCHAR2(4000) := '';
  len    NUMBER;
  rec    CLOB; 

  PROCEDURE exec_cnt (
    p_obj IN     VARCHAR2,               -- object name
    p_whr IN     VARCHAR2 DEFAULT NULL,  -- full where clause
    p_num IN OUT NUMBER                  -- number of records
  ) IS
    s   VARCHAR2(2000);
  BEGIN
    s := 'SELECT count(*) FROM '||p_obj;
    IF p_whr IS NOT NULL AND UPPER(p_whr) <> 'NULL' THEN
      s := s||CHR(10)||p_whr;
    END IF;
    sp_pkg.echo(s, 3);
    BEGIN 
      p_num := 0;
      EXECUTE IMMEDIATE s INTO p_num;
      sp_pkg.echo('p_num = '||to_char(p_num),3); 
      EXCEPTION  
      WHEN OTHERS THEN   
        sp_pkg.echo('ERR('||v_prg||'): '||SQLERRM,0);  
    END;
    IF p_num = 0 THEN
      sp_pkg.echo('INFO('||v_prg||'): '||p_obj||' does not exist',0);  
      RETURN;
    ELSE
      s := 'INFO('||v_prg||'):     '||TO_CHAR(p_num)||' records in '||p_obj;
      sp_pkg.echo(s,1);  
    END IF;
  END;

BEGIN
  -- 1. check inputs
  sp_pkg.echo('INFO('||v_prg||'): 1 - check inputs', 1);
  IF p_obj IS NULL THEN  
    sp_pkg.echo('ERR('||v_prg||'): missing table or view name.',0);
    RETURN; 
  END IF;
  IF p_dbl IS NULL THEN
    v_obj := p_sch||'.'||p_obj;
  ELSE
    v_obj := p_obj||'@'||p_dbl;
  END IF;
  sp_pkg.echo(v_obj, 3);
  IF p_ofn IS NULL THEN
    IF UPPER(p_fmt) IN ('HTML','HTMLONLY') THEN
      v_ofn := 'f'||TO_CHAR(sysdate,'YYYYMMDD_HH24MISS')||'.htm';
    ELSE
      v_ofn := 'f'||TO_CHAR(sysdate,'YYYYMMDD_HH24MISS')||'.'||p_fmt;
    END IF;
  ELSE
    v_ofn := p_ofn;
  END IF;

  -- 2. check objects
  sp_pkg.echo('INFO('||v_prg||'): 2 - check objects', 1);
  s := 'SELECT count(*) FROM '||v_obj; 
  IF p_dbl IS NULL THEN 
    s :=    ' WHERE owner       like UPPER('''||p_sch||''')'||cr;
    s := s||'   AND object_type like UPPER('''||p_typ||''')'||cr;
    s := s||'   AND object_name like UPPER('''||p_obj||''')';
    IF UPPER(p_sch) = USER THEN
      exec_cnt('all_objects',s, n);
    ELSE
      -- exec_cnt(p_sch||'.'||'all_objects',s, n);
      exec_cnt('sys.dba_objects',s, n);
    END IF;
    IF n = 0 THEN RETURN; END IF;
  ELSE
    exec_cnt(v_obj, '', n);
    IF n = 0 THEN RETURN; END IF;
  END IF;

  -- 3. get column names
  sp_pkg.echo('INFO('||v_prg||'): 3 - get column names', 1);
  IF UPPER(p_fmt) IN ('HTML','HTMLONLY') THEN
    IF p_cns IS NULL OR UPPER(p_cns) IN ('NULL','*','ALL') THEN 
      v_cns := sp_colname_fn(p_obj,'html',p_sch,p_dbl,
             null,p_ofs,p_ors,p_fqt,p_dft,p_lvl);
    ELSE
      v_cns := sp_colname_fn(p_obj,'html',p_sch,p_dbl,
             p_cns,p_ofs,p_ors,p_fqt,p_dft,p_lvl);
    END IF;
  ELSE 
    IF p_cns IS NULL OR UPPER(p_cns) IN ('NULL','ALL') THEN 
      v_cns := sp_colname_fn(p_obj,p_fmt,p_sch,p_dbl,
             null,p_ofs,p_ors,p_fqt,p_dft,p_lvl);
    ELSE 
      IF p_cns = '*' THEN
        v_cns := '*';
      ELSE 
       v_cns := sp_colname_fn(p_obj,p_fmt,p_sch,p_dbl,
             p_cns,p_ofs,p_ors,p_fqt,p_dft,p_lvl);
      END IF; 
    END IF;
  END IF;
  sp_pkg.echo('INFO('||v_prg||'): '||v_cns,2);
  
  -- 4. get records from the object
  sp_pkg.echo('INFO('||v_prg||'): 4 - build sql statement', 1);
  s :=    'SELECT '||v_cns||cr||'  FROM '||v_obj;
  IF p_whr IS NOT NULL AND UPPER(p_whr) <> 'NULL' THEN
    s := s||cr||p_whr;
  END IF;
  sp_pkg.echo(s, 3);

  -- 5. create CLOB 
  sp_pkg.echo('INFO('||v_prg||'): 5 - build clob object', 1);
  dbms_lob.createtemporary(rec, TRUE);
  dbms_lob.open(rec, dbms_lob.lob_readwrite);

  IF UPPER(p_fmt) = 'CSV' AND p_hdr = 1 THEN
    x := sp_colname_fn(p_obj,'csv_hdr',p_sch,p_dbl,
         null,p_ofs,p_ors,p_fqt,p_dft,p_lvl)||p_ors;
  ELSIF UPPER(p_fmt) IN ('HTML','HTMLONLY') THEN
    x := '<TABLE '||p_tbf||' >'||cr;
    IF p_cns IS NULL OR UPPER(p_cns) IN ('NULL','ALL') THEN 
      x := x||sp_colname_fn(p_obj,'html_hdr',p_sch,p_dbl,
           null,p_ofs,p_ors,p_fqt,p_dft,p_lvl)||cr;
    ELSE
      x := x||sp_colname_fn(p_obj,'html_hdr',p_sch,p_dbl,
           p_cns,p_ofs,p_ors,p_fqt,p_dft,p_lvl)||cr;
    END IF;
    IF UPPER(p_fmt) = 'HTMLONLY' THEN         
      sp_pkg.echo(x,0);         
    END IF;
  ELSE
    x := '';
  END IF;
  len := length(x); dbms_lob.writeappend(rec, len, x);

  n := 0;
  OPEN c FOR s;	
  LOOP
    FETCH c INTO x;
    EXIT WHEN c%NOTFOUND;
    IF UPPER(p_fmt) = 'HTMLONLY' THEN
      sp_pkg.echo(x, 0); 
    END IF;
    n := n + 1;
    x := x||p_ors;
    len := length(x); dbms_lob.writeappend(rec, len, x);
  END LOOP;	
  CLOSE c;
  sp_pkg.echo('INFO('||v_prg||'):     '||TO_CHAR(n)||' records selected',1);
  
  IF UPPER(p_fmt) IN ('HTML','HTMLONLY') THEN
    x := '</TABLE>'||cr;
    IF UPPER(p_fmt) = 'HTMLONLY' THEN
      sp_pkg.echo(x,0); 
      sp_pkg.echo('Total '||to_char(n)||' records selected',0); 
    END IF;
  END IF;
  len := length(x); dbms_lob.writeappend(rec, len, x);  
  
  -- 6. create CLOB 
  sp_pkg.echo('INFO('||v_prg||'): 6 - write to file '||v_ofn, 1);
  sp_pkg.echo('INFO('||v_prg||'):     in '||p_dir, 1);
  IF UPPER(p_fmt) IN ('HTMLONLY') THEN
    sp_pkg.echo('INFO(sp_dump_sp): output to '||v_ofn||': skipped',1);
    GOTO end_all; 
  END IF;
  sp_output_sp(s=>rec,p_ofn=>v_ofn,p_out=>p_out,p_dir=>p_dir,p_opt=>0 
      , p_skp=>1, p_lvl=>p_lvl);  
  <<end_all>>
  dbms_lob.close(rec);
  EXCEPTION  
  WHEN OTHERS THEN   
    IF dbms_lob.isopen(rec) <> 0 THEN dbms_lob.close(rec); END IF;
    sp_pkg.echo('ERR('||v_prg||'): '||SQLERRM,0);  
    raise;
END;
/

show err

/*  
@map_sp/src/sp_dump_sp.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/map_sp -a wrap src/sp_dump
@map_sp/wrapped/sp_dump_sp.plb

Test case:
define ufd=/opt/ora/ufd/owb1

exec sp_dump_sp('cc_rules',p_dir=>'&ufd',p_lvl=>3);
exec sp_dump_sp('cc_rules',p_dir=>'&ufd',p_lvl=>1);
exec sp_dump_sp('cc_rules',p_fmt=>'html',p_dir=>'&ufd',p_lvl=>3);

exec sp_dump_sp('ors_issue1',p_sch=>'viewpoint',p_dbl=>'vp_vpsql',p_fmt=>'csv',p_dir=>'&ufd',p_lvl=>1);

begin
  sp_dump_sp('ors_issue1', null,'where project_id =13609952',
    p_sch=>'viewpoint',
    p_dbl=>'vp_vpsql',
    p_fmt=>'csv',
    p_dir=>'&ufd',
    p_lvl=>1);
end;
/

CREATE OR REPLACE PROCEDURE vp_getissues
(
  p_tab  VARCHAR2 DEFAULT NULL
) IS
  CURSOR c IS 
    SELECT project_id, count(*) as cnt
      FROM ors_issue1@vp_vpsql
    GROUP BY project_id;    
  i NUMBER;
  n NUMBER; 
  f VARCHAR2(50);
BEGIN
  IF NOT c%ISOPEN THEN OPEN c; END IF;
  LOOP
    FETCH c INTO i, n;
    EXIT WHEN c%NOTFOUND;
    f := 'p'||to_char(i)||'.csv';
    sp_dump_sp('ors_issue1', null,'where project_id='||to_char(i),
      p_ofn=>f,
      p_sch=>'viewpoint',
      p_dbl=>'vp_vpsql',
      p_fmt=>'csv',
      p_dir=>'&ufd',
      p_lvl=>1);
  END LOOP;	
  CLOSE c;
END;
/


exec owb_admin.sp_dump_sp('dba_users',p_sch=>'sys',p_typ=>'view',p_fmt=>'html',p_out=>1,p_lvl=>3);

exec owb_admin.sp_dump_sp('dba_users','username,account_status','where default_tablespace=''OWB_USR'' order by username',p_sch=>'sys',p_typ=>'view',p_fmt=>'html',p_out=>1,p_lvl=>3);

*/
