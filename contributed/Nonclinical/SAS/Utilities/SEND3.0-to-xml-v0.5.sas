/*******************************************************************************/
/*  SEND3.0-to-xml-v0.5.sas                                                    */
/*                                                                             */
/*  A tool to read SAS XPT files and create an  *.xml file.   This does not    */
/*  produce *.xml that complyes with the ODM standard or any other standard.   */
/*                                                                             */
/*                                                                             */
/*******************************************************************************/
/* July 15,2011  W. Houser   Started creating version on SAS 9.                */
/* July 20,2011  W. Houser   This version creates one xml for each dataset     */
/* Aug  18,2011  W. Houser   Changed output to be lowercase filenames          */
/* Mar  14,2012  W. Houser   Added steps to read the xpt files                 */ 
/* May   2,2012  W. Houser   Corrected error preventing load of supp datastes  */
/*                                                                             */
/*******************************************************************************/

%MACRO XML(domain);
	%if %sysfunc(fileexist("c:\SAS-play\&domain..xpt")) %then %do;
		libname myxml   xml   "c:\SAS-play\&domain..xml";
		libname myxpt   xport "c:\SAS-play\&domain..xpt";
		DATA myxml.&domain;
			set myxpt.&domain;
		run;
	%end;
	%if %sysfunc(fileexist("c:\SAS-play\supp&domain..xpt")) %then %do;
		libname suppxml xml   "c:\SAS-play\supp&domain..xml";
		libname suppxpt xport "c:\SAS-play\supp&domain..xpt";
		DATA suppxml.supp&domain;
			set suppxpt.supp&domain;
		run;
	%end;
%MEND;

%XML(dm)
%XML(co)
%XML(se)
%XML(ex)
%XML(ds)
%XML(bw)
%XML(bg)
%XML(cl)
%XML(dd)
%XML(fw)
%XML(lb)
%XML(ma)
%XML(mi)
%XML(om)
%XML(pm)
%XML(pc)
%XML(pp)
%XML(sc)
%XML(tf)
%XML(vs)
%XML(eg)
%XML(te)
%XML(ta)
%XML(tx)
%XML(ts)
%XML(pooldef)
%XML(relreq)
