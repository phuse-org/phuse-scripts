/* $Header: sp_email_sp.sql 1.001 2008/01/03 12:10:10 cc$ 
Copyright (c) 2008 Hanming Tu All Rights Reserved.

PURPOSE
  This stored procedure sends email through a mail server

NOTES
  1. Run this PL/SQL while logged-in as the owner of compliance check
  2. Run it after the underline tables are created. 

HISTORY   MM/DD/YYYY (developer) 
  01/03/2008 (htu) - initial creation 
  01/23/2008 (htu) - changed to use dbms_output and v_prg   
  10/13/2010 (htu) - added CHR(13) to CR
*/

CREATE OR REPLACE PROCEDURE sp_email_sp (
  p_msg   VARCHAR2 DEFAULT NULL,   -- email message body  
  p_to    VARCHAR2 DEFAULT NULL,   -- email to 
  p_from  VARCHAR2 DEFAULT NULL,   -- email from 
  p_subj  VARCHAR2 DEFAULT NULL,   -- email subject
  p_cc    VARCHAR2 DEFAULT NULL,   -- email cc
  p_bcc   VARCHAR2 DEFAULT NULL,
  p_svr   VARCHAR2 DEFAULT NULL
) IS
  v_prg   VARCHAR2(100) := 'sp_email_sp';
  s       LONG;
  v_to    VARCHAR2(80) := 'htu@octagonresearch.com';
  v_from  VARCHAR2(80) := NULL;  
  v_cc    VARCHAR2(80) := NULL;
  v_bcc   VARCHAR2(80) := 'htu@octagonresearch.com';
  v_subj  VARCHAR2(100);
  v_dbn   VARCHAR2(50) := sys_context('USERENV','DB_NAME');
  v_dbd   VARCHAR2(50) := sys_context('USERENV','DB_DOMAIN');
  v_conn  UTL_SMTP.CONNECTION;
  v_svr   VARCHAR2(50); 
  crlf    VARCHAR2(5) := CHR(13)||CHR(10);
  cr      VARCHAR2(5) := CHR(13);
  lf      VARCHAR2(5) := CHR(10);
  v_msg   VARCHAR2(2000);
BEGIN
  IF p_msg IS NULL     THEN 
      dbms_output.put_line('ERR('||v_prg||'): No message is specified');
      RETURN;       
  END IF;
  IF p_to  IS NOT NULL THEN v_to := p_to; END IF;
  IF v_dbd IS NULL THEN v_dbd := 'octagonresearch.com'; END IF;
  IF p_from IS NULL THEN
      v_from := LOWER(USER||'@'||v_dbn||'.'||v_dbd);
  ELSE
      v_from := p_from;
  END IF;
  IF p_subj IS NULL THEN
      v_subj := '[WB JOB]: '||TO_CHAR(sysdate, 'YYYYMMDD.HH24MISS'); 
  ELSE
      v_subj := p_subj; 
  END IF;
  IF p_svr IS NULL THEN 
      v_svr := sys_context('USERENV','DB_DOMAIN');
  ELSE
      v_svr := p_svr;
  END IF;
  IF v_svr IS NULL THEN
      dbms_output.put_line('ERR('||v_prg||'): No mail server is specified');
      RETURN;
  END IF;
  v_msg := TO_CHAR(sysdate,'MM/DD/YYYY HH24:MI:SS');
  s :=    'Subject: '||v_subj||lf;
  s := s||'From: '||v_from||lf;
  s := s||'Date: '||v_msg||lf;
  s := s||'To:   '||v_to||lf;
  IF v_cc IS NOT NULL THEN s := s||'CC:  '||v_cc ||lf; END IF;
  IF v_to <> v_bcc    THEN s := s||'BCC: '||v_bcc||lf; END IF;
  s := s||lf||lf||p_msg||lf||lf;
  s := s||'----------------------------'||cr;
  s := s||'Sent By  : sp_email at '||v_msg||cr;
  s := s||'DB Name  : '||v_dbn||cr;
  s := s||'DB Domain: '||v_dbd||cr;
  s := s||'Module   : '||sys_context('USERENV','MODULE')||cr;
  s := s||'Program  : '||sys_context('USERENV','ACTION')||cr;  
  v_conn := UTL_SMTP.OPEN_CONNECTION(v_svr,25);
  UTL_SMTP.HELO(v_conn,v_svr);
  UTL_SMTP.MAIL(v_conn,v_to);
  UTL_SMTP.RCPT(v_conn,v_to);
  UTL_SMTP.DATA(v_conn,s);
  UTL_SMTP.QUIT(v_conn);

  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('ERR('||v_prg||'): '||SQLERRM);
END;
/

show err

