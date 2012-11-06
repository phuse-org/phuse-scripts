/* $Header: sp_output_sp.sql 1.001 2008/01/03 12:10:10 cc$ 
Copyright (c) 2008 Hanmiing Tu All Rights Reserved.

PURPOSE
  This stored procedure writes the content to a file based on
  output option
  
PROGRAMS CALLED
  dbms_output.put_line -- output messages
  sp_wrt2file_sp       -- write to file 
  sp_email_sp          -- send email

NOTES
  1. Make sure the output directory is defined in the database

HISTORY   MM/DD/YYYY (developer) 
  01/03/2008 (htu) - initial creation 
                     p_out explained as 
                      0 - do nothing
                      1 - execute codes
                      2 - output codes to file
                      3 - email status
                      4 - echo codes to screen
                      5 - create wrapped
                      6 - execute, output, and email
                     10 - do all above
  01/23/2008 (htu) - changed to use dbms_output and v_prg                     
  03/20/2008 (htu) - added sp_ name space
  04/04/2008 (htu) - added codes to bump up 'execute immediate' to 32k
  04/14/2008 (htu) - made p_ofn is optional 
                     since when p_opt=0,1,3,4 no output file name is needed.
  04/15/2008 (htu) - added codes to bump up 'execute immediate' to 64k
  05/05/2008 (htu) - added safe_clob_substr function; simplified the split; 
                     and added dbsm_ddl.create_wrapped option
  08/15/2008 (htu) - added p_skp empty line option      
  12/23/2008 (htu) - added logic to automatically output file if code is large
  12/24/2008 (htu) - commented out the 64k code block
  01/05/2009 (htu) - made p_ofn to be used even p_out = 1
  ---------
  02/25/2009 (htu) - only echo code when p_lvl > 2 and compiling failed
  ---------------
  05/13/2010 (htu) - added dbms_lob.isopen in the exception block
*/

PROMPT 
PROMPT Create procedure sp_output_sp
CREATE OR REPLACE PROCEDURE sp_output_sp (
  s      CLOB,                     -- SQL statements
  p_ofn  VARCHAR2 DEFAULT NULL,    -- output file name
  p_out  INTEGER  DEFAULT 0,       -- output options
  p_dir  VARCHAR2 DEFAULT NULL,    -- output directory
  p_opt  INTEGER  DEFAULT 0,       -- file: 0 - new/ow; 1 - append
  p_skp  INTEGER  DEFAULT 0,       -- skip empty lines: 0-no; 1-yes  
  p_lvl  INTEGER  DEFAULT 0        -- message level    
) IS
  v_prg  VARCHAR2(100) := 'sp_output_sp';
  x      VARCHAR2(4000);
  len    NUMBER;
  n      NUMBER;
  m      NUMBER;
  c      NUMBER;
  s1     LONG;
  s2     LONG;
  cr     CHAR(1) := CHR(10);   -- new line
  msg    VARCHAR2(200);
  v_ofn  VARCHAR2(200);
  v_dir  VARCHAR2(1000);
  v_dft  VARCHAR2(100) := 'YYYYMMDD_HH24MISS';

  PROCEDURE echo ( msg clob, lvl NUMBER DEFAULT 999 ) IS
  BEGIN
    IF lvl <= p_lvl THEN dbms_output.put_line(msg); END IF;
  END;

  FUNCTION safe_clob_substr (
    lob_loc IN CLOB ,
    amount  IN NUMBER DEFAULT 32767, 
    offset  IN NUMBER DEFAULT 1
  ) RETURN VARCHAR2
  AS 
    tmp_store  VARCHAR2(32767) := '';
    tmp_amount NUMBER := amount;
    tmp_offset NUMBER := offset;
  BEGIN
    IF tmp_amount > 8191 THEN
      WHILE tmp_amount > 8191 LOOP
        tmp_store := tmp_store||
                     dbms_lob.substr(lob_loc, 8191 , tmp_offset);
        tmp_amount := tmp_amount-8191;
        tmp_offset := tmp_offset+8191;
      END LOOP;
    END IF;
    tmp_store := tmp_store||
                 dbms_lob.substr(lob_loc, tmp_amount , tmp_offset);
    RETURN tmp_store;
  END safe_clob_substr;

BEGIN
  IF p_out = 0 THEN 
    RETURN; 
  END IF;
  v_dir := p_dir;
  IF v_dir IS NULL THEN
    v_dir := 'c:/temp';
  END IF;
  IF p_ofn IS NULL THEN
    v_ofn := 'f_'||sys_context('USERENV','SESSIONID')||'_' 
           ||TO_CHAR(sysdate,v_dft)||'.sql';
  ELSE
    v_ofn := p_ofn; 
  END IF;
  n := dbms_lob.getlength(s);
  msg := 'INFO('||v_prg||'): '||TO_CHAR(n)||' characters.';
  echo(msg, 1);
  -- echo(s, 5); 
  dbms_output.enable(1000000); 
  IF p_out = 1 OR p_out > 5 THEN
    IF n < 32767 THEN
      echo('INFO('||v_prg||'): executing codes (1)...', 1);
      s1  := safe_clob_substr(s);
      m   := LENGTH(s1);
      msg := 'INFO('||v_prg||'): '||TO_CHAR(m)||'/'||TO_CHAR(n)||' characters.';
      echo(msg, 1);
      echo(s1,3);
      EXECUTE IMMEDIATE s1; 
      msg := 'INFO('||v_prg||'): Codes in '||p_ofn||' were executed.';
