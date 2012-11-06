/* $Header: cc2010_pkg.sql 1.001 2008/01/04 12:10:10 cc$ 
Copyright (c) 2008 Hanming Tu All Rights Reserved.

PURPOSE
  This package contains all the configuraton and setup
  parameters.

PROGRAMS CALLED

NOTES

HISTORY   MM/DD/YYYY (developer) 
  ---------
  11/29/2010 (htu) - initial creation from cc2010_pkg.sql
  02/08/2011 (htu) - added begin/end in get_configvar
  06/14/2011 (htu) - break the msg into 255 chunk in echo (dbms_output limitation)
                   - updated echo procedure to break lines in spaces
                     
*/

/* ********** Package Specification **********

*/
CREATE OR REPLACE PACKAGE sp_pkg
AS
    -- output record type
    TYPE rst_refcur 	IS REF CURSOR;
    TYPE err_refcur 	IS REF CURSOR;

  ---------- Global variables -----------------------------------------------
    g_pkg   	VARCHAR2(100) 	:= 'sp_pkg';  		-- package name
    g_cr    	CHAR(1) 	:= CHR(10);         	-- new line
    g_num   	NUMBER  	:= 0;               	-- number
    g_msg   	VARCHAR2(2000) 	:= ''; 		    	-- varchar2
    g_jid   	NUMBER  	:= 0; 			-- job id
    g_cid	NUMBER		:= 0;			-- check id
    g_schema	VARCHAR2(100)	:= NULL;		-- schema name
    g_verify	NUMBER		:= 1;			-- to verify keys
    g_msg_lvl   NUMBER 		:= 0;            	-- message level
    g_log_lvl   NUMBER 		:= 0;           	-- log level

    
  ---------- FUNCTIONS  -----------------------------------------------------
  FUNCTION user_exist 	( p_user VARCHAR2 )   RETURN BOOLEAN;
  FUNCTION get_configvar (p_name IN VARCHAR2) RETURN VARCHAR2;
  
  ---------- PROCEDURES  ----------------------------------------------------
  PROCEDURE echo (
      msg clob
    , lvl NUMBER DEFAULT 999
  ); 
  PROCEDURE init; 
  PROCEDURE chk_objects (
      p_objs		IN	VARCHAR2           	-- t1:o1,o2;t2:o3,o4
    , p_status		IN OUT  NUMBER			-- status
  ); 
  PROCEDURE log (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log level 
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step message
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
    , p_type	IN	VARCHAR2 DEFAULT NULL		-- error type
  ); 
  PROCEDURE log_err (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log/msg level
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step message
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
  );
  PROCEDURE log_info (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log/msg level
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step message
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
  );
  PROCEDURE log2info (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log/msg level
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step msg
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
    , p_step	OUT	NUMBER
  );

END sp_pkg;
/

show err

/* ********** Package Body **********
*/
CREATE OR REPLACE PACKAGE BODY sp_pkg
IS

---------- FUNC: user_exist  ------------------------------------------------
FUNCTION user_exist (
    p_user VARCHAR2
) RETURN BOOLEAN 
IS
  v_prg VARCHAR2(100) := g_pkg||'.user_exist';
  CURSOR c1 IS 
    SELECT username 
      FROM dba_users
     WHERE username = UPPER(p_user);
  v_usr 		dba_users.username%TYPE;
BEGIN
  IF NOT c1%ISOPEN THEN OPEN c1; END IF;
  FETCH c1 INTO v_usr;
  CLOSE c1;
  IF v_usr IS NULL THEN RETURN FALSE; ELSE RETURN TRUE; END IF;

  EXCEPTION  
  WHEN OTHERS THEN   
    dbms_output.put_line('ERR('||v_prg||'): '||SQLERRM);  
END;

---------- FUNC: get_configvar  ---------------------------------------------
FUNCTION get_configvar (p_name IN VARCHAR2)
RETURN VARCHAR2
IS
  v_out   VARCHAR2 (4000);
