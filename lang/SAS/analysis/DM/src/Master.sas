**INCLUDES Determining needed datasets **;
** GROUPING **;
** SUBSET **;
** OUTPUTS **; 
** CALLING PANEL **;
** WORKING ON PANEL OPTIONS ***;
** REVISED DUE TO CHANGES IN GROUPING AND SUBSETTING TABLES ***;

*PROCESSBODY;

*%let runid = 5;

** Section 1 Set Parameters ***;
%let PTH = D:\SL_SAS_Progs\AA_Master_Progs\Master_Logs; * LOCATION OF LOG AND EXIT CODE *;

PROC PRINTTO LOG="&PTH\master_&runid..log" NEW;
RUN;

proc options option=work;
run;
** PROGRAM TO INITIATE THE ORACLE CONNECTION ***;

%include "D:\SL_SAS_Progs\ZZ_Utilities\oracle_reference.sas";

** THESE ARE SYSTEM MACROS THAT ARE TO BE SENT TO PANELS **;
** THESE NEED TO BE CHANGED AFTER A CHANGE IN ENVIRONMENT **;
%put &runid;

%let utilpath = D:\SL_SAS_Progs\ZZ_Utilities;
%let medDRapath = D:\SL_Data\AA1_MedDRA;
%let utildatapath = D:\SL_Data\AA2_Utilities;

** FIRST STEP IS TO READ IN RUN DATA AND SEE WHAT THE OPTIONS ARE TO KNOW WHAT CODE NEEDS TO BE RUN **;

** Section 2 Determine Datasets for Input **;
proc sql;
  update oracon.AT_ANALYSIS_RUN
  set ar_status_cd = "2"
  where ar_id = &runid. 
  ;
quit;

proc sql;
  create table flags
  as select *
  from oracon.AT_ANALYSIS_RUN
  where ar_id = &runid.  
  ;
quit;


data _null_;
  set flags;
call symput('group',ar_group_flag);
call symput('subset_flag',ar_subset_flag);
call symput('operator',ar_active_grpsets_operator);
call symput('panel_id',AR_PNL_ID);
call symput('ndabla',compress(ar_nda_id));
call symput('studyid',trim(ar_stdy_id));
run;


** DETERMINE WHICH ARE THE REQUIRED DATASETS **;

proc sql;
  create table req_data
  as select * 
  from flags f, oracon.at_panel_req_dataset_types d
  where ar_pnl_id = pnlds_pnl_id
  ;
quit;

** NOW MERGE ON THE ONE THAT IS USED IN THE ANALSYSIS RUN ***;

proc sql;
  create table actual_data
  as select distinct dads_custom_flag, dads_dst_cd, dads_name, DADS_FILE_PATH_LOC 
  from req_data, oracon.at_analysys_dataset, oracon.at_drug_appl_stdy_dataset
  where ar_id = ad_ar_id    and
        ad_dads_id = dads_id  and
		ad_selected_flag = 'true'
 ;
quit;
** FIGURE OUT HOW MANY ACTUAL DATASETS THERE ARE AND PULL THEM TO GET THEM READY FOR SUBSETTING AND GROUPING IF THERE IS ANY **;

proc sql noprint;
  select count(*) into: num_actual
  from actual_data;
quit;

%macro datasets;
%do NA = 1 %to &num_actual;

data _NULL_;
  set actual_data;
if _N_ = &NA;
call symput('dsk',compress(DADS_FILE_PATH_LOC));
if dads_custom_flag = 'false' then call symput('data',DADS_DST_CD);
  else call symput('data', compress(dads_name));
call symput('domain', compress(DADS_DST_CD));

run;

libname dsk "&dsk.";

data &domain.;
  set dsk.&data.;
run;

%end;
%mend datasets;
%datasets;

** Section 3 Grouping ***;
** NOW BRING IN THE GROUPING CODE ***;

