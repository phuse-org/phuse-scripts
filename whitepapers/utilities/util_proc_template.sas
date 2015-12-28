/***
  Access a PhUSE/CSS GTL template.

  -INPUT:
    TEMPLATE  Name of the 
              REQUIRED
              Syntax:  template-name
              Example: PhUSEboxplot

  -OUTPUT:
    <string> return IN-LINE to be used in an AXIS ORDER=(<string>) statement.

  -EXAMPLE:
    %util_proc_template(phuseboxplot)

  -KNOWN LIMITATIONS:
    Legend markers for boxplots are NOT FULLY SUPPORTED by GTL until SAS 9.4 maintenance release 3
      http://support.sas.com/documentation/cdl/en/grstatgraph/67882/HTML/default/p0nebkqa1obtgxn13ska62up7wwh.htm
        see general notes
      http://support.sas.com/documentation/cdl/en/grstatgraph/67882/HTML/default/p0vuh82v39fsasn1vqhzmhdl8y16.htm#n0tx2vgt2rdidvn0ztwjopaeehwo
        see notes for "display="
    So the legend prior to SAS 9.4 M3 CAN NOT DISPLAY group symbols

  Author:          Dante Di Tommaso
***/

%macro util_proc_template(template);

  *--- Normal Range outlier symbol (size 5) should fit in the IQR outlier (size 7)  ---*;
  *--- Box width, Box plot cluster width and Scatter cluster width should all match ---*;
  %local iqr_size nr_size clusterwidth;

  %let iqr_size = 7;
  %let nr_size = 5;
  %let clusterwidth = 0.8;

  %if %upcase(&template) = PHUSEBOXPLOT %then %do;
    proc template;
      define statgraph PhUSEboxplot;

        dynamic _TRT _AVISIT _AVISITN _AVAL _AVALOUTLIE 
                _REFMIN _REFMAX _YMIN _YMAX 
                _N _MEAN _STD _DATAMIN _Q1 _MEDIAN _Q3 _DATAMAX
                _TICKLIST_;

        *--- Design dimensions are suitable for landscape A4 and Letter ---*;
        begingraph / border=false 
                     dataskin=none 
                     designwidth=260mm designheight=190mm 
                     attrpriority=none;

          *--- Define extra legend items for Outlier markers. Define these OUTSIDE the layout block ---*;
          legenditem type=marker name='IQROutliers' / 
                                 label='IQR Outliers' 
                                 markerattrs=(color=CX000000 
                                              symbol=square 
                                              size=&iqr_size);
          legenditem type=marker name='NormalRangeOutliers' / 
                                 label='Normal Range Outliers' 
                                 markerattrs=(color=CXFF0000 
                                              symbol=circlefilled 
                                              size=&nr_size);

          layout overlay /
                 walldisplay=none
                 pad=(top=20)
                 yaxisopts=(type=linear 
                            linearopts=(viewmin=_YMIN viewmax=_YMAX)
                            )
                 xaxisopts=(labelfitpolicy=split)
                 xaxisopts=(type=discrete
                            discreteopts=(tickvaluelist=_TICKLIST_ 
                                          tickvaluefitpolicy=splitrotate 
                                          tickvaluelistpolicy=union)
                           );

            *--- TOP INNER MARGIN: Timepoint labels appear across the top of the plot area ---*;
            innermargin / align=top 
                          separator=false 
                          pad=(top=0);
              blockplot x=_AVISITN block=_AVISIT /
                        outlineattrs=(color=CXB3B3B3)
                        display=(outline 
                                 values)
                        valuefitpolicy=split
                        valuehalign=left
                        valuevalign=top
                        ;
            endinnermargin;

            *--- MAIN BOX PLOT: Including IQR outliers.
                 Cluster width must match that of Scatter plot, and the Box plot width. 
                 By default, they do not match! ---*;
            boxplot x=_AVISITN y=_AVAL /
                    group=_TRT
                    name='box'
                    capshape=serif
                    boxwidth=&clusterwidth
                    display=(notches 
                             caps 
                             mean 
                             median 
                             fill 
                             outliers)
                    groupdisplay=cluster
                    clusterwidth=&clusterwidth
                    fillattrs=(color=CXB9CFE7)
                    outlineattrs=(color=darkblue 
                                  pattern=solid 
                                  thickness=0.5)
                    medianattrs=(color=darkblue)
                    whiskerattrs=(color=darkblue)
                    meanattrs=(symbol=plus 
                               size=8)
                    outlierattrs=(color=cx000000 
                                  symbol=square 
                                  size=&iqr_size)
                    ;

            *--- OUTLIER SCATTER PLOT: Normal Range Outliers. 
                 Cluster width must match that of Box plot. 
                 By default, they do not match! ---*;
            scatterplot x=_AVISITN y=_AVALOUTLIE /
                        name='scatter'
                        jitter=auto
                        group=_TRT
                        markerattrs=(color=CXFF0000 
                                     symbol=CIRCLEFILLED 
                                     size=&nr_size)
                        legendlabel='Normal Range Outliers'
                        groupdisplay=cluster
                        clusterwidth=&clusterwidth
                        ;

            referenceline y=_REFMAX / lineattrs=(color=red) name='Max';
            referenceline y=_REFMIN / lineattrs=(color=red) name='Min';

            *--- KNOWN LIMITATION: 'box' markers work in SAS 9.4 M3 and later. See header notes. ---*;
            discretelegend 'box' 'IQROutliers' 'NormalRangeOutliers' /
                           type=marker
                           location=outside
                           valign=bottom
                           border=false
                           title='Treatments & Outliers:'
                           ;

            innermargin / align=bottom separator=false pad=(bottom=0);
                  axistable x=_AVISITN value=_TRT     / class=_TRT label='Treatment' classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_N       / class=_TRT label='n'         classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_MEAN    / class=_TRT label='Mean'      classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_STD     / class=_TRT label='Std Dev'   classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_DATAMIN / class=_TRT label='Min'       classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_Q1      / class=_TRT label='Q1'        classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_MEDIAN  / class=_TRT label='Median'    classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_Q3      / class=_TRT label='Q3'        classdisplay=cluster colorgroup=_TRT;
                  axistable x=_AVISITN value=_DATAMAX / class=_TRT label='Max'       classdisplay=cluster colorgroup=_TRT;
            endinnermargin;

          endlayout;
        endgraph;
      end;
    run;
  %end;

%mend util_proc_template;