/*      
    ELSIF n < 65533 THEN
      echo('INFO('||v_prg||'): executing codes (2)...', 1);
      s1  := safe_clob_substr(s);
      s2  := safe_clob_substr(s,32766,32767);
      m   := LENGTH(s1)+LENGTH(s2);
      msg := 'INFO('||v_prg||'): '||TO_CHAR(m)||'/'||TO_CHAR(n)||' characters.';
      echo(msg, 1);
      echo(s1,3);
      echo(s2,3);
      EXECUTE IMMEDIATE s1||s2; 
      msg := 'INFO('||v_prg||'): Codes in '||p_ofn||' was executed.';
*/
    ELSE
      msg := 'ERR('||v_prg||'): ';
      msg := msg||'skipped due to stmt is too long('||TO_CHAR(n)||').'||cr;
      msg := msg||'Please run - '||v_ofn||' manually in '||cr||v_dir||'.';
      sp_wrt2file_sp(p_sql=>s,p_ofn=>v_ofn,p_dir=>v_dir,p_opt=>p_opt,p_skp=>p_skp);
      x := '/'||cr;        
      sp_wrt2file_sp(p_sql=>x,p_ofn=>v_ofn,p_dir=>v_dir,p_opt=>1,p_skp=>p_skp);
      echo('INFO('||v_prg||'): File '||v_ofn||' was created.',1);
    END IF;
    echo(msg,1);
  END IF; 

  IF p_out = 2 OR p_out > 5 THEN
    sp_wrt2file_sp(p_sql=>s,p_ofn=>v_ofn,
      p_dir=>v_dir,p_opt=>p_opt,p_skp=>p_skp);
    echo('INFO('||v_prg||'): File '||v_ofn||' was created.',1);
  END IF; 

  IF p_out = 3 OR p_out > 5 THEN
    IF n < 4000 THEN
      sp_email_sp(s);
    ELSE
      msg := 'INFO('||v_prg||'): text is '||TO_CHAR(n)||' characters long'; 
      sp_email_sp(msg);
    END IF;
  END IF; 

  IF p_out = 4 OR p_out > 9 THEN
    dbms_output.enable(1000000); 
    IF n < 4000 THEN 
      echo(s,1);
    ELSE
      msg := 'INFO('||v_prg||'): text is '||TO_CHAR(n)||' characters long';
      echo(msg,1);
    END IF; 
  END IF; 

  IF p_out = 5 OR p_out > 5 THEN
    IF n < 32767 THEN
      echo('INFO('||v_prg||'): executing codes (1)...', 1);
      s1  := safe_clob_substr(s);
      m   := LENGTH(s1);
      msg := 'INFO('||v_prg||'): '||TO_CHAR(m)||'/'||TO_CHAR(n)||' characters.';
      echo(msg, 1);
      BEGIN
        sys.dbms_ddl.create_wrapped(s1); 
        msg := 'INFO('||v_prg||'): Codes in '||p_ofn||' were wrapped and executed.';
        EXCEPTION  
        WHEN OTHERS THEN  
        BEGIN
          echo('ERR('||v_prg||'): '||SQLERRM,0);
          IF p_lvl > 2 THEN  echo(s1, 1); END IF;
        END; 
      END;
/*      
    ELSIF n < 65533 THEN
      echo('INFO('||v_prg||'): executing codes (2)...', 1);
      s1  := safe_clob_substr(s);
      s2  := safe_clob_substr(s,32766,32767);
      m   := LENGTH(s1)+LENGTH(s2);
      msg := 'INFO('||v_prg||'): '||TO_CHAR(m)||'/'||TO_CHAR(n)||' characters.';
      echo(msg, 1);
      BEGIN 
        sys.dbms_ddl.create_wrapped(s1||s2); 
        msg := 'INFO('||v_prg||'): Codes in '||p_ofn||' was wrapped and executed.';
        EXCEPTION  
        WHEN OTHERS THEN   
        BEGIN 
          echo('ERR('||v_prg||'): '||SQLERRM,0);
          echo(s1, 1); 
          echo(s2, 1); 
        END; 
      END;
*/      
    ELSE
      msg := 'ERR('||v_prg||'): ';
      msg := msg||'skipped due to stmt is too long('||TO_CHAR(n)||').'||cr;
      msg := msg||'Please run - '||v_ofn||' manually.';
    END IF;
    echo(msg,1);
  END IF;

  EXCEPTION  
  WHEN OTHERS THEN   
    echo('ERR('||v_prg||'): '||SQLERRM,0);
    IF dbms_lob.isopen(s1) <> 0 THEN dbms_lob.close(s1); END IF;
    IF dbms_lob.isopen(s2) <> 0 THEN dbms_lob.close(s2); END IF;
    -- IF DBMS_SQL.IS_OPEN(c) THEN DBMS_SQL.CLOSE_CURSOR(c); END IF;
    raise;