proc sql;
  create table active_groups
  as select DADS_FILE_PATH_LOC, dads_dst_cd, dads_name, grp_set_id, grp_set_name, DADS_PARTIAN_EXISTS, 
            DST_PARTIAN_VARIABLE_NAME, dads_custom_flag
  from oracon.AT_active_set a, oracon.at_ds_set d, oracon.AT_DRUG_APPL_STDY_DATASET s, 
       oracon.at_dataset_type t, oracon.at_ds_variable_group g, oracon.at_dataset_variable v 
  where  s.DADS_DST_CD = t.dst_cd         and
         v.dsv_dads_id = s.dads_id        and
         g.dvg_grp_dsv_id = v.dsv_id         and
         d.grp_set_id = g.dsvg_grp_set_id and 
         a.asg_grp_set_id = d.grp_set_id  and
		 d.GRP_SET_TYPE_CD = '1'          and
         a.ag_ar_id = &runid.  
;
quit;

proc sql noprint;
  select count(*) into: num_groups
  from active_groups;
quit;


%macro grouping;

** THESE ARE THE ACTIVE GROUPSETS AND THE ASSOCIATED DATASETS ***;

proc sort data = active_groups nodupkey;
  by grp_set_id;
run;


**DETERMINE HOW MANY ACTIVE GROUPS THERE ARE IN ORDER TO LOOP FOR EACH ONE ***;

proc sql noprint;
  select count(*) into: num_groups
  from active_groups;
quit;

** NOW LOOP FOR EACH GROUPING;

%do G = 1 %to &num_groups;


**NOW USE THE GROUPING INFo TO PULL OFF THE NEEDED INFO **;

data _NULL_;
  set active_groups;
if _N_ = &G.;
call symput('dsk',compress(DADS_FILE_PATH_LOC));
if dads_custom_flag = 'false' then call symput('data',dads_dst_cd);
  else call symput('data', dads_name);
call symput('groupid', grp_set_id);
call symput('partition',DADS_PARTIAN_EXISTS);

call symput('part_variable',compress(DST_PARTIAN_VARIABLE_NAME));
call symput('domain', DADS_DST_CD);
call symput('grp_set_name',trim(grp_set_name));
run;

libname dsk2 "&dsk";

** NOW I NEED DIFFERENT LOGIC FOR PARTITION OR NOT PARTITION ***;
%macro part;
%if &partition = false %then %do;
** THESE ARE THE GROUPINGS ***;
proc sql;
  create table groupings
  as select dv.dsv_name, dvv.var_value, vg.dsvg_grp_name
  from oracon.at_ds_variable_group vg, oracon.at_group_variable_values gvv, oracon.at_ds_variable_values dvv,
       oracon.at_dataset_variable dv
  where dvv.var_dsv_id = dv.dsv_id                and
        gvv.grpv_var_value_id = dvv.var_value_id  and
        vg.dsvg_id = gvv.grpv_value_dsvg_id       and
		dsvg_grp_set_id = &groupid.
;
quit;


** MAKE A MACRO OUT OF THE VARIABLE ***;
proc sql noprint;;
  select dsv_name into: group_var
  from groupings;
quit;


** NOW MERGE ON TO THE DATASET **;

proc sql;
  create table gor_grouping
  as select * 
  from dsk2.&data as d left join groupings as g
  on d.&group_var = g.var_value
  ;
quit;
** OUTPUT THIS FILE FOR ANALYSIS PANELS **;

data sl_group&G.;
  format partition $50. group_name $50.;
  set gor_grouping;
if dsvg_grp_name ne '';
group_name = "&grp_set_name.";
partition = '';
var_name = "&group_var.";
keep group_name domain partition var_name var_value dsvg_grp_name;
run;
 

**NOW IF A VARIABLE HAS A GROUPING SET IT EQUAL TO THE NAME, ELSE LEAVE AS DEFAULT ***;

data final_grouping&G.;
  format temp_var $100.;
  set gor_grouping;

if dsvg_grp_name ne '' then temp_var = dsvg_grp_name;
  else temp_var = &group_var.;
keep usubjid domain temp_var;
run;

data final_grouping&G.;
  format &group_var.;
  set final_grouping&G.;
&group_var = temp_var;
drop temp_var;
run;



proc sort data = final_grouping&G.;
  by usubjid;
run;

proc sort data = &domain.;
  by usubjid;
run;

data &domain.;
  merge &domain.(drop=&group_var.) final_grouping&G.;
  by usubjid;
run;
 

