filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/advs.xpt";
libname source xport;

data work.advs;
	set source.advs;
	where PARAMCD="DIABP" and ATPTN=815 and ANL01FL="Y" and . < AVISITN < 99 and SAFFL="Y";
	keep USUBJID TRTPN PARAM PARAMCD AVAL ANL01FL AVISIT AVISITN;
run;

proc sort data = advs;
	by usubjid trtpn;
run;

ods output CrossTabFreqs=freq;
ods trace off;
ods listing close;
proc freq data=advs;
	tables trtpn*avisitn;
run;
ods listing;

data freq;
	set freq;
	if _type_='11';
run;

proc sort data = freq;
	by trtpn;
run;

data trts;
	set freq;
	by trtpn;
	if first.trtpn;
run;

data trts;
	set trts;
	trtnum=_N_;
	keep trtpn trtnum;
run;

proc sort data = freq;
	by avisitn;
run;

data visits;
	set freq;
	by avisitn;
	if first.avisitn;
run;

data visits;
	set visits;
	visnum=_N_;
	keep avisitn visnum;
run;

proc sort data = visits;
	by avisitn;
run;

proc sort data = freq;
	by trtpn avisitn;
run;

proc sort data = trts;
	by trtpn;
run;

data freq;
	merge freq trts;
	by trtpn;
run;

proc sort data = freq;
	by avisitn;
run;

data freq;
	merge freq visits;
	by avisitn;
run;

proc sql noprint;
	select max(trtnum) into :ntrts
		from trts;
run;

data frq;
	set freq;
	ttpoint=0.5+visnum+(trtnum-1)/(&ntrts);
	keep avisitn trtpn ttpoint trtnum visnum;
run;

proc sort data=frq;
	by avisitn trtpn;
run;

proc sort data=advs;
	by avisitn trtpn;
run;

data two;
	merge advs frq;
	by avisitn trtpn;
run;

* Compute subgroup size, mean, and standard deviation;
proc sort data=two;
	by avisitn trtpn;
run;

proc means data=two noprint;
	by avisitn trtpn;
	var aval;
	output out=stats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
run;

* Create block variables used to produce table;
data blockraw;
	length  block1 block2 block3 block4 block5 block6 block7 block8 block9 $40.;
	keep block1 block2 block3 block4 block5 block6 block7 block8 block9 trtpn avisitn;

	* treatment;
	set stats;
	by avisitn trtpn;

	blck2 = n;
	blck3 = mean;
	blck4 = std;
	blck5 = min;
	blck6=q1;
	blck7=median;
	blck8=max;
	blck9=q3;
	block2 = strip(put(blck2,10.0));
	block3 = strip(put(blck3,10.2));
	block4 = strip(put(blck4,10.2));
	block5 = strip(put(blck5,10.2));
	block6 = strip(put(blck6,10.2));
	block7 = strip(put(blck7,10.2));
	block8 = strip(put(blck8,10.2));
	block9 = strip(put(blck9,10.2));
	block2 = left(block2);
	block3 = left(block3);
	block4 = left(block4);
	block5 = left(block5);
	block6 = left(block6);
	block7 = left(block7);
	block8 = left(block8);
	block9 = left(block9);
	block1= trtpn;
run;

data labelraw;
	trtpn=0;
	ttpoint=0;
	length  block1 block2 block3 block4 block5 block6 block7 block8 block9  $40.;
	block2 = left('N   ');
	block3 = left('Mean  ');
	block4 = left('Std    ');
	block5 = left('Min    ');
	block6 = left('Q1     ');
	block7 = left('Median   ');
	block8 = left('Q3     ');
	block9 = left('Max    ');
	block1 = left('Treatment ');
run;

data vwiseplot;
	merge two blockraw;
	by avisitn trtpn;
run;

data vwiseplot;
	set vwiseplot;
	by avisitn;

	if avisitn=0 then
		_Phase_='Baseline';
	else _phase_=compress('Week='||avisitn);
run;

proc sort data=vwiseplot;
	by ttpoint trtpn;
run;

data plot_visit;
	set labelraw vwiseplot;
run;

data plot_visit1;
	set plot_visit;
	where avisitn<=8;
run;

data plot_visit2;
	set plot_visit;
	where avisitn>8 or block1="Treatment";
	if block1="Treatment" then ttpoint=6;
run;

ods listing;
options orientation=landscape;
goptions reset=all hsize=15in vsize=8.5in;
ods pdf;
Title justify=center h=2 'Box Plot - Diastolic Blood Pressure Over Time (Weeks Since Randomized)';
Footnote1 JUSTIFY= LEFT h=.75 'Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), min and max';
Footnote2 justify=left h=.75 'within 1.5 IQR below 25% and above 75% (ends of the whisker).Values outside the 1.5 IQR below 25% and';
Footnote3 JUSTIFY= LEFT h=.75 'above 75% are shown as outliers. Means ploted as different symbols by treatments.';
symbol1 v=circle h=.75 c=green;
symbol2 v=star h=.75 c=red;
axis1 value=none label=none order=(0 to 6.5 by 1) offset=(0,0) major=none minor=none;
axis2 label=(j=c h=1  "Diastolic Blood Pressure (mmHg)") minor=(n=4);

proc shewhart graphics data=plot_visit1;
	boxchart aval*ttpoint (block9 block8 block7 block6 block5 block4 block3 block2 block1)=trtpn /
		blocklabtype=1.5
		blockpos=3
		blockrep
		stddevs
		boxwidthscale=0
		boxwidth=2
		boxstyle=schematic
		haxis=axis1
		vaxis=axis2
		CvREF=Red
		height=1.5
		hoffset       = 5
		nolimits
		readphase = all
		phaseref
		PHASELABTYPE=5
		phaselegend
		notches;
run;


ods listing;
options orientation=landscape;
goptions reset=all hsize=15in vsize=8.5in;
ods pdf;
Title justify=center h=2 'Box Plot - Diastolic Blood Pressure Over Time (Weeks Since Randomized)';
Footnote1 JUSTIFY= LEFT h=.75 'Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), min and max';
Footnote2 justify=left h=.75 'within 1.5 IQR below 25% and above 75% (ends of the whisker).Values outside the 1.5 IQR below 25% and';
Footnote3 JUSTIFY= LEFT h=.75 'above 75% are shown as outliers. Means ploted as different symbols by treatments.';
symbol1 v=circle h=.75 c=green;
symbol2 v=star h=.75 c=red;
axis1 value=none label=none order=(6 to 11.2 by 1) major=none minor=none;
axis2 label=(j=c h=1  "Diastolic Blood Pressure (mmHg)") minor=(n=4);

proc shewhart graphics data=plot_visit2;
	boxchart aval*ttpoint (block9 block8 block7 block6 block5 block4 block3 block2 block1)=trtpn /
		blocklabtype=1.5
		blockpos=3
		blockrep
		stddevs
		boxwidthscale=0
		boxwidth=2
		boxstyle=schematic
		haxis=axis1
		vaxis=axis2
		CvREF=Red
		height=1.5
		hoffset       = 5
		nolimits
		readphase = all
		phaseref
		PHASELABTYPE=5
		phaselegend
		notches;
run;


