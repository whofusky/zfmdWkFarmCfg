alter PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME 90;
select LIMIT from DBA_PROFILES where PROFILE='DEFAULT' and RESOURCE_NAME='PASSWORD_LIFE_TIME';
alter user zfmd identified by "0796-Gls";
col USERNAME format a16;
col ACCOUNT_STATUS format a16;
col EXPIRY_DATE format a20;
select USERNAME, EXPIRY_DATE from dba_users where ACCOUNT_STATUS='OPEN';

--2,
--
grant connect,resource to zfmd
revoke dba from zfmd;

--3,Modify database link number to 80.
--Must restart for use.
show parameter processes;
show parameter sessions;
alter system set processes=80 scope=spfile;
alter system set sessions=100 scope=spfile;

--4,
select * from dba_profiles s where s.profile='DEFAULT' and resource_name='FAILED_LOGIN_ATTEMPTS';
alter profile default limit failed_login_attempts 5;
select * from dba_profiles s where s.profile='DEFAULT' and resource_name='FAILED_LOGIN_ATTEMPTS';

select * from dba_profiles s where s.profile='DEFAULT' and resource_name='PASSWORD_LOCK_TIME';
alter profile default limit password_lock_time 10;
select * from dba_profiles s where s.profile='DEFAULT' and resource_name='PASSWORD_LOCK_TIME';

--5,Aud
audit insert on zfmd.utf_frm;
audit update on zfmd.utf_frm;
audit delete on zfmd.utf_frm;
audit insert on zfmd.stf_frm;
audit update on zfmd.stf_frm;
audit delete on zfmd.stf_frm;
audit insert on zfmd.stf_tbn;
audit update on zfmd.stf_tbn;
audit delete on zfmd.stf_tbn;
audit insert on zfmd.tss_tbn_1mi;
audit update on zfmd.tss_tbn_1mi;
audit delete on zfmd.tss_tbn_1mi;
audit insert on zfmd.tss_tbn_5mi;
audit update on zfmd.tss_tbn_5mi;
audit delete on zfmd.tss_tbn_5mi;
audit insert on zfmd.tss_tbn_15mi;
audit update on zfmd.tss_tbn_15mi;
audit delete on zfmd.tss_tbn_15mi;
audit insert on zfmd.int_frm_1mi;
audit update on zfmd.int_frm_1mi;
audit delete on zfmd.int_frm_1mi;
audit insert on zfmd.int_frm_5mi;
audit update on zfmd.int_frm_5mi;
audit delete on zfmd.int_frm_5mi;
audit insert on zfmd.int_frm_15mi;
audit update on zfmd.int_frm_15mi;
audit delete on zfmd.int_frm_15mi;
audit insert on zfmd.amt_wnd_1mi;
audit update on zfmd.amt_wnd_1mi;
audit delete on zfmd.amt_wnd_1mi;
audit insert on zfmd.amt_wnd_5mi;
audit update on zfmd.amt_wnd_5mi;
audit delete on zfmd.amt_wnd_5mi;
audit insert on zfmd.amt_wnd_15mi;
audit update on zfmd.amt_wnd_15mi;
audit delete on zfmd.amt_wnd_15mi;
select returncode, action#, userid, userhost, terminal,timestamp# from sys.aud$; 