%end;
%else %do;
** THESE ARE THE GROUPINGS  FOR PARTITION***;
proc sql;
  create table groupings
  as select dv.dsv_name, dvv.var_value, vg.dsvg_grp_name, p.ds_part_name
  from oracon.at_ds_variable_group vg, oracon.at_group_variable_values gvv, oracon.at_ds_variable_values dvv,
       oracon.at_dataset_variable dv, oracon.at_dataset_partician p
  where dv.dsv_ds_part_id = p.ds_part_id          and
        dvv.var_dsv_id = dv.dsv_id                and
        gvv.grpv_var_value_id = dvv.var_value_id  and
        vg.dsvg_id = gvv.grpv_value_dsvg_id       and
		dsvg_grp_set_id = &groupid.
;
quit;


** MAKE A MACRO OUT OF THE VARIABLES ***;
proc sql noprint;;
  select dsv_name into: group_var
  from groupings;
quit;

proc sql noprint;;
  select DS_PART_NAME into: part_name
  from groupings;
quit;

** NOW MERGE ON TO THE DATASET **;

proc sql;
  create table gor_grouping
  as select * 
  from dsk2.&data as d left join groupings as g
  on d.&group_var = g.var_value and
     d.&part_variable     = g.ds_part_name
  ;
quit;

** OUTPUT THIS FILE FOR ANALYSIS PANELS **;
data sl_group&G.;
  format partition $50. group_name $50.;
  set gor_grouping;
if dsvg_grp_name ne '';
group_name = "&grp_set_name.";
partition = "&part_name.";
var_name = "&group_var.";
keep group_name domain partition var_name var_value dsvg_grp_name;
run;
 
**NOW IF A VARIABLE HAS A GROUPING SET IT EQUAL TO THE NAME, ELSE LEAVE AS DEFAULT ***;

data final_grouping&G.;
  format temp_var $100.;
  set gor_grouping;
where &part_variable = "&part_name.";
if dsvg_grp_name ne '' then temp_var = dsvg_grp_name;
  else temp_var = &group_var.;
keep domain usubjid &part_variable temp_var;
run;


data final_grouping&G.;
  format &group_var. $100.;
  set final_grouping&G.;
&group_var = temp_var;
drop temp_var;
run;


proc sort data = final_grouping&G.;
  by usubjid &part_variable;
run;

proc sort data = &domain.;
  by usubjid &part_variable;
run;

data &domain.;
  merge &domain.(drop=&group_var.) final_grouping&G.;
  by usubjid &part_variable;
run;
 

%end;
%mend part;
%part;
%end;

** PULL THE DATASETS TOGETHER **;
data final_sl_group;
  set sl_group:;
retain group_name domain partition var_name var_value dsvg_grp_name;
run;

** NOW GET THEM IN THE CORRECT ORDER and ONE OBS FOR EACH **;

proc sql;
  create table sl_group
  as select unique group_name, domain, partition, var_name, var_value, dsvg_grp_name
  from final_sl_group
  order by group_name, domain, partition, var_name, dsvg_grp_name, var_value;
quit;

%mend grouping;

**IF THERE ISNT GROUPING STILL NEED TO CREATE A DATASET WITH THE RIGHT VARS **;
%macro no_grouping;
data sl_group;
 group_name='None';
 domain='';
 partition='';
 var_name='';
 dsvg_grp_name='';
 var_value='';;
run;
%mend no_grouping;

%macro run_grouping;
%if %eval(&num_groups.) > 0 %then %grouping;
%else %no_grouping;

%mend run_grouping;
%run_grouping;

** Section 4 Subsetting ***;

proc sql;
  create table active_subsets
  as select DADS_FILE_PATH_LOC, dads_dst_cd, dads_name, grp_set_id, DADS_PARTIAN_EXISTS, DST_PARTIAN_VARIABLE_NAME, 
            dads_custom_flag, grp_set_operator, dsvg_id, grp_set_name
  from oracon.AT_active_set a, oracon.at_ds_set d, oracon.AT_DRUG_APPL_STDY_DATASET s, 
       oracon.at_dataset_type t, oracon.at_ds_variable_group g, oracon.at_dataset_variable v 
  where  s.DADS_DST_CD = t.dst_cd         and
         v.dsv_dads_id = s.dads_id        and
         g.dvg_Grp_dsv_id = v.dsv_id         and
         d.grp_set_id = g.dsvg_grp_set_id and 
         a.asg_grp_set_id = d.grp_set_id  and
		 d.GRP_SET_TYPE_CD = '2'          and
         a.ag_ar_id = &runid.  
