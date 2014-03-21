*** Input section- specific to Script-athon;

filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/advs.xpt" ;
libname source xport ;
data work.advs ;
  set source.advs ;
  param = catx(' ', param, propcase(atpt)); 
  paramn = atptn;
run ;

%let inds = advs;
%let invar = USUBJID TRTPN TRTP PARAM PARAMCD PARAMN ATPT ATPTN AVAL AVISITN ANL01FL BNRIND ANRIND SHIFT1 CHGCAT1 SAFFL;
%let inwhere = %str(WHERE PARAMCD='DIABP' and ANL01FL='Y' and AVISITN=99 and SAFFL='Y' and
                    BNRIND ne 'Missing' and ANRIND ne 'Missing'); 
%let trtvar = trtpn;
%let maxcat = 4;

proc format;
  value shifttx
    1 = 'Low' 
	2 = 'Normal'
	3 = 'High'
	4 = 'Total'
	;

  invalue shiftord
    'Low'    = 1
	'Normal' = 2
	'High'   = 3
	'Total'  = 4
	;
run;

*** Read selected variables/records from input dataset;
data inds;
  set &inds (keep=&invar);
  &inwhere;
run;

*** Build treatment group display format;

*** Get name of treatment variable containing text;
%let trtvartx = %substr(&trtvar, 1, %eval(%length(&trtvar) - 1));

*** Create file of TRTx/TRTxN combinations;
proc sql noprint;
  create table trtcomb as
    select distinct &trtvar as start, &trtvartx as label, 'TRTFT' as fmtname, 'n' as type
	  from inds;
quit;

*** Generate format;
proc format library=work cntlin=trtcomb;
run;

*** Count patients by baseline/post-baseline shift category;
proc summary data=inds;
  class param paramn &trtvar bnrind anrind;
  var aval;
  output out=counts (where=(param is not missing and paramn is not missing and &trtvar is not missing)) n(aval) = n;
run;

proc sort data=counts;
  by param paramn trtpn;
run;

*** Fill in total indicator, add numeric shift categories, and split off denominator records;
data fixtot (keep=param paramn &trtvar anrind bnrind anrindn bnrindn n) 
     denom (keep=param paramn &trtvar n rename=(n=denom));
  set counts;

  if missing(bnrind) then bnrind = 'Total';
  if missing(anrind) then anrind = 'Total';
  
  bnrindn = input(bnrind, shiftord.);
  anrindn = input(anrind, shiftord.);

  if bnrind='Total' and anrind='Total' then output denom;
    else output fixtot;
run;

proc sort data=fixtot;
  by param paramn &trtvar bnrindn anrindn;
run;

*** Create full dataset to account for 0 cells;
proc sql noprint;
  create table allcat as
    select distinct param, paramn, &trtvar
	  from fixtot;
quit;

*** Add records for all combinations of baseline and post-baseline categories;
data full;
  set allcat;
  do bnrindn=1 to &maxcat;
    do anrindn=1 to &maxcat;
	  n = 0;
	  output;
	end;
  end;
run;

*** Merge back with counts to get complete dataset;
data allrecs;
  merge full (in=inf) fixtot (in=ins);
  by param paramn &trtvar bnrindn anrindn;
  if inf;
run;

*** Add denominators and repopulate shift categories;
data alldenom (where=(denom is not missing));
  merge allrecs (in=ina) denom (in=ind);
  by param paramn &trtvar;
  if ina;

  bnrind = put(bnrindn, shifttx.);
  anrind = put(anrindn, shifttx.);
run;

*** Get category names for column headings;
proc sql noprint;
  select distinct anrind into :pbcat1-:pbcat&maxcat
    from alldenom
	where anrind is not missing
    order by anrindn;
quit;

*** Transpose to 1 record per baseline category and compute percentage;
data trans (keep=param paramn &trtvar bnrindn bnrind n1-n&maxcat pct1-pct&maxcat denom trttx);
  array ns(*) n1-n&maxcat;
  array pcts(*) $7 pct1-pct&maxcat;
  
  do until (last.bnrindn);
    set alldenom;
	by param paramn &trtvar bnrindn;

	ns(anrindn) = n;
	if denom > 0 then pcts(anrindn) = '(' || put(round(((100 * n) / denom), 0.1), 5.1) || ')';
	  else pcts(anrindn) = '(  0.0)';
  end;

  length trttx $ 30;
  trttx = catx(' ', put(&trtvar, trtft.), ('(N = ' || compress(put(denom, 12.)) || ')'));
  output;
run;

*** Generate output table;
options orientation=landscape;
proc report nowd data=trans split='^';
  by paramn param;
  column &trtvar trttx bnrindn bnrind 
        ('Post-Baseline Result' ("&pbcat1" n1 pct1) ("&pbcat2" n2 pct2) ("&pbcat3" n3 pct3) ("&pbcat4" n4 pct4));

  define &trtvar / id order noprint;
  define trttx / "Treatment" id order flow;
  define bnrindn / id order noprint;
  define bnrind / "Baseline^Result" id order flow;

  define n1 / "n" right;
  define pct1 / "%" left;
  define n2 / "n" right;
  define pct2 / "%" left;
  define n3 / "n" right;
  define pct3 / "%" left;
  define n4 / "n" right;
  define pct4 / "%" left;

  break after trttx / skip;
run;
