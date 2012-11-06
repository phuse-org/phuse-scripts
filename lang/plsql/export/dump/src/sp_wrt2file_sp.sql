/* $Header: sp_wrt2file_sp.sql 1.001 2008/01/03 12:10:10 cc$ 
Copyright (c) 2008 Hanming Tu All Rights Reserved.

PURPOSE
  This stored procedure writes the content to a file

NOTES
  1. Make sure the output directory is defined in the database

HISTORY   MM/DD/YYYY (developer) 
  01/03/2008 (htu) - initial creation 
                     p_opt: 0 - overwrite; 1 - append
  01/23/2008 (htu) - changed to use dbms_output and v_prg 
  03/20/2008 (htu) - added cc_ name space
  08/15/2008 (htu) - added p_skp empty line option
                     0-no, we keep them
                     1-yes, we remove them
  09/02/2008 (htu) - skip lines even if they have space or tabs
  ---------------
  05/13/2010 (htu) - added dbms_lob.isopen in the exception block
  08/19/2010 (htu) - added 32767 to utl_file.fopen
  01/28/2011 (htu) - 
    1. added  is_not_empty := 0 ;
    2. added IF dbms_lob.INSTR(p_sql, chr(10), i) > 0 THEN
*/

CREATE OR REPLACE PROCEDURE sp_wrt2file_sp (
  p_sql  CLOB,                     -- SQL statements
  p_ofn  VARCHAR2 DEFAULT NULL,    -- output file name
  p_dir  VARCHAR2 DEFAULT NULL,    -- output directory
  p_opt  INTEGER  DEFAULT 0,       -- output options
  p_skp  INTEGER  DEFAULT 0,       -- skip empty lines: 0-no; 1-yes
  p_lvl  INTEGER  DEFAULT 0        -- message level      
) IS
  v_sql  VARCHAR2(2000);
  v_msg  VARCHAR2(2000); 
  v_prg  VARCHAR2(100) := 'sp_wrt2file_sp';
  s      VARCHAR2(4000); 
  n      NUMBER;
  i      NUMBER  := 1;
  is_not_empty number := 0; 
  v_ofn  utl_file.file_type;
  v_dir  VARCHAR2(200) := './';
  v_fnm  VARCHAR2(200) := 'f'||TO_CHAR(sysdate,'YYYYMMDD_HH24MISS')||'.sql';
  v_opt  VARCHAR2(5)   := 'W';
  amt    NUMBER := 32000;
  msz    NUMBER := 4000;
  
  PROCEDURE echo ( msg clob, lvl NUMBER DEFAULT 999 ) IS
  BEGIN
    IF lvl <= p_lvl THEN dbms_output.put_line(msg); END IF;
  END;
  
BEGIN 
  IF p_dir IS NOT NULL THEN  
    v_dir := p_dir;
  ELSE
    echo('ERR('||v_prg||'): missing directory (p_dir)',0);
    RETURN;
  END IF;
  IF p_ofn IS NOT NULL THEN
     v_fnm := p_ofn;
  END IF;
  IF p_opt = 1 THEN v_opt := 'A'; END IF;
  v_ofn := utl_file.fopen(v_dir,v_fnm, v_opt, 32767);
  n     := DBMS_LOB.getLength(p_sql);

  WHILE i < n 
  LOOP
    IF dbms_lob.INSTR(p_sql, chr(10), i) > 0 THEN 
      amt := dbms_lob.INSTR(p_sql, chr(10), i) - i;
    ELSE
      amt := n - i ; 
    END IF; 
    echo('INFO('||v_prg||'): i='||i||',amt='||amt||',n='||n,3);
    is_not_empty := 0 ;
    IF amt > 0 THEN
      dbms_lob.read(p_sql,amt,i,s);
      is_not_empty := LENGTH(REGEXP_REPLACE(s,'[ '||chr(9)||chr(10)||chr(13)||']')); 
      IF is_not_empty > 0 OR p_skp = 0 THEN
        utl_file.put_line(v_ofn,s);
      END IF;
    ELSE
      IF p_skp < 1 THEN
        utl_file.put_line(v_ofn,'');
      END IF;
    END IF;
    echo(s, 5); 
    -- set the start position for the next cut
    i := i + amt+1;
    -- set the end position if less than 2000 bytes
  END LOOP;
  utl_file.fclose(v_ofn);

  <<end_all>>
  IF p_opt = 0 THEN
    echo('File - '||v_fnm||' was written to '||v_dir||'.',0);
  END IF; 

  EXCEPTION WHEN OTHERS THEN   
    -- IF dbms_lob.isopen(s) <> 0 THEN dbms_lob.close(s); END IF;
    echo('ERR('||v_prg||'): '||SQLERRM,0);  
    raise;
END;
/

show err

/*  
@map_sp/src/sp_wrt2file_sp.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/map_sp -a wrap src/sp_wrt2file
@map_sp/wrapped/sp_wrt2file_sp.plb

-- Test case:
declare
  s      CLOB := EMPTY_CLOB;   
  x      VARCHAR2(4000);
  len    NUMBER;
  cr     CHAR(1) := CHR(10);   -- new line
begin 
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  x := 'Test OCTA_SEQ  VARCHAR2(200 BYTE)'||cr;
  x := x||'Test2'||cr;
  len := length(x); dbms_lob.writeappend(s, len, x);
  sp_wrt2file_sp(p_sql=>s,  p_ofn=>'xx_test.txt', p_dir=>'/opt/ora/ufd/owb1');
end;
/

declare
  s      CLOB := EMPTY_CLOB;   
  x      VARCHAR2(4000);
  len    NUMBER;
  cr     CHAR(1) := CHR(10);   -- new line
begin 
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  x := 'Test OCTA_SEQ  VARCHAR2(200 BYTE)'||cr;
  x := x||'Test2'||cr;
  len := length(x); dbms_lob.writeappend(s, len, x);
  sp_wrt2file_sp(p_sql=>s,  p_ofn=>'xx_test.txt', p_dir=>'c:/www');
end;
/

declare
  s      CLOB := EMPTY_CLOB;   
  x      VARCHAR2(4000);
  len    NUMBER;
  cr     CHAR(1) := CHR(10);   -- new line
begin 
  dbms_lob.createtemporary(s, TRUE);
  dbms_lob.open(s, dbms_lob.lob_readwrite);
  x := 'Test OCTA_SEQ  VARCHAR2(200 BYTE)'||cr;
  x := x||'Test2 '||cr;
  x := x||'Test3 ';
  len := length(x); dbms_lob.writeappend(s, len, x);
  sp_wrt2file_sp(p_sql=>s,  p_ofn=>'xx_test.txt', p_lvl=> 5, 
  p_dir=>'\\octagonresearch/share/Client/owb_dir/cpp/outputs');
  IF dbms_lob.isopen(s) <> 0 THEN dbms_lob.close(s); END IF;
end;
/


*/