;
quit;


proc sql noprint;
  select count(*) into: num_active
  from active_subsets
 ;
quit;

%macro subset;

** THESE ARE THE ACTIVE SUBSETS AND THE ASSOCIATED DATASETS ***;


** DETERMINE HOW MANY ACTIVE SUBSETS THERE ARE TO ACT AS AN OUTER LOOPS ***;

proc sql;
  create table distinct_active
  as select distinct grp_set_id, grp_set_operator
  from active_subsets;
quit;

proc sql noprint;
  select count(*) into: num_active
  from distinct_active
 ;
quit;


** THIS IS THE OUTERLOOP OF ACTIVE SUBSETS **;

%do OL = 1 %to &num_active.; 

data _null_;
set distinct_active;
if _N_ = &OL.;
call symput('grp_set_id',grp_set_id);
call symput('gs_operator',compress(grp_set_operator));
run;


**DETERMINE HOW MANY ACTIVE GROUPS THERE ARE IN ORDER TO LOOP FOR EACH ONE ***;

proc sql noprint;
  select count(*) into: num_subsets
  from active_subsets
  where grp_set_id = &grp_set_id.;
quit;

proc sql;
  create table active_subsets&OL.
  as select *
  from active_subsets
  where grp_set_id = &grp_set_id.;
quit;
** NOW LOOP FOR EACH GROUPING;

%do S = 1 %to &num_subsets;

**NOW USE THE GROUPING INFo TO PULL OFF THE NEEDED INFO **;

data _NULL_;
  set active_subsets&OL;
if _N_ = &S.;
call symput('dsk',compress(DADS_FILE_PATH_LOC));
if dads_custom_flag = 'false' then call symput('data',dads_dst_cd);
  else call symput('data', dads_name);
call symput('subsetid', dsvg_id);
call symput('partition',DADS_PARTIAN_EXISTS);
call symput('part_variable',compress(DST_PARTIAN_VARIABLE_NAME));
call symput('in_operator',GRP_SET_OPERATOR);
call symput('subset_name',trim(grp_set_name));
run;

libname dsk2 "&dsk";

** NOW I NEED DIFFERENT LOGIC FOR PARTITION OR NOT PARTITION ***;

%if &partition = false %then %do; 
** THESE ARE THE SUBSETS ***;
proc sql;
  create table subsets
  as select dv.dsv_name, dvv.var_value, vg.dsvg_grp_name, dsvg_grp_set_id
  from oracon.at_ds_variable_group vg, oracon.at_group_variable_values gvv, oracon.at_ds_variable_values dvv,
       oracon.at_dataset_variable dv
  where dvv.var_dsv_id = dv.dsv_id                and
        gvv.grpv_var_value_id = dvv.var_value_id  and
        vg.dsvg_id = gvv.grpv_value_dsvg_id       and
		dsvg_id = &subsetid.
;
quit;


** MAKE A MACRO OUT OF THE VARIABLE ***;
proc sql noprint;;
  select dsv_name into: subset_var
  from subsets;
quit;

** CHECK IF THE VAR IN THE DOMAIN IS CHAR OR NUMBERIC SO WE KNOW WHICH TYPE OF WORK NEEDS TO BE DONE TO JOIN **;
proc contents data = dsk2.&data. out = contents noprint;
run;

proc sql noprint;
  select type into: var_type
  from contents
  where name = "&subset_var";
quit;

** NUMERIC MERGE **;


** NOW CHARACTER MERGE ON TO THE DATASET **;
%if &var_type. = 2 %then %do;
proc sql;
  create table data_subset
  as select * 
  from dsk2.&data d,  subsets s
  where d.&subset_var = s.var_value
  ;
quit;
%end;
%else %do;
data subsets;
  set subsets;
