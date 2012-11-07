data one ;
  length group $8 ;
  censor = 0 ;
  arm = "Arm 1" ;
  do day = 143,164,188,188,190,192,206,213,216,220,227.230,
           234,246,265,304 ;
    output ;
  end ;
  censor = 1 ;
  day = 216 ; output ;
  day = 244 ; output ;
  censor = 0 ;
  arm = "Arm 2" ;
  do day = 142,156,163,198,205,232,232,233,233,233,233,239,
           240, 261, 280, 280, 296, 296, 323 ;
    output ;
  end ;
  censor = 1 ;
  day = 204 ; output ;
  day = 344 ; output ;
  run ;
  
ods pdf file = "/bdm/myfolder/mcarniel/kmplot.pdf" ;
ods listing close ;
ods graphics on ;

proc lifetest data=one plots=survival (atrisk=0 to to 330 by 30) ;
  time day*censor(1) ;
  srata arm ;
  title1 "Example K-M Plot" ;
  run ;
  
ods graphics off ;
ods pdf close ;
