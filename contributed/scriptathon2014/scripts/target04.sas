/*soh********************************************************************************************
   CODE NAME         : target4.sas
   DESCRIPTION       : Reference SAS program for target 4
   SOFTWARE/VERSION# : SAS V9
   INPUT             : http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/advs.xpt
--------------------------------------------------------------------------------------------------
   Author:    P. Chen 
   Notes from Author: 
     1. This is just a test version reference code, may need to be validated before using.
     2. In many cases, one may wish to use LSEMAN instead of the MEAN, other produces 
        (For example: PROC MIXED) could be used to calculate lsmeans in data step. The code for plot part 
        should only require very minor changes.
     3. A BANDPLOT statement can be added to the reference code to draw the shaded "Normal Range" area
        in the background based on your data and your requirement.
**eoh**********************************************************************************************/
options  NOCENTER MPRINT ;

filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/advs.xpt" ;
libname source xport ;

/*read in ADVS data with selected variables and obs*/
data advs ;
set source.advs ;
where PARAMCD="DIABP" and ATPTN=815 and ANL01FL='Y' and .<avisitn<99 AND SAFFL='Y';
KEEP usubjid trtpn ANL01FL PARAM PARAMCD avisit avisitn ATPTN SAFFL aval;
run;


/*take a look at the ADVS data with selected variables and obs*/
proc contents data=advs;
run;

proc freq data=advs;
tables trtpn Avisit*avisitn aval/list;
run;


/*produce summary statistics of aval by avisitn and trtpn*/
proc sort data=advs; 
by trtpn avisitn;
run;

PROC MEANS DATA=advs NOPRINT;
BY trtpn avisitn avisit;
VAR aval;
OUTPUT OUT=temp N=n MEAN=mean
STDERR=stderr LCLM=lclm UCLM=uclm ;
RUN ;


/*If you want to calculate Confidence Intervals and be 100% confident that your 95% confidence interval of
Mean is correct, it is best that you get your N, Mean and Standard error by any one of the procedures in SAS and
then use the TINV function to calculate the Confidence Interval.*/
DATA temp1 ;
SET temp ;
lo = mean - ( TINV ( 0.95 , n-1 ) * stderr ) ;
hi = mean + ( TINV ( 0.95 , n-1 ) * stderr ) ;
drop _TYPE_  _FREQ_  lclm     uclm stderr;
RUN;


/*format the data for plot -- there many other ways to do this*/
data a b c;
set temp1;
if trtpn=0 then output a;
else if trtpn=54 then output b;
else if trtpn=81 then output c;
run;

data a1;
set a;
rename n=a_n   mean=a_mean lo=a_lcl hi=a_ucl;
run;

data b1;
set b;
rename n=b_n   mean=b_mean lo=b_lcl hi=b_ucl;
run;

data c1;
set c;
rename n=c_n   mean=c_mean lo=c_lcl hi=c_ucl;
run;

data all;
merge a1 b1 c1;
by avisitn avisit;
rename avisitn=xc avisit=x;
drop trtpn;
label a_mean=0 b_mean=54 c_mean=81 ;                                                                                                        ;                                                                                                       
run;

                                                                                                                 
/* Create the template for the graph*/ 
/* Used a sample program on SAS web site as reference*/ 
proc template;                                                                                                                          
define statgraph dbp_profile;                                                                                                         
dynamic title;                                                                                                                      
begingraph / designwidth=17in designheight=14.5in;                                                                                  
entrytitle title;                                                                                                                 
layout lattice / columndatarange=union rowweights=(0.8 .05 .05 .05 .05);                                                         
layout overlay / cycleattrs=true yaxisopts=(label='Mean(unit)with 95% CI' griddisplay=on)                                       
xaxisopts=(label='Weeks Since Randomized' offsetmin=0.05 offsetmax=0.05                                          
linearopts=(tickvaluelist=(0 2 4 6 8 10 12 16 20 24 26)));    
scatterplot x=eval(xc-0.05) y=a_mean / yerrorlower=a_lcl yerrorupper=a_ucl name='as'                                          
                                                markerattrs=graphdata2(size=9px weight=bold)                                            
                                                errorbarattrs=graphdata2(pattern=solid thickness=2);                                    
scatterplot x=eval(xc+0.05) y=b_mean / yerrorlower=b_lcl yerrorupper=b_ucl name='bs'                                          
                                                markerattrs=graphdata3(size=9px weight=bold)                                            
                                                errorbarattrs=graphdata3(pattern=solid thickness=2);                                    
scatterplot x=eval(xc+0.15) y=c_mean / yerrorlower=c_lcl yerrorupper=c_ucl name='cs'                                          
                                                markerattrs=graphdata4(size=9px weight=bold)                                            
                                                errorbarattrs=graphdata4(pattern=solid thickness=2);                                                                                                                                                                          
seriesplot x=eval(xc-0.05) y=a_mean / lineattrs=graphdata2(pattern=shortdash thickness=2px) name='al';                        
seriesplot x=eval(xc+0.05) y=b_mean / lineattrs=graphdata3(pattern=mediumdash thickness=2px) name='bl';                       
seriesplot x=eval(xc+0.15) y=c_mean / lineattrs=graphdata4(pattern=dash thickness=2px) name='cl';                             
endlayout;                                                                                                                                                                                                                                                           
layout overlay;                                                                                                                 
entry halign=left 'At Risk Subjects';                                                                                                   
endlayout;                                                                                                                                                                                                                                                           
blockplot x=xc block=c_n / display=(values label) valuehalign=center label='81' repeatedvalues=true                           
                                     valueattrs=graphdata4 labelattrs=graphdata4;                                                       
blockplot x=xc block=b_n / display=(values label) valuehalign=center label='54' repeatedvalues=true                          
                                     valueattrs=graphdata3 labelattrs=graphdata3;                                                       
blockplot x=xc block=a_n / display=(values label) valuehalign=center label='0' repeatedvalues=true                          
                                     valueattrs=graphdata2 labelattrs=graphdata2;                                                                                                                                                                                         
idebar / spacefill=false;                                                                                                      
discretelegend  'al' 'bl' 'cl' / title='Treatment Group: ' across=3;                                                          
endsidebar;                                                                                                                     
endlayout;                                                                                                                        
endgraph;                                                                                                                           
end;                                                                                                                                  
run;                                                                                                                                    
                                                                                                                                        
/* Output graphs!! */                                                                                                                                                                                                                              
ods listing close;                                                                                                                      
ods html image_dpi=100 file='DBP_Profile.html' path='.';                                                                                
ods graphics / reset noborder width=600px height=400px                                                                                  
               imagename='ClinicalHandout_DbpProfile' imagefmt=gif noscale;                                                             
                                                                                                                                        
proc sgrender data=all template=dbp_profile;                                                                                           
dynamic title="Mean of DBP Measures by Treatment: Profile Over Time (Weeks Since Randomized)";                                       
run;                                                                                                                                    
                                                                                                                                        
ods html close;                                                                                                                         
ods listing;


   

