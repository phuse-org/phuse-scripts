### ADaM Test Datasets

#### Description of subfolders contents
See individual subfolder `README.md` files for further details  

  * `cdisc` - Modified & augmented version of `cdiscpilot01`, below  
    * adlbhy.xpt - addition of `ANL01FL`  
    * advs.xpt - addition of `ANL01FL`  
    * Addition of further datasets not included in `cdiscpilot01`  
      * `adcm.xpt` - 2-study data that seem out-of-place here, see `cdisc-split`, below!!   
      * `adpc.xpt` - Pharmacokinetic parameters data with different `USUBJID`s   
      * `adpp.xpt` - Pharmacokinetic parameters data with different `USUBJID`s   
      * `advsmax.xpt` - Same as `advs.xpt`, except for modified values of `CHGCAT1` (???)  
      * `advsmin.xpt` - Same contents as `advsmax.xpt` with different timestamp (???)    
  * `cdiscpilot01` - original CDISC Pilot data, published by CDISC in 2013  
  * `cdisc-split` - 2-study version of `cdiscpilot01` with addition of VS min/max datasets `advsmin.xpt` and `advsmax.xpt`  
  * `TDF_ADaM_v1.0` - Update fromo Test Data Factory team in "Standard Analyses and Code Sharing working group"  

#### Notes
The purpose and value of the `cdisc` subfolder requires clarification:
  * The purpose of `ANL01FL` are not clear - not documented?  
  * The new datasets seem out of place and require some explanation, or removal.  
