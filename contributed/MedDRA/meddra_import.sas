/* path the the MedDRA hierarchy text files formatted as ASC */
%let path = ;

/* MedDRA version */
%let ver = ;

/* location where the SAS datasets will be copied */
%let outpath = ;
libname out "&outpath.";

%let dsver = %sysfunc(translate(&ver.,'_','.'));

options mprint mlogic;

/*****************************************************/
/* import the MedDRA hierarchy and lower-level terms */
/*****************************************************/
%macro import;

	%put ;
	%put READING IN TEXT FILES AND CREATING SAS DATASETS;
	%put ; 

	/* import the SOC/HLGT/HLT/PT hierarchy */
	data mdhier_&dsver.;
		infile "&path.\mdhier.asc" dsd dlm='$' missover lrecl=32767;
		length pt_name 
	           hlt_name 
	           hlgt_name 
	           soc_name $100 
	           soc_abbrev $5 
	           null_field $1
	           primary_soc_fg $1;
	  	input pt_code 
	          hlt_code 
	          hlgt_code 
	          soc_code 
	          pt_name 
	          hlt_name 
	          hlgt_name 
	          soc_name
	          soc_abbrev 
	          null_field 
	          pt_soc_code 
	          primary_soc_fg;

		length ver $4;
		ver = left("&ver.");
		aebodsys = upcase(soc_name);
		aedecod = upcase(pt_name);
	run; 

	proc sort data=mdhier_&dsver.; by aebodsys aedecod; run;

	/* import the PT level to get the LLT-to-PT code mapping */
	data pt_&dsver.;
		infile "&path.\pt.asc" dsd dlm='$' missover lrecl=32767;
		length pt_name        $100 
               null_field     $1 
               pt_whoart_code $7 
               pt_costart_sym $21
               pt_icd9_code   $8 
               pt_icd9cm_code $8 
               pt_icd10_code  $8 
               pt_jart_code   $6;
               ;
		input pt_code 
              pt_name 
              null_field 
              pt_soc_code 
              pt_whoart_code 
              pt_harts_code
              pt_costart_sym 
              pt_icd9_code 
              pt_icd9cm_code 
              pt_icd10_code 
              pt_jart_code
              ;
		length ver $4;
		ver = left("&ver."); 
	run;

	/* import the LLT level */
	data llt_&dsver.;
		infile "&path.\llt.asc" dsd dlm='$' missover lrecl=32767;
		length llt_name        $100 
               llt_whoart_code $7 
               llt_costart_sym $21 
               llt_icd9_code   $8
               llt_icd9cm_code $8 
               llt_icd10_code  $8 
               llt_currency    $1 
               llt_jart_code   $6
               ;
		input  llt_code 
               llt_name 
               pt_code 
               llt_whoart_code 
               llt_harts_code 
               llt_costart_sym
               llt_icd9_code 
               llt_icd9cm_code 
               llt_icd10_code 
               llt_currency 
               llt_jart_code
               ;
		length ver $4;
		ver = left("&ver."); 
	run; 


	/* combine lower level terms with preferred terms */
	proc sql noprint;
		create table pt_llt_&dsver. as
		select a.ver, a.pt_name, b.llt_name, a.pt_code, b.llt_code
		from pt_&dsver. a,
		     llt_&dsver. b
		where a.pt_code = b.pt_code
		order by llt_name;
	quit;

	/* create MedDRA hierarchy with SOC - LLT */
	proc sql noprint;
		create table mdhier_llt_&dsver. as
		select b.llt_name,
               a.pt_name,
		       a.hlt_name,
			   a.hlgt_name,
			   a.soc_name,
			   a.soc_abbrev,
			   a.null_field,
			   a.primary_soc_fg,
			   b.llt_code,
			   a.pt_code,
			   a.hlt_code,
			   a.hlgt_code,
			   a.soc_code,
			   a.pt_soc_code,
			   a.ver,
			   a.aebodsys,
			   a.aedecod
		from mdhier_&dsver. a,
		     pt_llt_&dsver. b
		where a.pt_code = b.pt_code
		order by soc_name, hlgt_name, hlt_name, pt_name, llt_name;
	quit;

	/* copy the resulting SAS datasets to the output location */
	data out.mdhier_&dsver.;
		set mdhier_&dsver.;
	run;

	data out.mdhier_llt_&dsver.;
		set mdhier_llt_&dsver.;
	run;

	/* clean up datasets */
	proc datasets library=work nolist nodetails; delete pt_&dsver. llt_&dsver.; quit;

%mend import;


/*************************************************************************/
/* import DMEs, save them to a permanent SAS library, and write a report */
/*************************************************************************/
%macro meddra;

	%put ;
	%put IMPORTING MEDDRA VERSION &ver.;
	%put ; 

	/* determine if the files exist */
	data _null_; 
		mdhier_exist = fileexist("&path.\mdhier.asc");
		pt_exist = fileexist("&path.\pt.asc");
		llt_exist = fileexist("&path.\llt.asc");
		if mdhier_exist and pt_exist and llt_exist then file_exist = 1;
		else file_exist = 0;
		call symputx('file_exist',file_exist,'g');
	run;

	%if not &file_exist. %then %do;
		%let err_msg = THE REQUIRED MEDDRA FILES DO NOT EXIST IN THE SPECIFIED DIRECTORY;
		%goto exit;
	%end;

	/* determine if the output location is valid */
	data _null_;
		out_exist = ifn(libref('out')=0,1,0);
		call symputx('out_exist',out_exist,'g');
	run;

	%if not &out_exist. %then %do;
		%let err_msg = %upcase(&outpath.) DOES NOT EXIST;
		%goto exit;
	%end;

	%import; 

	%exit: %if %symexist(err_msg) %then %put ERROR: &err_msg.;

%mend meddra;

%meddra;
