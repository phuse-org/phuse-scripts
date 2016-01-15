/*** normal distribution ******/
%macro normal (size=200, mu1=22, sd1=10, Delta=20, sd2=10, PCT=100);
	data final;
	     category='test';
		 do study_id=1 to 3;
		     do n=1 to &size ;
			  trt=1;
			  if study_id=3 then do;
				  a1=&mu1+sqrt(&SD1)*rannor(-1)+10;
				  bse=&mu1+sqrt(&SD1)*rannor(-1)+10;
				  output;
			  end;
			  else if study_id<3 then do;
                a1=&mu1+sqrt(&SD1)*rannor(-1);
				bse=&mu1+sqrt(&SD1)*rannor(-1);
			  output;
			  end; 
			  trt=2;
			  bse=&mu1+sqrt(&SD1)*rannor(-1);
			  if n>&size*(&PCT/100) then a1=&mu1+sqrt(&SD1)*rannor(-1);
	          else  
			  a1=&mu1+&delta+sqrt(&SD2)*rannor(-1);
			  output;
			end;
		 end;
	Run;
 proc sort data=final;
  by study_id;
    data final;
	 set final;
	 by study_id;
	 if first.study_id then do;
		 xorg=0;
		 yorg=0;
		 xend=50;
		 yend=50;
	 end;
	 if trt=1 then treatment='A';
	 if trt=2 then treatment='B';
	 id=compress('Study'||study_id||'_TRT_'||treatment);
	run;

 %mend normal;

/**** hard code in the inferential statistics for convenience. 
      Usually this should from actual analysis using 
      Proc Freq with CMH statistics requested
      ******/

data n;
 input trt $ BigN $ SMLn $ PCT $ OR $ Heter_P $ PVal $;
 label trt='Treatment';
 label BigN='N';
 label SMLn='n';
 label PCT='%';
 label OR='MH Odds Ratio';
 label Heter_p='Heterogenity P value';
 label PVAL='CMH P value';
 cards;
 A 600 30 5.0 - -  - 
 B 600 45 7.5 1.54 0.238 0.324
 ;
run;

/*simulated the raw data */
%normal (size=200, mu1=22, sd1=20, delta=20, sd2=30, PCT=5);

  /*template for the symbol, table, color and font format */ 
 proc template;
  Define style styles.Weistyle;
  Parent=styles.default;
  Style graphdata1 from graphdata1 / MarkerSymbol="circle" Color=green Contrastcolor=green;
  Style graphdata2 from graphdata2 / MarkerSymbol="circle" Color=orange Contrastcolor=orange;
  Style graphdata3 from graphdata3 / MarkerSymbol="square" Color=green Contrastcolor=green;
  Style graphdata4 from graphdata4 / MarkerSymbol="square" Color=orange Contrastcolor=orange;
  Style graphdata5 from graphdata5 / MarkerSymbol="plus" Color=green Contrastcolor=green;
  Style graphdata6 from graphdata6 / MarkerSymbol="plus" Color=orange Contrastcolor=orange;
  replace Table from Output / 
	 frame = hside /* outside borders: void, box, above/below, vsides/hsides, lhs/rhs */ 
	 rules = rows /* internal borders: none, all, cols, rows, groups */ 
	 cellpadding = 4pt /* the space between table cell contents and the cell border */ 
	 cellspacing = 0.25pt /* the space between table cells, allows background to show */ 
	 borderwidth = 0.75pt /* the width of the borders and rules */; 
  replace color_list / 
	 'link' = blue /* links */ 
	 'bgH' = gray /* row and column header background */ 
	 'bgT' = gray /* table background */ 
	 'bgD' = white /* data cell background */ 
	 'fg' = black /* text color */ 
	 'bg' = white; /* page background color */; 
 replace fonts / 
	 'TitleFont' = ("Arial",12pt,Bold) /* Titles from TITLE statements */ 
	 'TitleFont2' = ("Arial",12pt,Bold) /* Proc titles ("The XX Procedure")*/ 
	 'StrongFont' = ("Arial",10pt,Bold) 
	 'EmphasisFont' = ("Arial",10pt,Italic) 
	 'headingEmphasisFont' = ("Arial",10pt,Bold Italic) 
	 'headingFont' = ("Arial",10pt) /* Table column and row headings */ 
	 'docFont' = ("Arial",10pt) /* Data in table cells */ 
	 'footFont' = ("Arial",8pt, Italic) /* Footnotes from FOOTNOTE statements */ 
	 'FixedEmphasisFont' = ("Courier",9pt,Italic) 
	 'FixedStrongFont' = ("Courier",9pt,Bold) 
	 'FixedHeadingFont' = ("Courier",9pt,Bold) 
	 'BatchFixedFont' = ("Courier",6.7pt) 
	 'FixedFont' = ("Courier",8pt); 
  end;
