/* $Header: sp_colname_fn.sql 1.001 2008/02/14 12:10:10 cc$
PURPOSE
  This function returns a list of column names based on 
  different requests.

REQUIRED:
  sp_objexist_fn - check if object exist

NOTES
  1. This can only get column names for tables.

HISTORY   MM/DD/YYYY (developer) 
  02/15/2008 (htu) - initial creation 
  03/25/2008 (htu) - added sp_ name space
  ---------
  02/20/2009 (htu) - enable getting column names from views
  02/18/2010 (htu) - added more echos
  04/07/2010 (htu) - renumbered from 5009 to 1109
  06/18/2010 (htu) - fixed duplicated last column names 
  07/21/2010 (htu) - added NVL(col, '&nbsp;') in html_col

*/

CREATE OR REPLACE FUNCTION sp_colname_fn (
  p_obj  VARCHAR2 DEFAULT NULL,              -- table or view name
  p_opt  VARCHAR2 DEFAULT NULL,              -- output format
  p_sch  VARCHAR2 DEFAULT USER,              -- schema name
  p_dbl  VARCHAR2 DEFAULT NULL,              -- database link
  p_cns  VARCHAR2 DEFAULT NULL,              -- column names separated by comma
  p_ofs  VARCHAR2 DEFAULT ',',               -- output field separator
  p_ors  VARCHAR2 DEFAULT CHR(10),           -- output record separator
  p_fqt  VARCHAR2 DEFAULT '"',               -- field quotes
  p_dft  VARCHAR2 DEFAULT 'MM/DD/YYYY HH24MISS', -- date format
  p_lvl  INTEGER  DEFAULT 0                  -- message level
) RETURN VARCHAR2
IS
  v_prg  VARCHAR2(100) := 'sp_colname_fn';
  sqt    CHAR(1) := CHR(39);
  dqt    CHAR(1) := CHR(34);
  cma    CHAR(1) := CHR(44);
  cr     CHAR(1) := CHR(10);
  whr    VARCHAR2(4000); 
  s      VARCHAR2(4000); 
  n      NUMBER  := 0;
  n1     NUMBER  := 0;
  n2     NUMBER;
  v_obj  VARCHAR2(200);
  v_cns  VARCHAR2(2000) := NULL;   -- select statement
  v_stg  VARCHAR2(20)   := NULL;   -- start tag
  v_ctg  VARCHAR2(20)   := NULL;   -- close tag
  TYPE   a_refcur IS REF CURSOR;
  c      a_refcur;
  v_col  VARCHAR2(100)		;	-- column name
  v_typ  VARCHAR2(100)		;	-- data type 
  v_otp  VARCHAR2(100)		;	-- obj type: table or view
  v_tmp  VARCHAR2(4000)		;

  PROCEDURE echo (
    msg clob,
    lvl NUMBER DEFAULT 999
  ) IS
  BEGIN
    IF lvl <= p_lvl THEN
        dbms_output.put_line(msg);
    END IF;
  END;
  
  FUNCTION csv_col (
    col    VARCHAR2,
    typ    VARCHAR2
  ) RETURN VARCHAR2 IS
    c      VARCHAR2(2000);
  BEGIN    
    IF typ = 'DATE' OR typ LIKE 'TIME%' THEN 
      c := 'TO_CHAR('||col||','||sqt||p_dft||sqt||')'||cr;
    ELSIF typ LIKE 'NUM%' OR typ IN ('FLOAT') THEN
      c := 'TO_CHAR('||col||')'||cr;
    ELSIF typ LIKE 'VARCH%' OR typ LIKE 'NVARCH%' 
       OR typ IN('LONG','CHAR','NCHAR','CLOB','NCLOB') THEN 
      c := sqt||p_fqt||sqt||'||REPLACE('||col||',';
      c := c  ||sqt||p_fqt||sqt||')'||'||'||sqt||p_fqt||sqt||cr;
    ELSE       -- we will deal with other types later
      echo('WARN('||v_prg||'): unhandled type ('||col||','||typ||')',1);
      c := p_fqt||col||p_fqt; 
    END IF;
    RETURN c;
  END;    

  FUNCTION csv_hdr (
    col   VARCHAR2,
    typ   VARCHAR2,
    stg   VARCHAR2 DEFAULT '',   -- start tag
    ctg   VARCHAR2 DEFAULT ''    -- close tag
  ) RETURN VARCHAR2 IS
    c     VARCHAR2(2000) := '';
  BEGIN    
    IF typ LIKE 'VARCH%' OR typ LIKE 'NVARCH%' 
       OR typ IN('LONG','CHAR','NCHAR','CLOB','NCLOB') THEN
      c := stg||col||ctg;
    ELSE
      c := col;
    END IF;
    RETURN c;
  END;    

  FUNCTION html_col (
    col   VARCHAR2,
    typ   VARCHAR2,
    stg   VARCHAR2 DEFAULT '  <TD>',   -- start tag
    ctg   VARCHAR2 DEFAULT '</TD>'     -- close tag
  ) RETURN VARCHAR2 IS
    c     VARCHAR2(2000);
  BEGIN    
    IF typ = 'DATE' OR typ LIKE 'TIME%' THEN
      c := sqt||stg||sqt||'||NVL(TO_CHAR('||col||','||sqt||p_dft||sqt||'),';
      c := c  ||'chr(38)||''nbsp''||chr(59))';
      c := c  ||'||'||sqt||ctg||sqt||cr;
    ELSIF typ LIKE 'NUM%' OR typ IN ('FLOAT') THEN
      c := sqt||stg||sqt||'||NVL(TO_CHAR('||col||'),';
      c := c  ||'chr(38)||''nbsp''||chr(59))';      
      c := c  ||'||'||sqt||ctg||sqt||cr;
    ELSIF typ LIKE 'VARCH%' OR typ LIKE 'NVARCH%' 
       OR typ IN('LONG','CHAR','NCHAR','CLOB','NCLOB') THEN
      c := sqt||stg||sqt||'||NVL('||col||',';
      c := c  ||'chr(38)||''nbsp''||chr(59))';            
      c := c  ||'||'||sqt||ctg||sqt||cr;
    ELSE       -- we will deal with other types later
      echo('WARN('||v_prg||'): unhandled type - '||typ,1);
      c := sqt||stg||sqt||'||NVL('||col||',';
      c := c  ||'||'||sqt||ctg||sqt||cr;
    END IF;
    RETURN c;
  END;    

  FUNCTION html_hdr (
    col   VARCHAR2,
    typ   VARCHAR2,
    stg   VARCHAR2 DEFAULT '  <TH>',   -- start tag
    ctg   VARCHAR2 DEFAULT '</TH>'     -- close tag
  ) RETURN VARCHAR2 IS
    c     VARCHAR2(2000);
  BEGIN    
    c := stg||col||ctg||cr;
    RETURN c;
  END;    

