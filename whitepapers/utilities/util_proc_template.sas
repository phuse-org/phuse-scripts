/***
  Access a PhUSE CS GTL template.

  -INPUT:
    TEMPLATE  Name of the 
              REQUIRED
              Syntax:  template-name
              Example: PhUSEboxplot
    DESIGNWIDTH &
    DESIGNHEIGHT: GTL templates do not support default values, or conditional BEGINGRAPH statements.
                  So use SAS Macro logic to control width & height of resulting GTL graphic. See discussion:
                  https://communities.sas.com/t5/SAS-GRAPH-and-ODS-Graphics/default-values-for-DYNAMIC-variables/m-p/246946

                  For details on these BEGINGRAPH options:
                  http://support.sas.com/documentation/cdl/en/grstatgraph/67882/HTML/default/n0j696v6yqkb79n12zed3am3omcx.htm

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

  -REFERENCES:
    * Predefined GTL Template for SAS procedures -- including TIPS for accessing SAS ODS templates
      http://support.sas.com/documentation/cdl/en/grstatug/67914/HTML/default/p0wcdwr2jjbnabn11tel1wmb43va.htm
    * 

  Author:          Dante Di Tommaso
***/

%macro util_proc_template(template, designwidth=260mm, designheight=170mm);

  *--- Set marker size relative to IQR outlier: MEAN symbol is +1, Normal Range outlier is -1 ---*;
  *--- Box width, Box plot cluster width and Scatter cluster width should all match ---*;
  %local iqr_size clusterwidth;

  %let iqr_size = 6;
  %let clusterwidth = 0.6;

  %if %upcase(&template) = PHUSEBOXPLOT %then %do;
    proc template;
      define statgraph PhUSEboxplot;

        dynamic _TITLE _DESIGN_WIDTH _DESIGN_HEIGHT
                _TRT _AVISIT _AVISITN _AVAL _AVALOUTLIE
                _YLABEL _YMIN _YMAX _YINCR 
                _REFLINES
                _N _MEAN _STD _DATAMIN _Q1 _MEDIAN _Q3 _DATAMAX _PVAL
                ;

        begingraph / attrpriority=none border=false pad=0 dataskin=none
                     designwidth=&designwidth designheight=&designheight
                     ;

          IF (EXISTS(_TITLE))
            entrytitle _TITLE;
          ENDIF;

          *--- Define extra legend items for Outlier markers. Define these OUTSIDE the layout block ---*;
          legenditem type=marker name='IQROutliers' / 
                                 label='IQR Outliers' 
                                 markerattrs=(color=CX000000 
                                              symbol=square 
                                              size=&iqr_size);

          IF (EXISTS(_AVALOUTLIE))
            legenditem type=marker name='NormalRangeOutliers' / 
                                   label='Normal Range Outliers'
                                   markerattrs=(color=CXFF0000 
                                                symbol=circlefilled 
                                                size=%eval(&iqr_size - 1)
                                               );
          ENDIF;

          layout overlay /
                 walldisplay=none
                 pad=(top=20)
                 yaxisopts=(type=linear
                            display=standard
                            label=_YLABEL
                            linearopts=(viewmin=_YMIN viewmax=_YMAX
                                        tickvaluesequence=(start=_YMIN 
                                                           end=_YMAX 
                                                           increment=_YINCR)
                                       )
                            )
                 xaxisopts=(type=discrete
                            display=(line)
                            discreteopts=(colorbands=even colorbandsattrs=GraphBlock (transparency=0.7))
                           );

            *--- TOP INNER MARGIN: Timepoint labels appear across the top of the plot area ---*;
            innermargin / align=top 
                          separator=false 
                          pad=0;
              blockplot x=_AVISITN block=_AVISIT /
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
                    name='box'
                    group=_TRT
                    groupdisplay=cluster
                    clusterwidth=&clusterwidth
                    capshape=serif
                    boxwidth=&clusterwidth
                    display=(notches 
                             caps 
                             mean 
                             median 
                             fill 
                             outliers)
                    fillattrs=(color=CXB9CFE7)
                    outlineattrs=GraphOutlines(color=navy thickness=0.01)
                    medianattrs=(color=navy)
                    whiskerattrs=(color=navy)
                    meanattrs=(size=%eval(&iqr_size + 1))
                    outlierattrs=(color=cx000000 
                                  symbol=square 
                                  size=&iqr_size)
                    ;

            *--- OUTLIER SCATTER PLOT: Normal Range Outliers, IF NON-MISSING.
                 Cluster width must match that of Box plot. 
                 By default, they do not match! ---*;

            IF ( MEAN(_AVALOUTLIE) NE . )

              scatterplot x=_AVISITN y=_AVALOUTLIE /
                          name='scatter'
                          group=_TRT
                          groupdisplay=cluster
                          clusterwidth=&clusterwidth
                          jitter=auto
                          markerattrs=(color=CXFF0000 
                                       symbol=circlefilled 
                                       size=%eval(&iqr_size - 1)
                                      )
                          legendlabel='Normal Range Outliers'
                          ;

            ENDIF;

            *--- Normal Range Reference lines, IF PROVIDED ---*;
            IF (EXISTS(_REFLINES))
              referenceline y=eval(coln(_REFLINES)) / lineattrs=(color=red) name='Reference Lines';
            ENDIF;

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

                  IF (EXISTS(_PVAL))
                    axistable x=_AVISITN value=_PVAL  / class=_TRT label='P Value'   classdisplay=cluster colorgroup=_TRT;
                  ENDIF;
            endinnermargin;

          endlayout;

        endgraph;

      end;
    run;
  %end;

%mend util_proc_template;