var_value_n = 1*var_value;
run;
proc sql;
  create table data_subset
  as select * 
  from dsk2.&data d,  subsets s
  where d.&subset_var = s.var_value_n
  ;
quit;
%end;


data for_panels&OL.&S.;
  set data_subset;
ds_part_name = '';
subset_name = "&subset_name.";
keep domain dsv_name var_value subset_name ds_part_name;
run;

**NOW TAKE AWAY DUPLICATES AND KEEP JUST THE SUBJECT ID ***;

proc sort data = data_subset out= final_subset&OL.&S.(keep=usubjid DSVG_GRP_SET_ID) nodupkey;
  by usubjid;
run;


%end; 
%else %do;
** THESE ARE THE SUBSETS FOR PARTITION***;
proc sql;
  create table subsets
  as select dv.dsv_name, dvv.var_value, vg.dsvg_grp_name, p.ds_part_name, DSVG_GRP_SET_ID
  from oracon.at_ds_variable_group vg, oracon.at_group_variable_values gvv, oracon.at_ds_variable_values dvv,
       oracon.at_dataset_variable dv, oracon.at_dataset_partician p
  where dv.dsv_ds_part_id = p.ds_part_id          and
        dvv.var_dsv_id = dv.dsv_id                and
        gvv.grpv_var_value_id = dvv.var_value_id  and
        vg.dsvg_id = gvv.grpv_value_dsvg_id       and
		dsvg_id = &subsetid.
;
quit;


** MAKE A MACRO OUT OF THE VARIABLES ***;
proc sql noprint;;
  select dsv_name into: subset_var
  from subsets;
quit;

proc sql noprint;;
  select DS_PART_NAME into: part_name
  from subsets;
quit;

** NOW MERGE ON TO THE DATASET **;
proc contents data = dsk2.&data. out = contents noprint;
run;

proc sql noprint;
  select type into: var_type
  from contents
  where name = "&subset_var";
quit;

** NUMERIC MERGE **;


** NOW CHARACTER MERGE ON TO THE DATASET **;
%if &var_type. = 2 %then %do;

proc sql;
  create table data_subset
  as select * 
  from dsk2.&data d, subsets s
  where compress(d.&subset_var) = compress(s.var_value) and 
        d.&part_variable     = s.ds_part_name 
  ;
quit;

%end;
%else %do;
data subsets;
  set subsets;
var_value_n = 1*var_value;
run;

proc sql;
  create table data_subset
  as select * 
  from dsk2.&data d, subsets s
  where d.&subset_var = s.var_value_n and 
        d.&part_variable     = s.ds_part_name 
  ;
quit;
%end;




data for_panels&OL.&S.;
  set data_subset;

subset_name = "&subset_name.";
keep domain dsv_name var_value subset_name ds_part_name;
run;
**NOW TAKE AWAY DUPLICATES AND KEEP JUST THE SUBJECT ID ***;

proc sort data = data_subset out= final_subset&OL.&S.(keep=usubjid DSVG_GRP_SET_ID) nodupkey;
  by usubjid;
run;

%end; /* END PARTITION LOOP */ 
%end; /* END INNER LOOP */

** THE FOLLOWING DETERMINES IF IT IS AN OR OR AND WITHIN A SUBSET SET AND TO GET THE RIGHT FILE **;
%if &num_subsets > 1 %then %do;

 %if &in_operator = 1 %then %do; /* AND OPERAND */
    data final_subset&OL.;
	  merge
	  %do M = 1 %to &num_subsets.;
	    final_subset&OL.&M. (in=i&M.)
	  %end;
	  ;
      by usubjid;
	  if
	  %do I = 1 %to %eval(&num_subsets.)-1;
	    i&I. and
	  %end;
        i%eval(&num_subsets.);
	run;
   ** NOW MERGE THE OUTPUT STUFF ALSO **;
   data c_for_panels&OL.;
     set for_panels&OL.:;
     inner_operator = 'AND';
   run;
  %end;
  %else %if &in_operator = 2 %then %do; /* OR OPERAND */
    data final_subset&OL.;
	  merge
	  %do M = 1 %to &num_subsets.;
	    final_subset&OL.&M.
	  %end;
	  ;
      by usubjid;
	run;
	data c_for_panels&OL.;
     set for_panels&OL.:;
     inner_operator = 'OR';
   run;
  %end;