BEGIN
  -- 1. check inputs
  IF p_obj IS NULL THEN
    echo('ERR('||v_prg||'): missing object name',0);
    RETURN NULL;
  END IF;
  IF p_dbl IS NULL THEN
    v_obj := p_sch||'.'||p_obj;
  ELSE
    v_obj := p_obj||'@'||p_dbl;
  END IF;
  
  IF p_dbl IS NULL THEN
    IF sp_objexist_fn(p_obj,'TABLE',p_sch) THEN
      v_otp := 'TABLE';
      echo('INFO('||v_prg||'): v_otp=TABLE',3);
    ELSIF sp_objexist_fn(p_obj,'VIEW',p_sch) THEN
      v_otp := 'VIEW';
      echo('INFO('||v_prg||'): v_otp=VIEW',3);
    ELSE
      echo('INFO('||v_prg||'): p_obj='||p_obj||',p_sch='||p_sch,2);
      echo('ERR('||v_prg||'): object - '||v_obj||' does not exist.',0);
      RETURN NULL;
    END IF;
  ELSE
    s := 'SELECT count(object_name) FROM all_objects'||'@'||p_dbl||cr;
    s := s||' WHERE owner = :1 AND object_type = :2 AND object_name = :3';
    echo(s,3);
    EXECUTE IMMEDIATE s INTO n1 USING UPPER(p_sch),'TABLE',UPPER(p_obj);
    EXECUTE IMMEDIATE s INTO n2 USING UPPER(p_sch),'VIEW',UPPER(p_obj);
    IF n1 > 0 THEN
      v_otp := 'TABLE';
    ELSIF n2 > 0 THEN 
      v_otp := 'VIEW';
    ELSE
      echo('ERR('||v_prg||'): object - '||v_obj||' does not exist.',0);
      RETURN NULL;      
    END IF;
  END IF;
  -- define start and close tag based on p_ofs
  IF UPPER(p_opt) = 'HTML' THEN
    IF p_ofs IN (',',';','|') THEN s := 'TD'; ELSE s := p_ofs; END IF;
    v_stg := '  <'||s||'>';
    v_ctg := '</'||s||'>';
  ELSIF UPPER(p_opt) IN ('HEADER','HDR','HTML_HDR') THEN
    v_stg := '  <TH>';
    v_ctg := '</TH>';
  END IF;
  
  -- 2. get column names from all_tab_columns
  IF p_dbl IS NULL THEN
    s := 'SELECT column_name, data_type FROM all_tab_columns '||cr;
  ELSE
    s := 'SELECT column_name, data_type FROM all_tab_columns';
    s := s||'@'||p_dbl||cr;
  END IF;
  s := s||' WHERE owner       = UPPER('''||p_sch||''')'||cr;
  s := s||'   AND table_name  = UPPER('''||p_obj||''')'||cr;
  v_tmp := UPPER(REPLACE(REPLACE(p_cns, ' ',''),',',''','''));
  IF p_cns IS NOT NULL AND UPPER(p_cns) NOT IN ('NULL','ALL','*') THEN
    IF INSTR(p_cns,',') > 0 THEN
      -- remove any blank spaces and replace comma with ',' 
      s := s||'   AND column_name IN ('''||v_tmp||''')'||cr;
    ELSIF INSTR(p_cns,'%') > 0 THEN
      s := s||'   AND column_name LIKE UPPER('''||p_cns||''') '||cr;
    ELSE 
      s := s||'   AND column_name = UPPER('''||p_cns||''') '||cr;
    END IF;
  END IF; 
  s := s||'ORDER BY column_id';
  echo(s, 3);
  OPEN c FOR s;	
  LOOP
    FETCH c INTO v_col,v_typ;
    EXIT WHEN c%NOTFOUND;
    IF v_cns IS NULL THEN
      IF UPPER(p_opt) = 'CSV' THEN
        v_cns := csv_col(v_col, v_typ);
      ELSIF UPPER(p_opt) = 'HTML' THEN
        v_cns := sqt||'<TR>'||sqt||cr||'||'||sqt||cr||sqt||'||'||cr;
        v_cns := v_cns||html_col(v_col,v_typ,v_stg,v_ctg);
      ELSIF UPPER(p_opt) IN ('HEADER','HDR','HTML_HDR') THEN
        v_cns := '<TR>'||cr||html_hdr(v_col,v_typ,v_stg,v_ctg);
      ELSIF UPPER(p_opt) IN ('CSV_HDR') THEN
        v_cns := csv_hdr(v_col,v_typ,p_fqt,p_fqt);
      ELSE
        v_cns := v_col;
      END IF;
    ELSE                  -- v_cns is not null
      IF UPPER(p_opt) = 'CSV' THEN
        v_cns := v_cns||'||'||sqt||p_ofs||sqt||'||'||csv_col(v_col, v_typ);
      ELSIF UPPER(p_opt) = 'HTML' THEN
        v_cns := v_cns||'||'||sqt||cr||sqt||'||'||html_col(v_col,v_typ,v_stg,v_ctg);
      ELSIF UPPER(p_opt) IN ('HEADER','HDR','HTML_HDR') THEN
        v_cns := v_cns||html_hdr(v_col,v_typ,v_stg,v_ctg);
      ELSIF UPPER(p_opt) IN ('CSV_HDR') THEN
        v_cns := v_cns||p_ofs||csv_hdr(v_col,v_typ,p_fqt,p_fqt);
      ELSE
        v_cns := v_cns||p_ofs||v_col;
      END IF;
    END IF;
  END LOOP;	
  CLOSE c;
  IF UPPER(p_opt) = 'CSV' THEN
--    v_cns := v_cns||'||'||sqt||p_ofs||sqt||'||'||csv_col(v_col, v_typ);
    null;
  ELSIF UPPER(p_opt) = 'HTML' THEN
    -- v_cns := v_cns||'||'||sqt||cr||sqt||'||'||html_col(v_col,v_typ,v_stg,v_ctg);
    v_cns := v_cns||'||'||sqt||cr||sqt||'||'||sqt||'</TR>'||sqt||cr;
  ELSIF UPPER(p_opt) IN ('HEADER','HDR','HTML_HDR') THEN
    -- v_cns := v_cns||html_hdr(v_col,v_typ,v_stg,v_ctg)||'</TR>'||cr;
    v_cns := v_cns||'</TR>'||cr;
--  ELSIF UPPER(p_opt) IN ('CSV_HDR') THEN
--    v_cns := v_cns||p_ofs||csv_hdr(v_col,v_typ,p_fqt,p_fqt);
--  ELSE
--    v_cns := v_cns||p_ofs||v_col;
  END IF;
  echo(v_cns, 3);
  RETURN v_cns;
  
  EXCEPTION  
  WHEN OTHERS THEN   
    echo('ERR('||v_prg||'): '||SQLERRM,0);  
END;
/

show err

/*
@cmdr/v300a/all_sqls/cc1109_colname_fn.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/cmdr/v300a -a wrap all_sqls/cc1109
@cmdr/v300a/wrapped/cc1109_colname_fn.plb

-- from a table 
select sp_colname_fn('cc_rules') from dual;
-- from a view
select sp_colname_fn('D_TIMING_ORS_IR0001',null,'comply3chk') from dual;

select sp_colname_fn('cc_rules','csv') from dual;
select sp_colname_fn('cc_rules','hdr') from dual;
select sp_colname_fn('cc_rules','csv_hdr') from dual;
select sp_colname_fn('cc_rules','html') from dual;
select sp_colname_fn('dba_users','html','sys',null,null,',',CHR(10),'"','MM/DD/YYYY HH24MISS',3) from dual;

select sp_colname_fn('dba_users','html','sys',null,'username,account_status',',',CHR(10),'"','MM/DD/YYYY HH24MISS',3) from dual;

SELECT
'"'||REPLACE(RULE_ID,'"')||'"'
||','||'"'||REPLACE(RULE_DOMAIN,'"')||'"'
||','||'"'||REPLACE(RULE_DESCRIPTION,'"')||'"'
||','||'"'||REPLACE(SEVERITY,'"')||'"'
||','||'"'||REPLACE(CC_CATEGORY,'"')||'"'
||','||'"'||REPLACE(RULE_VERSION,'"')||'"'
||','||TO_CHAR(EFFECTIVE_DATE,'MM/DD/YYYY HH24MISS')
||','||'"'||REPLACE(ERROR_MSG,'"')||'"'
||','||'"'||REPLACE(IMPACT,'"')||'"'
||','||TO_CHAR(RULE_UID)
||','||TO_CHAR(RULE_UID)
FROM cc_rules;

select sp_colname_fn('cc_rules','html') from dual;

SELECT
'<TR>'
||'
'||
'  <TD>'||RULE_ID||'</TD>'
||'
'||'  <TD>'||RULE_DOMAIN||'</TD>'
||'
'||'  <TD>'||RULE_DESCRIPTION||'</TD>'
||'
'||'  <TD>'||SEVERITY||'</TD>'
||'
'||'  <TD>'||CC_CATEGORY||'</TD>'
||'
'||'  <TD>'||RULE_VERSION||'</TD>'
||'
'||'  <TD>'||TO_CHAR(EFFECTIVE_DATE,'MM/DD/YYYY HH24MISS')||'</TD>'
||'
'||'  <TD>'||ERROR_MSG||'</TD>'
||'
'||'  <TD>'||IMPACT||'</TD>'
||'
'||'  <TD>'||TO_CHAR(RULE_UID)||'</TD>'
||'
'||'  <TD>'||TO_CHAR(RULE_UID)||'</TD>'
||'
'||'</TR>'
from cc_rules;

cc_dev@OWB1> select sp_colname_fn('cc_rules','hdr') from dual;

<TR>
  <TH>RULE_ID</TH>
  <TH>RULE_DOMAIN</TH>
  <TH>RULE_DESCRIPTION</TH>
  <TH>SEVERITY</TH>
  <TH>CC_CATEGORY</TH>
  <TH>RULE_VERSION</TH>
  <TH>EFFECTIVE_DATE</TH>
  <TH>ERROR_MSG</TH>
  <TH>IMPACT</TH>
  <TH>RULE_UID</TH>
  <TH>RULE_UID</TH>
</TR>

cc_dev@OWB1> select sp_colname_fn('cc_rules','xxxhdr') from dual;

RULE_ID,RULE_DOMAIN,RULE_DESCRIPTION,SEVERITY,CC_CATEGORY,RULE_VERSION,
EFFECTIVE_DATE,ERROR_MSG,IMPACT,RULE_UID,RULE_UID

# select cc_colname_sp('ors_issue1','csv_hdr','viewpoint','vp_vpsql') from dual;
*/