BEGIN
  BEGIN
    SELECT cfgvar_value INTO v_out FROM sp_cfgvars
     WHERE UPPER(cfgvar_name) = UPPER(p_name);
    EXCEPTION WHEN OTHERS THEN v_out := null; 
  END; 
  RETURN v_out;
END;


--#########################################################################--

---------- PROC: init -------------------------------------------------------
PROCEDURE init 
IS
  v_prg 	VARCHAR2(100) := g_pkg||'.init';
  v_num		NUMBER; 
BEGIN
  sp_pkg.g_schema  := sp_pkg.get_configvar('COMPLYCHK_SCHEMA');
  v_num 	   := TO_NUMBER(sp_pkg.get_configvar('LOG_VERIFICATION'));
  sp_pkg.g_verify  := NVL(v_num, sp_pkg.g_verify);
  v_num 	   := TO_NUMBER(sp_pkg.get_configvar('LOG_LEVEL'));
  sp_pkg.g_log_lvl := NVL(v_num, sp_pkg.g_log_lvl);
  v_num 	   := TO_NUMBER(sp_pkg.get_configvar('MSG_LEVEL'));
  sp_pkg.g_msg_lvl := NVL(v_num, sp_pkg.g_msg_lvl);

  -- sp_pkg.echo(LPAD('COMPLYCHK_SCHEMA',24,' ')||': '||sp_pkg.g_schema, 1); 
  -- sp_pkg.echo(LPAD('LOG_VERIFICATION',24,' ')||': '||to_char(sp_pkg.g_verify), 1); 
  sp_pkg.echo(LPAD('LOG_LEVEL',24,' ')||': '||to_char(sp_pkg.g_log_lvl), 1); 
  sp_pkg.echo(LPAD('MSG_LEVEL',24,' ')||': '||to_char(sp_pkg.g_msg_lvl), 1); 
  sp_pkg.echo(LPAD('G_JID',24,' ')||': '||to_char(sp_pkg.g_jid), 1); 
  
  EXCEPTION WHEN OTHERS THEN
    sp_pkg.echo('ERR('||v_prg||'): '||SQLERRM,0); 
END;

---------- PROC: echo -------------------------------------------------------
PROCEDURE echo ( msg clob, lvl NUMBER DEFAULT 999 ) IS
  v_tot number 		:= length(msg); 
  v_pos number 		:= 1;
  v_msg varchar2(32767)	; 
  v_cnt number 		:= 0; 
  v_amt number 		:= 0; 
  v_ps2 number 		:= 1; 
  v_am2 number 		:= 0; 
  v_cn2 number		:= 0; 
BEGIN
  IF lvl <= g_msg_lvl THEN
    while (v_pos <= v_tot and v_cnt < 50000) loop
      IF INSTR(msg, chr(10), v_pos) > 0 THEN 
        v_amt := INSTR(msg, chr(10), v_pos) - v_pos;
      ELSE
        v_amt := v_tot - v_pos + 1; 
      END IF; 
      -- dbms_output.put_line('pos='||v_pos||',amt='||v_amt);                 
      v_msg := substr(msg,v_pos, v_amt); 
      IF v_amt > 255 THEN
        -- dbms_output.put_line(v_msg);                 
        while (length(v_msg) > 0 AND v_cn2 < 1000) loop 
          -- from the 255 char search backward
          v_ps2 := instr(substr(v_msg,1,255),chr(32), -1);  	-- check space
          IF v_ps2 = 0 THEN 
            v_ps2 := instr(substr(v_msg,1,255), chr(62), -1); 	-- check '>'
          END IF; 
          IF v_ps2 = 0 THEN 
            v_ps2 := instr(substr(v_msg,1,255), chr(59), -1); 	-- check ';'
          END IF; 
          IF v_ps2 = 0 OR v_ps2 > 255 THEN
            v_am2 := 255; v_ps2 := 256; 
          ELSE
            v_am2 := v_ps2; v_ps2 := v_ps2+1; 
          END IF; 
          -- dbms_output.put_line('ps2='||v_ps2||',am2='||v_am2);  
          dbms_output.put_line(substr(v_msg,1, v_am2));
          v_msg := substr(v_msg,v_ps2);  
          v_cn2 := v_cn2 + 1;
        end loop; 
      ELSE
        dbms_output.put_line(v_msg); 
      END IF; 
      v_cnt := v_cnt + 1; 		-- so that it will not go into infinite loop
      v_pos := v_pos + v_amt; 
      IF INSTR(msg, chr(10), v_pos) > 0 THEN v_pos := v_pos + 1; END IF; 
    end loop;
  END IF;