%end;
%else %do;
 data final_subset&OL.;
  set final_subset&OL.1;
 run;
 data c_for_panels&OL.;
     set for_panels&OL.:;
     inner_operator = '   ';
 run;
%end;

%end; /* END OF OUTER LOOP */ 
** FOLLOWING IS THE COMBINATION OF EACH OF THE SUBSET SETS INTO ONE SUBSET **;
%if &num_active. > 1 %then %do;

 %if &operator = 1 %then %do; /* AND OPERAND */
    data final_subset(keep = usubjid);
	  merge
	  %do A = 1 %to &num_active.;
	    final_subset&A. (in=i&A.)
	  %end;
	  ;
      by usubjid;
	  if
	  %do I = 1 %to %eval(&num_active.)-1;
	    i&I. and
	  %end;
        i%eval(&num_active.);
	run;
	data o_for_panels;
     set c_for_panels:;
     outer_operator = 'AND';
    run;
  %end;
  %else %if &operator = 2 %then %do; /* OR OPERAND */
    data final_subset(keep = usubjid);
	  merge
	  %do A = 1 %to &num_active.;
	    final_subset&A.
	  %end;
	  ;
      by usubjid;
	run;
	data o_for_panels;
     set c_for_panels:;
     outer_operator = 'OR';
    run;
  %end;
%end;
%else %do;
 data final_subset(keep = usubjid);
  set final_subset1;
 run;
 data o_for_panels;
     set c_for_panels:;
     outer_operator = '  ';
    run;
%end;

proc sort data = dm;
  by usubjid;
run;

proc sort data = final_subset;
  by usubjid;
run;

data dm;
  merge dm(in=d) final_subset(in=s);
  by usubjid;
  if d and s;
run;

proc sql;
  create table sl_subset
  as select unique subset_name as name, domain, ds_part_name as partition, dsv_name as var_name, var_value, 
                   inner_operator, outer_operator
  from o_for_panels
  order by subset_name, domain, ds_part_name, var_name, var_value;
quit;

%mend subset;

%macro no_subset;
data sl_subset;
 name='None';
 domain='';
 partition='';
 var_name='';
 var_value='';
 inner_operator='';
 outer_operator='';
run;
data active_subsets;
run;

%mend no_subset;

%macro run_subset;
%if %eval(&num_active) > 0 %then %subset;
%else %no_subset;

%mend run_subset;
%run_subset;



** FOR FUTURE VERSIONS WITH NON SAS PROGRAMS, A DATA TRANSFORM MODULE WILL HAVE TO BE PUT HERE **;

** NOW I NEED TO FIGURE OUT WHICH PANEL IS BEING USED AND CALL IT **;
** Section 5 Panel Options ***;
proc sql;
  create table panel
  as select *
  from oracon.at_panel 
  where pnl_id = &panel_id.
  ;
quit;

data _null_;
  set panel;
  format panel $100.;
panel = compress(pnl_file_path_loc)||trim(pnl_file_name);
call symput('panel',trim(panel));
call symput('saspath',compress(pnl_file_path_loc));
call symput('panel_title',trim(PNL_NAME));
call symput('panel_desc',trim(PNL_DESCRIP_PLAIN));
run;

** NOW FIGURE OUT THE OUTPUT DATA ***;

proc sql;
  create table outdata
  as select *
  from oracon.at_analysis_output
  where ano_ar_id = &runid.
  ;
quit;

** DETERMINE HOW MANY OUTFILES THERE ARE **;

proc sql noprint;
  select count(*) into: num_out
  from outdata;
quit;

** LOOP THROUGH EACH INSTANCE AND RESOLVE THE MACRO ***;
%macro outs;
%do O = 1 %to &num_out;

data _null_;
  set outdata;
  if &O = _N_;
call symput("m_name",compress(ano_file_name));
run;
%GLOBAL &m_name.;
data _null_;
  set outdata;
  if &O = _N_;
call symput("&m_name.",trim(ANO_RESULTS_PATH_LOC)||trim(ano_displ_name));
run;

%end;
%mend outs;
%outs;


** NOW PULL THE PANEL OPTIONS ***;

