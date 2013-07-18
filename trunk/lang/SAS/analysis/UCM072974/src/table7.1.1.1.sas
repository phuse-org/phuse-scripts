/*
Initial draft of table specified in "docs" folder, on page 54 of UCM072974:
Table 7.1.1.1
Deaths Listing

NOTES:    
A footnote should describe the rule for including deaths in the table (e.g., all deaths that occurred during a period of drug exposure or within a period of up to 30 days following discontinuation from drug and also those occurring later but resulting from adverse events that had an onset during drug exposure or during the 30-day follow up period). Other rules may be equally appropriate Deaths occurring outside the time window for this table should be listed elsewhere.

This table should be provided by the sponsor in electronic format. The exact design of the table and the preferred electronic format should be established in discussions between the sponsor and the reviewing division.

Similar lists should be provided for patients exposed to placebo and active control drugs.

This is the data lock date for entering data into this table (i.e., the date beyond which additional exposed patients were not available for entry). Generally this date should be no more than several months prior to the submission date for an NDA. This date as well as this table may likely need to be updated during the course of NDA review as more data become available.

Dose at time of death, or if death occurred after discontinuation, note that, as well as last dose before discontinuation.

Time (days) = days on drug at time of death; or if death occurred after discontinuation, note how many days on drug before discontinuation and also how many days off drug at time of death.

This listing should include all deaths meeting the inclusion rule, whether arising from a clinical trial or from any secondary source (e.g., postmarketing experience). The source should be identified in this column (i.e., 10 for deaths arising from primary source clinical trials and 20 for those arising from secondary sources). [Kim M: not sure where this is coming from ADaM]

Person Time should identify patients (yes/no) for whom person-time data are available, so the reviewer can know which patients were included in the mortality rate calculations. [Kim M: not sure where this variable would come from in ADaM]

Since narrative summaries should be available for all deaths, the description can be very brief (e.g., myocardial infarction, stroke, pancreatic cancer, suicide by drowning).[Kim M: not sure where this is coming from SDTM/ADaM - need just cause or also want to include information from death details dataset]
*/

data dth ;
   merge dm (where = (dthfl = 'Y'))
         ex ;
   by subjid ;
   if last.exdt;
   if dthdtc gt rfendtc then dthdy = rfendtc-rfstdtc + 1||'/'|| dthdtc-rfendtc ;
   else dthdy = dthdtc - rfstdtc + 1;
run ;

proc report data=dth nofs headline headskip;
   column studyid / group width=10 'Trial';
   define siteid/ group width=10 'Center';
   define subjid / width=10 'Patient' ;
   define age / width=10 'Age (yrs)';
   define sex / width=10 'Sex';
   define exdose / width=10 'Dose (mg)';
   define dthdy / width=10 'Time (days)'; 
   define source / width=10 'Source'; 
   define psntime / width=10 'Person Time';
   define desc / width=10 'Description';
   title1 'Table 7.1.1.1';
   title2 'Deaths Listing';
   title3 'Treatment = New Drug';
   title4 'Cutoff Date';
   footnote1 'All deaths that occurred within a period of up to 30 days following discontinuation from drug' ;
run;

