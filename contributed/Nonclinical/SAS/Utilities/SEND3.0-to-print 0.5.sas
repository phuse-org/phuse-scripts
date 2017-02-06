/*******************************************************************************/
/*  SEND3.0-to-print.sas                                                       */
/*                                                                             */
/*  A tool to print SAS SEND files to PDF  (not including SUPP dataset)        */
/*                                                                             */
/*                                                                             */
/*******************************************************************************/
/* Jan 15, 2013   W. Houser   Created initial version v0.4                     */
/* Oct 14, 2013   W. Houser	  added MISUPP and MASUPP, named v0.5              */
/*                                                                             */
/*******************************************************************************/

%MACRO XML(domain);
	libname myxpt xport "C:\PhUSE Script Repository\phuse-scripts\trunk\data\send\instem\Xpt\&domain..xpt";
	data &domain;
		set myxpt.&domain;
	run;
	ods proclabel="&domain";/*this is the bookmark name in the pdf output*/
	proc print data=&domain contents="";
         title "Data Set &domain";
		  /* Contents variable is the bookmark name for level 2 in the pdf output*/
    run;
%MEND;


ods pdf file="c:\SAS-play\output.pdf"; 
ods listing close; /* to prevent warnings of column too long for log file */

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
%XML(suppma)
%XML(mi)
%XML(suppmi)
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
%XML(relrec)

ods pdf close;