END;

---------- PROC: chk_objects  -----------------------------------------------
PROCEDURE chk_objects (
      p_objs		IN	VARCHAR2           	-- t1:o1,o2;t2:o3,o4
    , p_status		IN OUT  NUMBER			-- status
) IS
  v_prg 	VARCHAR2(100) 	:= g_pkg||'.chk_objects';
  v_msg 	VARCHAR2(2000);
  v_cnt		NUMBER		:= 0;
  v_own		VARCHAR2(100)	:= USER;
  v_objs	VARCHAR2(2000);
  v_type	VARCHAR2(50);
  a		sp_vctab_tp; 
  b		sp_vctab_tp; 
  c		sp_vctab_tp; 
BEGIN
  -- U:usr;T:tb1,tb2;V:vw1,vw2;P:pkg1,pkg2
  -- remove all the spaces in the p_objs
  v_objs := UPPER(REGEXP_REPLACE(p_objs,'( ){1,}','')); 

  a 	:= sp_fn.get_list(v_objs,';'); 
  FOR i IN a.FIRST..a.LAST LOOP
    b	:= sp_fn.get_list(a(i),':');
    IF b(1) IN ('U','USER','SCHEMA') THEN
      IF sp_pkg.user_exist(b(2)) THEN
        v_msg := 'Find user - '||b(2); 
        sp_pkg.echo(v_msg, 3);  
      ELSE
        v_cnt := v_cnt + 1;
      END IF;
      v_own := NVL(b(2), USER); 
      GOTO next_obj;
    END IF;
    SELECT CASE 
    	   WHEN b(1) IN ('T','TBL','TABLE') 		THEN 'TABLE'
           WHEN b(1) IN ('V','VW','VIEW')  		THEN 'VIEW'
           WHEN b(1) IN ('P','SP','PROC','PROCEDURE') 	THEN 'PROCEDURE'
           WHEN b(1) IN ('K','PKG','PACKAGE')		THEN 'PACKAGE'
           WHEN b(1) IN ('F','FN','FUNC','FUNCTION') 	THEN 'FUNCTION'
           WHEN b(1) IN ('Y','TP','TYPE')		THEN 'TYPE'
           WHEN b(1) IN ('G','TRG','TRIGGER')		THEN 'TRIGGER'
           ELSE NULL
           END
      INTO v_type
      FROM dual;   
    c	:= sp_fn.get_list(b(2),',');
    FOR j IN c.FIRST..c.LAST LOOP
      IF sp_objexist_fn(c(j), v_type, v_own) THEN
        v_msg := 'Find object '||v_type||' - '||c(j); 
        sp_pkg.echo(v_msg, 3);  
      ELSE
        v_cnt := v_cnt + 1;
      END IF;
    END LOOP;
    <<next_obj>>
    NULL;
  END LOOP;
  p_status := v_cnt;

  EXCEPTION  
  WHEN OTHERS THEN
  BEGIN
    sp_pkg.echo('ERR('||v_prg||'): '||SQLERRM,0); 
  END;
END;  

---------- PROC: log --------------------------------------------------------
PROCEDURE log (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log level 
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step message
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
    , p_type	IN	VARCHAR2 DEFAULT NULL		-- error type
) IS 
  PRAGMA 	AUTONOMOUS_TRANSACTION;
  v_prg 	VARCHAR2(100) := g_pkg||'.log';
  v_cnt		NUMBER;
  v_name	varchar2(200)	;
  v_msg		varchar2(4000)	;
  v_errm	varchar2(4000)	;
  v_type	varchar2(20)	;
