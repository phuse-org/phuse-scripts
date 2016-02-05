# Metadata Tag Description

| Metadata Tag | Explanation | 
|:--- |:--- |
|**KeyWords**: | Key words to be used to categorize and search the script.| 
|**Script**: | Metadata tag group for defining the script.| 
|  Desc   : | Script description | 
|  Name   : | Script name following the proposed convention: https://github.com/phuse-org/phuse-scripts/blob/master/naming_conventions_proposed.txt| 
|  GCR    : | Google Code or Github code revision number such as r135 or 234 |
|  SRV    : | Stage revision version ?? Contributed | 
|  URL    : | URL linked to the source of this script in the repository | 
|  Source : | Whether the script is based on the whitepaper or from other source |
|  Target : | a link to the target or whitepaper | 
|  Title  : | A descriptive title for the script | 
|  Topic  : | How topic the script is about |
|  Type   : | What type this script addresses: Table, Figure or List |
|  Subtype: | Sub-type such as boxplot, analysis, etc. 
|**Package**: | Metadata tag group for defining the package | 
|  name : | Name for the package such as White Paper abbreviation, for example: WPCT | 
|  title: | Title for the package such as White Paper title, for example: White Paper on Measures of Central Tendency |
|**Language**: | Metadata tag group for defining the language used to program
|  name   : | Computer language such as SAS, R, PL/SQL, YML, etc. |
|  version: | Version of the language that script can be used | 
|**Environment**: | Metadata tag group for defining statistical computing environment |
|  OS : | Operating system such as Window 2012, Linux, Unix, etc. | 
|  os_version : | OS version | 
|**Comments**: | Comments about the script. This is s multi-line field. |
|**Inputs**: | Metadata tag group for defining input parameters. | 
|  datasets: | a list of data sets to be used by this script such as dat1, dat2, dat3 | 
|  P1: | 1st parameter such as "String - dataset name" | 
|  P2: | 2nd parameter such as "Number - depart id" | 
|  P3: | 3rd parameter such as "String - subject id" |
|**Outputs**: | Metadata tag group for defining output parameters | 
|  datasets: | a list of output data sets such as out1, out2, out3 |
|  O1: | 1st output parameter |
|  O2: | 2nd output parameter |
|**Authors**: | Medatadata tag group for providing author information |
|  - name   : | The 1st Author name such as Jon Doo |
|    email  : | The email address of the first author such as jon.doo@phuse.com |
|    company: | The organization name of the 1st author such as PhUSE |
|  - name   : | The 2nd Author name such as Jim Boo |
|    email  : | The email address of the 2nd author such as jim.boo@phuse.com |
|    company: | The organization name of the 2nd author such as PhUSE|
|**Qualification**: | Metadata tag group for documenting the qualification process and status | 
|  LastQualDate: | The last date the script being qualified; the date format is DD-MON-YYYY |
|  LastQualBy: | The name of the person who conducted the qualification; the name format is FirstName LastName |
|  Stage: | The stage of the qualification such as D
|  Document: | qualification documents | 
|  Note: | The description about the qualification such as C - Contributed; D - Development; T - Testing; Q - Qualified |
|**Stages**: | The historical stages for the script. | 
|  - Date: | Date the 1st stage of the script in the format of mm/dd/yyyy |
|    Name: | Name of the person who reviewed and set the stage. | 
|    Stage: | The 1st Stage of the script at that time. | 
|    Docs: | a link to qualification documents |
|  - Date: | Date of the 2nd stage of the script in the format of mm/dd/yyyy | 
|    Name: | Name of the person who reviewed and set the stage. | 
|    Stage: | The 2nd stage of the script at that time. |  	
|    Docs: | a link to qualification documents |
|**Rating**: | The rating the user provided in the scale of 5.| 
|  - User: | the first user name | 
|    Date: | the date the rating was provided.|
|    Association: | company or organization name |
|    Stars: | number in the scale of 1 to 5 |
|  - User: | the 2nd user name | 
|    Date: | the date the rating was provided.|
|    Association: | company or organization name |
|    Stars: | number in the scale of 1 to 5 |
	

# Simple Index Table
| Column Name | Explanation | 
|:--- |:--- |
| Script | Script file name linked (**Script:URL**) to the script source code with **Script:Title** (**Language:name** [**Language:version**] **Script:GCR** and **Script:SRV**) as popup message. |
| Target | **Script:Source** linked to the **Script:Target** with **Script:Desc** and **Keywords** as popup message. |  
| Stage | **Qualification:Stage** linked to the metadata file with **Qualification**, **Authors** and **Stages** as popup message. |
| Rating | **Rating:Stars** linked to metadata tag description page with **Rating** history as popup message. |

# Standard Script Index Table
| Column Name | Explanation |
|:--- |:--- |
| Name | Script file name linked (**Script:URL**) to the script source code |
| Title | **Script:Title** |
| Source | **Script:Source** linked to the **Script:Target** |
| Type | **Script:Type** (**Script:Subtype**) |
| Language | **Language:name** (**Language:version**) |
| Keywords | **Keywords** |
| Qualification | **Qualification:Stage** |