run;

title;
footnote;

options nodate nonumber ;
Options orientation=landscape nonumber nodate;
ods pdf file="Maps.pdf" startpage=no style=styles.Weistyle notoc; 
ods escapechar='^';
ods layout start width=12in height=9.5in;
ods region width=9in height=1.5in x=0.5 in y=0in; 
ods pdf text="^{style [just=c fontsize=13pt fontweight=bold color=black] Shift/Outlier Analysis
– Maximum During Baseline to Maximum During Post-baseline  for Lab test 1}";
ods region width=9in height=1.5in x=0.5 in y=0.2in; 

ods pdf text="^{style [just=c fontsize=13pt fontweight=bold color=black] Population xxxx}";
 
ods region width=6in height=1.5in x=.5 in y=0.65in; 

ods pdf text="^{style [just=c fontsize=12pt color=black] ScatterPlot by Study}";
ods region width=5in height=1.5in x=6in y=1.4in; 
ods pdf text="^{style [just=c fontsize=12pt color=black] Treatment Emergent High}";
ods region width=4in height=4.5in x=6.8in y=4.4in; 
ods pdf text="^{style [just=l fontsize=9pt color=black] N=number of subjects with maximum baseline measurement }";
ods pdf text="^{style [just=l fontsize=9pt color=black] below upper limit of normal and at least one post-baseline  }";
ods pdf text="^{style [just=l fontsize=9pt color=black] measurement; n = number of subjects with a post-baseline  }";
ods pdf text="^{style [just=l fontsize=9pt color=black] measurement above upper limit of normal; CMH P-value = }";
ods pdf text="^{style [just=l fontsize=9pt color=black] Cochran-Mantel-Haenszel (CMH) test stratified by study.}";
ods pdf text="^{style [just=l fontsize=9pt color=black] The denominator for Mantel-Haenszel odds ratio is treatment A }";
ods pdf text="^{style [just=l fontsize=9pt color=black] Heterogeneity P value is from Breslow-Day test. }";
ods region width=8in height=1in x=0.5 in y=7in; 
ods pdf text="^{style [just=l fontsize=9pt color=black] XXX lab reference range is used. }";

ods region width=6in height=7.5in x=.5in y=0.8in; 
ods graphics/ BORDER= OFF;
proc sgpanel data=final;
	   panelby study_id;
	   scatter x=bse y=a1 / group=treatment;
	  refline 40 /axis=x label="ULN"  LABELPOS= min LINEATTRs=(color=red pattern=dot);
      refline 40 /axis=y label="ULN" LABELPOS= min LINEATTRs=(color=red pattern=dot);
      refline 10 /axis=x label="LLN"  LABELPOS= min LINEATTRs=(color=blue pattern=dot);
      refline 10 /axis=y label="LLN"  LABELPOS= min  LINEATTRs=(color=blue pattern=dot);
      vector x=xend y=yend/xorigin=xorg yorigin=yorg noarrowheads lineattrs=(thickness=1px  color=gray);
	  colaxis label='Maximum Baseline Measurement' values= (0 to 50 by 10) offsetmin=0 offsetmax=0.05 ;
      rowaxis  label='Maximum Post-baseline Measurement' values=(0 to 50 by 10) offsetmin=0 offsetmax=0.05 ;
    run;
quit; 


ods region width=5in height=4in x=6 in y=1.7in; 
proc print data=n label noobs style=[font_size=.2in] blankline=5;
 var trt bign smln pct;
run;


proc print data=n label noobs style=[font_size=.2in] blankline=5;
 where or^='-';
 title 'Treatment Comparison - B vs. A';
 var or heter_p Pval;
run; 
ods layout end; 
ods pdf close;