END;
/

show err

/*
PROMPT 
PROMPT Test procedure sp_output_sp

DECLARE
  s CLOB;
  s1 LONG;
  s2 LONG;
  n NUMBER;
  m NUMBER;
BEGIN
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  s1 := 'BEGIN null; ' || LPAD (' ', 32000, ' ')||' END;';
  n := length(s1); dbms_lob.writeappend(s, n, s1);
  m := LENGTH(DBMS_LOB.SUBSTR(s));
  dbms_output.put_line('N='||TO_CHAR(n)||','||'M='||TO_CHAR(m));
  sp_output_sp(s,p_lvl=>5,p_out=>1); 
  dbms_lob.close(s);
END;
/

*/

/*
@map_sp/src/sp_output_sp.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/map_sp -a wrap src/sp
@map_sp/wrapped/sp_output_sp.plb

DECLARE
  s CLOB;
  s1 LONG;
  s2 LONG;
  n1 NUMBER;
  n2 NUMBER;
  n  NUMBER;
  m  NUMBER;
BEGIN
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  s1 := 'BEGIN null; ' || LPAD (' ', 30000, ' ');
  s2 := LPAD (' ', 30000, ' ')||'END;';
  n1 := length(s1); dbms_lob.writeappend(s, n1, s1);
  n2 := length(s2); dbms_lob.writeappend(s, n2, s2);
  n := n1 + n2;
  m := LENGTH(DBMS_LOB.SUBSTR(s));
  dbms_output.put_line('N='||TO_CHAR(n)||','||'M='||TO_CHAR(m));
  sp_output_sp(s,p_lvl=>5,p_out=>1); 
  dbms_lob.close(s);
END;
/

DECLARE
  s CLOB;
  s1 LONG;
  s2 LONG;
  n1 NUMBER;
  n2 NUMBER;
  n  NUMBER;
  m  NUMBER;
BEGIN
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  s1 := q'!
    create or replace function wrap_test
    return varchar2  
    is  
    begin  
      return 'Yep, it worked';  
    end wrap_test; !';  
  s1 := s1|| LPAD (' ', 30000, ' ');
  n1 := length(s1); dbms_lob.writeappend(s, n1, s1);
  n := n1;
  m := LENGTH(DBMS_LOB.SUBSTR(s));
  dbms_output.put_line('N='||TO_CHAR(n)||','||'M='||TO_CHAR(m));
  sp_output_sp(s,p_lvl=>5,p_out=>5); 
  dbms_lob.close(s);
END;
/

DECLARE
  s CLOB;
  s1 LONG;
  s2 LONG;
  n1 NUMBER;
  n2 NUMBER;
  n  NUMBER;
  m  NUMBER;
  -- v_dir 	varchar2(1000) := 'O:\Client\owb_dir\cpp\outputs';
  v_dir 	varchar2(1000) := 'c:\www';
  v_ofn		varchar2(100)  := 'cpp_test.sql'; 
BEGIN
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  s1 := q'!
    create or replace function wrap_test
    return varchar2  
    is  
    begin  
      return 'Yep, it worked';  
    end wrap_test; !'||chr(10);  
  n1 := length(s1); dbms_lob.writeappend(s, n1, s1);
  n := n1;
  m := LENGTH(DBMS_LOB.SUBSTR(s));
  dbms_output.put_line('N='||TO_CHAR(n)||','||'M='||TO_CHAR(m));
  sp_output_sp(s,p_dir=>v_dir,p_ofn=>v_ofn,p_lvl=>5,p_out=>2); 
  dbms_lob.close(s);
END;
/

DECLARE
  s CLOB;
  s1 LONG;
  s2 LONG;
  n1 NUMBER;
  n2 NUMBER;
  n  NUMBER;
  m  NUMBER;
  v_dir 	varchar2(1000) := '\\octagonresearch\share\Client\owb_dir\cpp\outputs';
  v_ofn		varchar2(100)  := 'cpp_test.sql'; 
BEGIN
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  s1 := q'!
    create or replace function wrap_test
    return varchar2  
    is  
    begin  
      return 'Yep, it worked';  
    end wrap_test; !'||chr(10);  
  n1 := length(s1); dbms_lob.writeappend(s, n1, s1);
  n := n1;
  m := LENGTH(DBMS_LOB.SUBSTR(s));
  dbms_output.put_line('N='||TO_CHAR(n)||','||'M='||TO_CHAR(m));
  sp_output_sp(s,p_dir=>v_dir,p_ofn=>v_ofn,p_lvl=>5,p_out=>2); 
  dbms_lob.close(s);
END;
/



*/

