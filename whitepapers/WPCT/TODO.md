### WPCT Task List

The Repository Content team aim to deliver a package of robust, easy to use and understand SAS and R scripts that create the WPCT standard analyses and displays. For further details, see [the README file in this folder](./README.md).

**But feel free to be creative** when considering the expertise that you can contribute:
* Do you have Spotfire expertise, and time to create templates for these analyses?
* Do you have RStudio Shiny expertise, and time to create a web interface to our R scripts?
* Other expertise in Testing, Spec writing, Documentation, etc?

#### Targets for our WPCT package

Scripts below by default produce outputs based on a specific ADaM domain such as Vital Signs. The Central Tendency analyses, however, apply equally to Vital Signs, Laboratory and ECG data. These ADaM domains differ both in variables (e.g., timing variables) and variable names (e.g., analysis flags). This leads to several tasks to complete for this project:

* Establish conventions for providing easy to use and understand Central Tendency scripts that can accomodate at least these three intended data domains: Vital Signs, Laboratory and ECG.
* Update the [specifications for Central Tendency figures](https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification) to accurately describe domain differences.
* Update implementation of Central Tendency figures according to conventions for supporting intended data domains.
* Update guides for users and contributors according to conventions for supporting intended data domains.

| Target | Specify | Implement | Review | Release |
|---|---|---|---|---|
|![Fig. 7.1](../images/wpct/target_07.01.png)<br/>[Ex. SAS](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.01_Box_plot_DIABP_by_visit_for_timepoint_815.pdf)<br/>[Ex. R](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_r/WPCT-F.07.01%20R%20Output%20Example.PNG)|Review [specs](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/WPCT_Fig_7.1_RequirementsSpecification.docx)|[R script](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/WPCT-F.07.01.R)<br/> [SAS script](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/WPCT-F.07.01.sas)|Review & Test code on your own data| *release upon successful review*|
|![Fig. 7.2](../images/wpct/target_07.02.png)<br/>[Ex. SAS](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.01_Box_plot_DIABP_by_visit_for_timepoint_815.pdf)<br/>Ex. R|Review [specs](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/WPCT_Fig_7.2_RequirementsSpecification.docx)|[R script](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/WPCT-F.07.02.R)<br/>[SAS script](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/WPCT-F.07.02.sas)|Review & Test code on your own data| *release upon successful review*|
|![Fig. 7.3](../images/wpct/target_07.03.png)<br/>Ex. SAS<br/>Ex. R|Create specs|R script<br/>SAS script|Review & Test code on your own data| *release upon successful review*|
|![Fig. 7.5](../images/wpct/target_07.05.png)<br/>Ex. SAS<br/>Ex. R|Create specs|R script<br/>SAS script|Review & Test code on your own data| *nb: low priority, see [annotated white paper](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/Annotated-CSS_WhitePaper_CentralTendency_v1.0.pdf)*|
|![Fig. 7.6](../images/wpct/target_07.06.png)<br/>Ex. SAS<br/>Ex. R|Create specs|R script<br/>SAS script|Review & Test code on your own data| *release upon successful review*|
|![Fig. 7.7](../images/wpct/target_07.07.png)<br/>Ex. SAS<br/>Ex. R|Create specs|R script<br/>SAS script|Review & Test code on your own data| *release upon successful review*|
|![Fig. 7.8](../images/wpct/target_07.08.png)<br/>Ex. SAS<br/>Ex. R|Create specs|R script<br/>SAS script|Review & Test code on your own data| *release upon successful review*|
| | | | |*a template row follows*|
|![Fig. A.b](../images/wpct/target_A.b.png)<br/>[Ex. SAS]()<br/>[Ex. R]()|Review [specs]()|[R script]()<br/>[SAS script]()|Review & Test code on your own data| *release upon successful review*|