BEGIN
  IF p_lvl > g_log_lvl THEN  RETURN; END IF;
  IF g_jid IS NULL THEN 
    sp_pkg.echo('INFO('||v_prg||'): job_id is missing.',1); 
    RETURN; 
  END IF;

  v_name  	:= substr(p_name,1, 200);
  v_msg		:= substr(p_msg, 1, 4000);
  v_errm	:= substr(p_errm,1, 4000);
  v_type	:= substr(p_type,1, 20);

  INSERT INTO sp_job_logs (
         log_id, job_id, log_time, log_level, prg_name, 
         step_num, step_msg, err_number, err_msg, err_type
  ) VALUES (
         sp_job_logs_seq.nextval, g_jid, sysdate, p_lvl, v_name, 
         p_num, v_msg, p_code, v_errm, v_type
         );
  commit;

  EXCEPTION WHEN OTHERS THEN
    sp_pkg.echo('ERR('||v_prg||'): '||SQLERRM,0); 
END;

---------- PROC: log_err ----------------------------------------------------
PROCEDURE log_err (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log/msg level
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step message
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
) IS
  v_prg 	VARCHAR2(100) 	:= g_pkg||'.log_err';
  v_code	number		;
BEGIN
  IF p_code IS NULL OR p_code < -20999 OR p_code > -20000 THEN
    v_code := - 20001; 
  ELSE
    v_code := p_code;
  END IF;
  sp_pkg.echo(p_msg, p_lvl);
  sp_pkg.log(p_name, p_msg=>p_msg,   p_type=>'ERR', p_lvl=>p_lvl
    , p_num=>p_num,  p_code=>v_code, p_errm=>p_errm);
  ROLLBACK;
  raise_application_error(v_code, p_errm);
END;

---------- PROC: log_info ---------------------------------------------------
PROCEDURE log_info (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log/msg level
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step message
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
) IS
  v_prg 	VARCHAR2(100) := g_pkg||'.log_info';
BEGIN
  sp_pkg.echo(p_msg, p_lvl);
  sp_pkg.log(p_name, p_msg=>p_msg,   p_type=>'INFO', p_lvl=>p_lvl
      , p_num=>p_num,  p_code=>p_code, p_errm=>p_errm);
  EXCEPTION WHEN OTHERS THEN
    sp_pkg.echo('ERR('||v_prg||'): '||SQLERRM,0);  
END;

---------- PROC: log2info ---------------------------------------------------
PROCEDURE log2info (
      p_name	IN	VARCHAR2           		-- program name
    , p_lvl	IN	NUMBER   DEFAULT 0		-- log/msg level
    , p_num	IN	NUMBER   DEFAULT 1		-- step number
    , p_msg	IN	VARCHAR2 DEFAULT NULL		-- step msg
    , p_code	IN	NUMBER   DEFAULT NULL		-- error number
    , p_errm	IN	VARCHAR2 DEFAULT NULL		-- error message
    , p_step	OUT	NUMBER
) IS
  v_prg 	VARCHAR2(100) 	:= g_pkg||'.log2info';
  v_msg  	VARCHAR2(32676)	;			-- message
BEGIN
  p_step := p_num; 
  v_msg  := 'INFO('||p_name||') '||to_char(p_step)||' - '||p_msg||'...';
  sp_pkg.log_info(p_name,p_msg=>v_msg,p_num=>p_step,p_lvl=>p_lvl
         , p_code=>p_code,p_errm=>p_errm);
  EXCEPTION WHEN OTHERS THEN
    sp_pkg.echo('ERR('||v_prg||'): '||SQLERRM,0);  
END;



END sp_pkg;
/

show err


/*
@map_sp/src/sp_pkg.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/map_sp -a wrap src/sp_pkg
@map_sp/wrapped/sp_pkg.plb

variable n number;
exec sp_pkg.g_msg_lvl := 5;
exec sp_pkg.chk_objects('u:comply2chk;t:dm,ts_final;v:relrec_vw',:n);
print :n


-- test log2info
exec sp_pkg.init;



*/
