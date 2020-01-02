/***
Annotations 
(assuming table of diastolic blood pressure after lying down for 5 minutes over time for subjects in safety population)
Dataset: ADVS
Variables: USUBJID, TRTPN, PARAM, PARAMCD, AVAL, CRIT1, CRIT1FL, , CRIT2, CRIT2FL
Record Selection: WHERE PARAMCD=�DIABP� and ATPTN=815 and ADY > 1 and SAFFL=�Y� and (not missing(CRIT1FL) or not missing(CRIT2FL))
Abnormality Direction: Low
N = number of subjects with at least 1 record with non-missing CRIT2FL.
n = number of subjects with CRIT2FL='Y'.
Abnormality Direction: High
N = number of subjects with at least 1 record with non-missing CRIT1FL.
n = number of subjects with CRIT1FL='Y'.
Percentage = 100 * n / N.
**/

%* modification 2019-12-23 - update path as data has been moved;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/advs.xpt";
libname source xport;
data advs;
	set inlib.advs;
	WHERE PARAMCD="DIABP" and ATPTN=815 and ADY > 1 and SAFFL="Y" and (not missing(CRIT1FL) or not missing(CRIT2FL));
	keep USUBJID TRTPN PARAM PARAMCD AVAL CRIT1 CRIT1FL CRIT2 CRIT2FL;
run;

proc sql;
	* Count total subjects for TE low N;
	create table totn_low as
		select distinct trtpn, 
				param,
				count(unique(usubjid)) as totn, 
				"Low" as tefl length=4
		from advs
		where not missing(crit1fl)
		group by trtpn, param;

	* Count number of TE low subjects;
	create table n_low as
		select distinct trtpn, 
				param,
				count(unique(usubjid)) as n, 
				"Low" as tefl length=4
		from advs
		where crit1fl="Y"
		group by trtpn, param;

	* Count total subjects for TE high N;
	create table totn_high as
		select distinct trtpn, 
				param,
				count(unique(usubjid)) as totn, 
				"High" as tefl length=4
		from advs
		where not missing(crit2fl)
		group by trtpn, param;

	* Count number of TE low subjects;
	create table n_high as
		select distinct trtpn, 
				param,
				count(unique(usubjid)) as n, 
				"High" as tefl length=4
		from advs
		where crit2fl="Y"
		group by trtpn, param;
quit;

data totn;
	set totn_high totn_low;
run;

data te_n;
	set n_high n_low;
run;

proc sort data=totn;
	by trtpn param;
run;

proc sort data=te_n;
	by trtpn param;
run;

* Combine N and n datasets, calculate percent of TE high and low subjects;
data all_n;
	merge totn te_n;
	by trtpn param;
	pct=n/totn*100;
run;


* Compute Fisher Exact p-value;
%macro fisherpval(flg=, tefl=);
proc sort data=advs;
	by usubjid &flg;
run;

data &flg;
	set advs;
	by usubjid &flg;
	if last.usubjid;
run;

ods output FishersExact=fisher_&flg;
proc freq data = &flg;
	tables param*trtpn*&flg/fisher;
run;

data fisher_&flg;
	set fisher_&flg;
	length tefl $4.;
	tefl="&tefl";
	where name1="XP2_FISH";
	keep tefl nvalue1;
run;
%mend;

%fisherpval(flg=crit1fl, tefl=Low);
%fisherpval(flg=crit2fl, tefl=High);

data all_fisher;
	set fisher_crit1fl fisher_crit2fl;
run;

proc sort data=all_fisher;
	by tefl;
run;

proc sort data=all_n;
	by tefl trtpn;
run;

* Merge Fisher Exact p-value with N and n values;
* Create the variable "n (%)" for the reporting table;
data table_vals;
	merge all_n all_fisher;
	by tefl;
	pctc="("||strip(put(pct, 5.1))||")";
	nc=strip(put(n, best.));
run;

proc sort data=table_vals;
	by param descending tefl nvalue1;
run;

* Only want to display first p-value in final table;
data table_vals;
	set table_vals;
	by param descending tefl nvalue1;
	if first.nvalue1 then nvalue1c=put(nvalue1, pvalue5.3);
		else nvalue1c="";
run;

options pageno=1 nonumber nocenter mprint ps=44 ls=132 nodate orientation=landscape
		bottommargin = 1.0in
        Topmargin=1.0in
        leftmargin=1.0in
        rightmargin=1.0in;
title1 font="Courier New" height=8pt "Vital Signs";
title2 font="Courier New" height=8pt "Treatment-Emergent Abnormal High or Low at Any Time";
proc report data=table_vals nowd split="|" headline headskip missing formchar(2)="_" nocenter
		style(report)=[fontsize=8pt background=white]
		style(column)=[font=("Courier New", 8pt) background=white]
		style(header)=[font=("Courier New", 8pt) background=white];
	columns param tefl trtpn totn nc pctc nvalue1c;
	define param/"Vital Sign|(unit)" group order=data
				style(column)=[cellwidth=2.75in just=left] style(header)=[just=left];
	define tefl/"Abnormality|Direction" group order=data
				style(column)=[cellwidth=1.25in just=left] style(header)=[just=left];
	define trtpn/"Treatment" order=data group
				style(column)=[cellwidth=1.75in just=left] style(header)=[just=left];
	define totn/"N" order=data group
				style(column)=[cellwidth=0.75in just=left] style(header)=[just=left];
	define nc/"n" order=data group
				style(column)=[cellwidth=.6in just=left] style(header)=[just=left];
	define pctc/"(%)" order=data group
				style(column)=[cellwidth=.6in just=left] style(header)=[just=left];
	define nvalue1c/"P value*" order=data group
				style(column)=[cellwidth=1in just=left] style(header)=[just=left];

	compute after _page_;
		line @2 "Abbreviations:  N = number of patients with a normal (i.e., not low if calculating `low` and not high if calculating `high`)";
		line @2 "baseline and at least one post-baseline measure, n = number of patients wtih an abnormal post-baseline result in the";
		line @2 "specified category.";
		line @2 "*P values are from Fisher's Exact test.";
	endcomp;
run;




