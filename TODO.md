### Standard Analyses Working Group Task Lists

1. [Standard Analyses (White Papers) to-do list](#white-papers-project-08)
2. [Standard Scripts (Repository Contents) to-do list](#repository-contents-project-02)
3. [GitHub Infrastructure to-do list](#repository-infrastructure-project-03)
4. [General WG5 Principles and Conventions to-do list](#wg5-principles-and-conventions)

#### [White Papers (Project 08)](http://www.phusewiki.org/wiki/index.php?title=WG5_Project_08)

##### Ongoing development & review - White papers that welcome comments and suggestions:

1. Hepatotoxicity: Clinical Trials and Integrated Summaries [see this paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_Hepatotoxicity_White_Paper)
2. Adverse Events: Clinical Trials and Integrated Summaries [see this paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_Adverse_Events_White_Paper)
3. QT Studies [see this paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_QT_Studies_White_Paper)

##### Initial planning - White papers that need further contribution and authoring:

1. Questionnaire Data [see this paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_Questionnaire_White_Paper)
2. Events of Special Interest [see this paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_Events_of_Special_Interest_White_Paper)

##### Final (published) white papers (see [PhUSE CS Final Deliverables Catalog](http://www.phuse.eu/CSS-deliverables.aspx)):

1. **2013-10** [Measures of Central Tendency: Vital Signs, ECG, Labs](http://www.phusewiki.org/wiki/images/4/48/CSS_WhitePaper_CentralTendency_v1.0.pdf) (see also [this white paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_Central_Tendency_White_Paper))
4. **2014-03** [Non-Compartmental Pharmacokinetics](http://www.phusewiki.org/wiki/images/e/ed/PhUSE_CSS_WhitePaper_PK_final_25March2014.pdf) (see also [this white paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_PK_White_Paper))
5. **2014-10** [Demographics, Disposition and Medications: Clinical Trials and Integrated Summaries](http://www.phusewiki.org/wiki/images/c/c9/CSS_WhitePaper_DemoDispMed_v1.0.pdf) (see also [this white paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_Demographics,_Disposition,_Medications_White_Paper))
2. **2015-09** [Analyses of Outliers and Shifts: Vital Signs, ECG, Labs](http://www.phusewiki.org/wiki/images/9/95/CS_WhitePaper_OutliersShifts_v1.0.pdf) (see also [this white paper's phusewiki page](http://www.phusewiki.org/wiki/index.php?title=SS_P08_Outliers/Shifts_White_Paper))

#### [Repository Contents (Project 02)](http://www.phusewiki.org/wiki/index.php?title=WG5_Project_02)

##### White Paper on Measures of Central Tendency (WPCT)

Currently, our main objective is to deliver robust, easy to use and understand SAS and R scripts for **WPCT** analyses and displays. There are several steps in this process, and therefore several ways that people can participate, learn and contribute.

For details, see our [WPCT Task List](http://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/TODO.md).

#### [Repository Infrastructure (Project 03)](http://www.phusewiki.org/wiki/index.php?title=WG5_Project_03)

Finalizing and implementing an overall project GitHub structure is the main activity for Project 03.

#### WG5 Principles and Conventions

There are several general topics to resolve, especially between the Standard Analyses (P08) and Standard Scripts (P03) teams. These arose while implementing **WPCT** analyses, so we use these analyses to illustrate the general topics.

* We have drafted:
⋅⋅* [General Output & Formatting Requirements](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/CS_General_OutputandFormattingRequirements.docx), which should apply to Standard Analyses *across* white papers, and

..* [WPCT General Requirements](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/CS_General_CentralTendencyRequirements.docx), which should apply across **WPCT** displays.

..* Do the White Paper team endorse this approach, and want to finalize these?

* Otherwise, what is the best way to specify and document analysis-specific details such as the following from **WPCT**?

..* Does the team accept the revised footnotes in the scripts and outputs, below. How/where do we document these?

..* WPCT Scripts currently restrict data to the safety population (SAFFL = 'Y'). Is this correct; should we specify/document this for each analysis?

..* Most WPCT scripts currently restrict data to "analysis" measurements (e.g., ANL01FL = 'Y'). Is this correct; should we specify/docuemnt this for each analysis?

..* Do we need more detailed specification of the ANCOVA models for pvalues?

..* Section 8.2 mentions that Figures 7.1 & 7.2 could contain additional statistics. Should we implements any specific, optional, stats?

..* Fig. 7.7 in the white paper includes least square means, otherwise not discussed in the paper. Should these be included? By default? Only optional? ...

..* Fig. 7.8 in the white paper includes additional results otherwise not discussed in the paper: "TE High n(%)" and "TE Low n(%)". What are these? Should these be included? By default? Only optional? ...
