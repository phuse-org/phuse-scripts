####################################################################################################
#  Use this to create a PC.csv file for SENDIGv3.0 from a PDF report.
#
# creat the input file by copying from the PDF table and edit the results a little to look like the example file.
# currently capitalization is important in the input file.
#
# example usage:
# perl PCfromPDF.pl <DataCopiedFromPDF.txt >pc.csv
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

use strict;
my (	$studyid,
	$domain,
	$usubjid,
	$poolid,
	$pcseq,
	$pcgrpid,
	$pcrefid,
	$pcspid,
	$pctestcd,
	$pctest,
	$pccat,
	$pcscat,
	$pcorres,
	$pcorresu,
	$pcstresc,
	$pcstresn,
	$pcstresu,
	$pcstat,
	$pcreasnd,
	$pcnam,
	$pcspec,
	$pcspccnd,
	$pcmethod,
	$pcblfl,
	$pcfast,
	$pcdrvfl,
	$pclloq,
	$pcexclfl,
	$pcreasex,
	$visitdy,
	$pcdtc,
	$pcendtc,
	$pcdy,
	$pcendy,
	$pctpt,
	$pctptnum,
	$pceltm,
	$pctptref,
	$pcrftdtc,
	$pcevlint,
	$pcnomdy,
	$t, $i, $columns, @columnsA, @values, $line_count);
#initial values.  Some get overritten by later lines.
$studyid="";
$domain="PC";
$usubjid="";
$poolid="";
$pcseq="";
$pcgrpid="";
$pcrefid="";
$pcspid="";
$pctestcd="";
$pctest="";
$pccat="";
$pcscat="";
$pcorres="";
$pcorresu="";
$pcstresc="";
$pcstresn="";
$pcstresu="";
$pcstat="";
$pcreasnd="";
$pcnam="";
$pcspec="";
$pcspccnd="";
$pcmethod="LC/MS-MS";
$pcblfl="";
$pcfast="";
$pcdrvfl="";
$pclloq="";
$pcexclfl="";
$pcreasex="";
$visitdy="";
$pcdtc="";
$pcendtc="";
$pcdy="";
$pcendy="";
$pctpt="";
$pctptnum="";
$pceltm="";
$pctptref="";
$pcrftdtc="";
$pcevlint="";
$pcnomdy="";
print("STUDYID, DOMAIN, USUBJID, POOLID, PCSEQ, PCGRPID, PCREFID, PCSPID, PCTESTCD, PCTEST, PCCAT, PCSCAT, PCORRES, PCORRESU, PCSTRESC, PCSTRESN, PCSTRESU, PCSTAT, PCREASND, PCNAM, PCSPEC, PCSPCCND, PCMETHOD, PCBLFL, PCFAST, PCDRVFL, PCLLOQ, PCEXCLFL, PCREASEX, VISITDY, PCDTC, PCENDTC, PCDY, PCENDY, PCTPT, PCTPTNUM, PCELTM, PCTPTREF, PCRFTDTC, PCEVLINT\n");
$line_count=0;
$pcseq=0;
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
		$pcspec=$1;
	}
	if ($_ =~ /PCTEST=(.*)/)
	{
		$pctest=$1;
		$pctestcd=substr($pctest,0,2).substr($pctest,-6);
		$pccat="ANALYTE";
	}	
	if ($_ =~ /PCLLOQ=(.*)/)
	{
		$pclloq=$1;
	}
	if ($_ =~ /PCTEST_unit=(.*)/)
	{
		$pcorresu=$1;
		$pcstresu=$1;
	}
	if ($_ =~ /Columns=(.*)/)
	{
		$columns=$1
	}
	if ($_ =~ /PCNOMDY=(.*)/)
	{
		$pcnomdy=$1;
	}
	if ($_ =~ /^([0-9]+.*)/)
	{
		#rows starting with a number is assumed to be the numeric animal id at the beginning of its row of concentration values.
		@values = split(/[ \t]/,$1);
		@columnsA = split(/[ \t]/,$columns);
		if (scalar @values == scalar @columnsA)
		{
			for (my $i=0; $i < scalar @values; $i++)
			{
				if ($columnsA[$i] =~ /SUBJID/)
				{
					if ($values[$i] =~ /([0-9]*).*/)  #this discards the footnotes
					{
						$usubjid=$studyid."-".$1;
					#	print "animal id = $1\n";
					}
					else
					{
						die("I'm confused\n");
					}
				}
				if ($columnsA[$i] =~ /[0-9]+\.?[0-9]*/)
				{
					$pcgrpid=$pctest."-DAY".$pcnomdy."-".$usubjid;
					#assume the column header is the number of hours post dose.
					$visitdy=$pcnomdy;
					$pcdtc="";
					$pcdy=$pcnomdy + int($columnsA[$i]/24);
					$pctpt="DAY ".$pcnomdy." ".$columnsA[$i]."H";
					$pctptnum=10000*$pcnomdy+$columnsA[$i];
					$pceltm="PT".$columnsA[$i]."H";
					$pctptref="";
					$pcrftdtc="";
					$pcseq++;
					#determine the value of the measurement
					$pcorres=$values[$i];
					$pcstresc=$pcorres;
					if ($pcorres =~ /^[0-9]+\.?[0-9]*$/)
					{
						$pcstresn = $pcorres;
					#	print "PCORRES $pcorres resulted in PCSTRESN $pcstresn\n";
					}
					else
					{
						$pcstresn = "";
					#	print "PCORRES $pcorres resulted in PCSTRESN $pcstresn\n";
					}	
					printf("$studyid,$domain,$usubjid,$poolid,$pcseq,$pcgrpid,$pcrefid,$pcspid,$pctestcd,$pctest,$pccat,$pcscat,$pcorres,$pcorresu,$pcstresc,$pcstresn,$pcstresu,$pcstat,$pcreasnd,$pcnam,$pcspec,$pcspccnd,$pcmethod,$pcblfl,$pcfast,$pcdrvfl,$pclloq,$pcexclfl,$pcreasex,$visitdy,$pcdtc,$pcendtc,$pcdy,$pcendy,$pctpt,$pctptnum,$pceltm,$pctptref,$pcrftdtc,$pcevlint\n");
				}
			}
		}
		else
		{
			die("Error: I was expecting the same number of columns in the column header ($columns) as there are values in line ($line_count); but I see ".(scalar $values[$i])." instead.\n");
		}
	}
}