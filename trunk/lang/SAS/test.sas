/*
test.sas
*/

* this comment was added by Mike Carniello on September 24 2012 ;
* Note that to save the file, you will need to add some comment in the bottom,
for the committ to take place ;

* this comments was added;
data class;
   set sashelp.class;
run;

proc print data=class noobs;
run;