proc sql;
  create table panel_options
  as select *
  from oracon.at_analysis_pnl_ds_options
  where pdo_ar_id = &runid.
  ;
quit;

** DETERMINE NUMBER OF OPTIONS **;

proc sql noprint;
  select count(*) into: num_options
  from panel_options;
quit;

** LOOP THROUGH EACH ONE AND PASS OUT THE OPTION **;
** THERE IS A SPECIAL CHECK FOR NUMBER OF BUCKETS **;
%global num_buckets;
%macro panel_options;
%do PO = 1 %to &num_options.;

** DECIDE WHICH FIELD IS POPULATED AND PASS IT ***;
data panel_options2;
  set panel_options;
  if _N_ = &PO.;
macro_var = compress(compress(PDO_OPT_REQ_SAS_VAR)||trim(compress(PDO_OPT_OPTION_SEQ,".' '")));
call symput('o_name',compress(macro_var));
if PDO_OPT_REQ_SAS_VAR = 'AGE_GRP' then call symput('num_buckets',compress(PDO_OPT_OPTION_SEQ));
run;

%GLOBAL &o_name.;

proc sql noprint;
  select trim(pdo_opt_txt) into: &o_name.
  from panel_options2;
  ;
quit;

%end;
%mend;
%panel_options;

** NOW MAKE A DATASET WITH ALL OF DATASETS USED TO PASS TO DAVID ***;
** Section 6 Metadata ***;
data data_used;
  set actual_data active_subsets;
  if dads_dst_cd ne '';
  if upcase(dads_name) = 'DEFAULT' then default = 'Y'; 
    else default = 'N';
run;

proc sql;
  create table sl_datasets
  as select unique dads_dst_cd as datatype, ad.DST_PARTIAN_VARIABLE_NAME as partition_variable, dads_name as name, default
  from data_used d, oracon.at_dataset_type ad
       where d.dads_dst_cd = ad.dst_cd;
quit;

data sl_datasets;
  set sl_datasets;
if partition_variable = 'default' then partition_variable='';
run;

** THIS IS THE FINAL VERSION OF THE GROUPING DATASETS **;
** SETS IT TO EMPTY IF THERE ISN'T GROUPING ***;
data sl_group;
  set sl_group;
if upcase(group_name) = 'NONE' then delete;
run;

** FIANL OF SUBSETTING **;
** SETS TO EMPTY IF THERE ISNT ANY **;
data sl_subset;
  set sl_subset;
if upcase(name) = 'NONE' then delete;
run;

** Section 7 Run Panel ***;
** SOME PANELS NEED THE FOLLOWING **;
%let run_location = SL;
** NOW CALL THE PANEL **;
** ALL THE DATASETS AND MACROS WILL BE PASSED ***;

%global ERRSTATUS;
%let ERRSTATUS = 0;

%include "&panel.";

** Section 8 Error File ***;
** THIS OUTPUTS THE FINAL STATUS CODE OF THE PROGRAM**;
** SO JAVA KNOWS HOW WE DID **;
** MAKE 3 INTO 7 BECAUSE 3 IS GOOD IN THE ORACLE WORLD **;

data _null_;
run;
%put &SYSERR.;
%put &SYSCC;
** THE FOLLOWING WILL GET SAS OUT OF SYNTEX MODE IF IT HAS GOTTEN ITSELF THERE **;
Options NOSYNTAXCHECK NODMSSYNCHK obs=max; 
DATA _NULL_;
  
if &ERRSTATUS = 5 then a = 5;
  else a = &SYSCC;
 if a = 3 then a = 7;
  FILE  "&PTH.\complete_&runid..txt";
  PUT a;
RUN;

/** GENERIC ERROR OUTPUT **/
/** Create an Excel workbook in case there is an unanticipated error in the panel **/
%macro sl_errout;

	%if (&syscc. = 3 or &syscc. > 4) %then %do;

		%include "&utilpath.\xml_output.sas";
		%include "&utilpath.\err_output.sas";

		%error_summary(err_file=&errout.,
					   err_desc=%str(There was an error executing this panel.)
                       );

	%end;

%mend sl_errout;

%sl_errout;

proc datasets library = work kill;
quit;