/*
@cmdr/v300a/all_sqls/cc5006_email_sp.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/cmdr/v300a -a wrap all_sqls/cc5006
@cmdr/v300a/wrapped/cc5006_email_sp.plb



-- for Oracle 11g
SELECT any_path FROM resource_view WHERE any_path like '/sys/acls/%.xml';

COLUMN host 	FORMAT A25
COLUMN acl 	FORMAT A25
SELECT host, lower_port, upper_port, acl
  FROM dba_network_acls;


COLUMN acl 		FORMAT A25
COLUMN principal 	FORMAT A20
SELECT acl,
       principal,
       privilege,
       is_grant,
       TO_CHAR(start_date, 'DD-MON-YYYY') AS start_date,
       TO_CHAR(end_date, 'DD-MON-YYYY') AS end_date
FROM   dba_network_acl_privileges;

COLUMN host FORMAT A20
SELECT host, lower_port, upper_port, privilege, status
FROM   user_network_acl_privileges;

SELECT host,
       lower_port,
       upper_port,
       acl,
       DECODE(
         DBMS_NETWORK_ACL_ADMIN.check_privilege_aclid(aclid,  'CC_300A', 'resolve'),
         1, 'GRANTED', 0, 'DENIED', null) PRIVILEGE
FROM   dba_network_acls
WHERE  host IN (SELECT *
                FROM   TABLE(DBMS_NETWORK_ACL_UTILITY.domains('192.168.10.6')))
ORDER BY 
       DBMS_NETWORK_ACL_UTILITY.domain_level(host) desc, lower_port, upper_port;


exec DBMS_NETWORK_ACL_ADMIN.drop_acl (acl => 'orsmail.xml');

DECLARE
  v_xml 	varchar2(200)	:= 'orsmail.xml';
  v_dsc		varchar2(1000)	:= 'Network permissions for your_company.com'; 
  v_sch		varchar2(100)	:= 'CC_300A'; 
  v_host	varchar2(100)	:= '192.168.10.6';
BEGIN
  dbms_network_acl_admin.create_acl(
      acl         => v_xml
    , description => v_dsc
    , principal   => v_sch
    , is_grant 	  => TRUE
    , privilege   => 'connect'
    , start_date  => null
    , end_date	  => null
    );
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
      acl         => v_xml
    , principal   => v_sch
    , is_grant    => true
    , privilege   => 'resolve'
    );
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
      acl         => v_xml
    , host        => v_host
    );
  commit;
END;
/


exec sp_email_sp('Test Body: http://ors2di/cgi/cpp2.pl/', 'htu@gmail.com',p_svr=>'192.168.10.6');



sys@db> desc dbms_network_acl_admin
PROCEDURE ADD_PRIVILEGE
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN
 PRINCIPAL                      VARCHAR2                IN
 IS_GRANT                       BOOLEAN                 IN
 PRIVILEGE                      VARCHAR2                IN
 POSITION                       BINARY_INTEGER          IN     DEFAULT
 START_DATE                     TIMESTAMP WITH TIME ZONE IN     DEFAULT
 END_DATE                       TIMESTAMP WITH TIME ZONE IN     DEFAULT
PROCEDURE ASSIGN_ACL
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN
 HOST                           VARCHAR2                IN
 LOWER_PORT                     BINARY_INTEGER          IN     DEFAULT
 UPPER_PORT                     BINARY_INTEGER          IN     DEFAULT
PROCEDURE ASSIGN_WALLET_ACL
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN
 WALLET_PATH                    VARCHAR2                IN
FUNCTION CHECK_PRIVILEGE RETURNS NUMBER
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN
 USER                           VARCHAR2                IN
 PRIVILEGE                      VARCHAR2                IN
FUNCTION CHECK_PRIVILEGE_ACLID RETURNS NUMBER
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACLID                          RAW                     IN
 USER                           VARCHAR2                IN
 PRIVILEGE                      VARCHAR2                IN
PROCEDURE CREATE_ACL
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN
 DESCRIPTION                    VARCHAR2                IN
 PRINCIPAL                      VARCHAR2                IN
 IS_GRANT                       BOOLEAN                 IN
 PRIVILEGE                      VARCHAR2                IN
 START_DATE                     TIMESTAMP WITH TIME ZONE IN     DEFAULT
 END_DATE                       TIMESTAMP WITH TIME ZONE IN     DEFAULT
PROCEDURE DELETE_PRIVILEGE
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN
 PRINCIPAL                      VARCHAR2                IN
 IS_GRANT                       BOOLEAN                 IN     DEFAULT
 PRIVILEGE                      VARCHAR2                IN     DEFAULT
PROCEDURE DROP_ACL
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN
PROCEDURE HANDLEPREDELETE
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 EVENT                          RAW(32)                 IN
PROCEDURE UNASSIGN_ACL
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN     DEFAULT
 HOST                           VARCHAR2                IN     DEFAULT
 LOWER_PORT                     BINARY_INTEGER          IN     DEFAULT
 UPPER_PORT                     BINARY_INTEGER          IN     DEFAULT
PROCEDURE UNASSIGN_WALLET_ACL
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 ACL                            VARCHAR2                IN     DEFAULT
 WALLET_PATH                    VARCHAR2                IN     DEFAULT


*/
