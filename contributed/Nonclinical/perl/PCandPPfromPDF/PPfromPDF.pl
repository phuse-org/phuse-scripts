####################################################################################################
#  Use this to create a PP.csv file for SENDIGv3.0 from a PDF report.
#
# creat the input file by copying from the PDF table and edit the results a little to look like the example file.
# currently capitalization is important in the input file.
#
# example usage:
# perl PPfromPDF.pl <DataCopiedFromPDF.txt >pp.csv
#
# This is intended to be used with a RELREC table that relates PC and PP domains together using PCGRPID and PPGRPID as a MANY to MANY relationship as
# shown in the first table in section 6.3.12.3 of SENDIGv3.0
#
# Pay carful attention to the footnotes and adjust the data and CO records as needed to represent this information.
#
###YYYY-MM-DD#########################################################################################
#  2016-12-13	W. Houser initially created this script.
#  2017-02-02   W. Houser minor adjustments to recogize other white space as field seperators
######################################################################################################

use List::Util qw[min max];
use strict;
my (	$studyid,
	$domain,
	$usubjid,
	$poolid,
	$ppseq,
	$ppgrpid,
#	$pprefid,
#	$ppspid,
	$pptestcd,
	$pptest,
	$ppcat,
	$ppscat,
	$pporres,
	$pporresu,
	$ppstresc,
	$ppstresn,
	$ppstresu,
	$ppstat,
	$ppreasnd,
#	$ppnam,
	$ppspec,
#	$ppspccnd,
#	$ppmethod,
#	$ppblfl,
#	$ppfast,
#	$ppdrvfl,
#	$pplloq,
#	$ppexclfl,
#	$ppreasex,
	$visitdy,
#	$ppdtc,
#	$ppendtc,
#	$ppdy,
#	$ppendy,
#	$pptpt,
#	$pptptnum,
#	$ppeltm,
	$pptptref,
	$pprftdtc,
	$ppstint,   #not in pc
	$ppenint,   #not in pc
#	$ppevlint,
	$ppnomdy,   #not in SEND 3.0 but is in report; so I'm using it to populate SEND 3.0 variables.
	$t, $i, $columns, @columnsA, @values, $line_count);
#initial values.  Some get overritten by later lines.
$studyid="";
$domain="PP";
$usubjid="";
$poolid="";
$ppseq="";
$ppgrpid="";
$pptestcd="";
$pptest="";
$ppcat="";
$ppscat="NONCOMPARTMENTAL";
$pporres="";
$pporresu="";
$ppstresc="";
$ppstresn="";
$ppstresu="";
$ppstat="";
$ppreasnd="";
$ppspec="";
$visitdy="";
$pptptref="";
$pprftdtc="";
$ppstint="PT0H";
$ppenint="";
$ppnomdy="";
print("STUDYID, DOMAIN, USUBJID, POOLID, PPSEQ, PPGRPID, PPTESTCD, PPTEST, PPCAT, PPSCAT, PPORRES, PPORRESU, PPSTRESC, PPSTRESN, PPSTRESU, PPSTAT, PPREASND, PPSPEC, VISITDY, PPTPTREF, PPRFTDTC, PPSTINT, PPENINT\n");
$line_count=0;
$ppseq=0;
$t=0; #time in hours of the evaluation interval.
while (<>)
{
	$line_count++;
#	print $line_count."\t".$_;
	if ($_ =~ /STUDYID=(.*)/)
	{
		$studyid=$1;
	}
	if ($_ =~ /PCSPEC=(.*)/)
	{
		$ppspec=$1;
	}
	if ($_ =~ /PCTEST=(.*)/)
	{
		$ppcat=$1;
	}
	if ($_ =~ /Columns=(.*)/)
	{
		$columns=$1;
		$t=0; #if we have a new set of column lables we need to re-determine the time interval
	}
	if ($_ =~ /PCNOMDY=(.*)/)
	{
		$ppnomdy=$1;
	}
	if ($_ =~ /^([0-9]+.*)/)
	{
		#rows starting with a number is assumed to be the numeric animal id at the beginning of its row of concentration values.
		@values = split(/[ \t]/,$1);
		@columnsA = split(/[ \t]/,$columns);
		if (scalar @values == scalar @columnsA)  #confirm the number of columns match the number of column headers
		{
			for (my $i=0; $i < scalar @values; $i++) #loop through the columns
			{
				if ($columnsA[$i] =~ /SUBJID/)
				{
					if ($values[$i] =~ /([0-9]*).*/)
					{
						$usubjid=$studyid."-".$1;
					#	print "animal id = $1\n";
					}
					else
					{
						die("I'm confused\n");
					}
				}
				else
				{
					if ($columnsA[$i] =~ /[0-9]+\.?[0-9]*/)
					{	#look for the highest time value in the table heading.
						$t = max($t, $columnsA[$i]);
					}
					else
					{
						# transform
						#	"CMAX(ng/mL)" to be "CMAX" and "ng/mL"
						#	"AUCINT(ng*h/mL) to be "AUCINT" and "ng*h/mL"
						# 
						if ($columnsA[$i] =~ /(.*)\((.*)\)/)
						{
							$pporresu=$2;	
							$ppstresu=$2;
							$pptestcd =$1; 
							$pptest = $1;
						}
						else
						{
							die("The column header for PP parameters is expected to be in the form parameter(unit).\n");
						}
						$ppgrpid=$pptest."-DAY".$ppnomdy."-".$usubjid;
						#assume the column header is the number of hours post dose.
						$visitdy=$ppnomdy;
						$pptptref="";
						$pprftdtc="";
						$ppseq++;
						#determine the value of the measurement
						if ($values[$i] =~ /^([0-9]+\.?[0-9]*)(.*)/) #strips of any footnote flags into $2.
						{
							$pporres=$1;
							$ppstresc=$pporres;
							$ppstresn = $pporres;
						#	print "PPORRES $pporres resulted in PPSTRESN $ppstresn\n";
						}
						else
						{
							$pporres=$values[$i];
							$ppstresc=$pporres;
							$ppstresn = "";
						#	print "PPORRES $pporres resulted in PPSTRESN $ppstresn\n";
						}
						$ppenint = "PT".$t."H";
						printf("$studyid,$domain,$usubjid,$poolid,$ppseq,$ppgrpid,$pptestcd,$pptest,$ppcat,$ppscat,$pporres,$pporresu,$ppstresc,$ppstresn,$ppstresu,$ppstat,$ppreasnd,$ppspec,$visitdy,$pptptref,$pprftdtc,$ppstint, $ppenint\n");
					}
				}
				
			}
		}
		else
		{
			die("Error: I was expecting the same number of columns in the column header ($columns) as there are values in line ($line_count); but I see (scalar $values[$i]) instead.\n");
		}
	}
}