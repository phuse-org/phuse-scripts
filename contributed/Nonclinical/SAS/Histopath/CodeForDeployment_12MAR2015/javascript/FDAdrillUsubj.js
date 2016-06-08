// INDIVIDUAL UNIQUE SUBJECT Findings drill down 2 report
function processUsubj(thisRpt, html2val, studyid, domain) {

    var jsonFileNm = studyid + "_" + "DRILLDOWN.json" ;
//alert('in processusubj  .json file is: ' + jsonFileNm);

    // create empty string variable for HTML report
    var infoHTML = '';
	firstRow = 1;

  /* For the 2nd drill down report there is only one object in the JSON file per report */
   $.getJSON(jsonFileNm,{key : html2val}, function(data) {

//alert("success for individual usubjid JSON call" + " html2val = " + html2val);

//    $.each(data,function(dataaray, val) {

    // loop through each object writing data if the id matches
    $.each(data, function() {

        $.each(this, function(dataarray, val) {

         if (val.html2name == html2val) {

		   if (firstRow == 1) {
		     firstRow = 0;
	  //infoHTML += "<head> <link rel='stylesheet' href='styles.myfdatmpl'> </head>";
	  
	  infoHTML += '<head><style>.systemtitle { background-color: #fafbfe; color: #112277;' +
                ' font-family: Arial, Albany AMT, Helvetica, Helv; font-size: small;' +
                ' font-style: normal; font-weight: bold; } ' ;
	  infoHTML += '.hdgtext { background-color: #add8e6; color: #112277;' +
                ' font-family: Arial, Albany AMT, Helvetica, Helv; font-size: x-small;' +
                ' font-style: normal; font-weight: bold; border-style: solid; border-width: 0 1px 1px 0; ' ;
      infoHTML += '.data { background-color: #ffffff; color: #c1c1c1;' +
                ' border-style: solid; border-width: 0 1px 1px 0;' +
                ' font-family: Arial, Albany AMT, Helvetica, Helv; font-size: x-small;' +
                ' font-style: normal; font-weight: normal; } ' ;

      infoHTML += '.usertext { background-color: fafbfe; color: #112277;' +
                ' border-style: solid; border-width: 0 1px 1px 0;' +
                ' font-family: Arial, Albany AMT, Helvetica, Helv; font-size: x-small;' +
                ' font-style: normal; font-weight: normal; } ' ;
      infoHTML += '</style></head>';

 	  infoHTML += '<div id="ttl" class="systitleandfootercontainer" style="border-spacing: 1px">' +
                  '<p><span class="c systemtitle"><span style="font-size: 12pt; font-weight: bold">' +
				  'Unique Subject ID: ' + val.usubjid + '  Study ID: ' + studyid +  
                  '  ' + val.findingstitle + '</span></span> </p></div>';

	        }   // end if first row

	  infoHTML += '<table class="table" style="border-spacing: 0"> <thead> <tr>';
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Sponsor Defined Group Code</td>';
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Sponsor Defined Group Label</td>';	
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Control Type</td>';
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Species</td>';
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Strain/Substrain</td>';
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Strain/Substrain Details</td>';
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Subject Reference Start Date/Time (Source)</td>';
	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Subject Reference Start Date/Time</td>';
	  infoHTML += '</tr>';

	  infoHTML += '<tr> <td class="c data" style="color: #000000; font-size: x-small">' + val.spgrpcd + '</td>';
	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.grplbl + '</td>';
	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.controltype + '</td>';
	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.species + '</td>';
	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.strain + '</td>';
	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.sbstrain + '</td>';
	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.subjrefstrtsrc + '</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.rfstdtc + '</td> </tr>';

 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Subject Reference End Date/Time (Source)</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Subject Reference End Date/Time</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Date of Birth(Source)</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Date of Birth</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Age</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Age Range</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Age Unit</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Threat Day</td>';
 	  infoHTML += '</tr> <tr>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.subjrefendsrc + '</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.rfendtc + '</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.dateofbirthsrc + '</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.brthdtc + '</td>';
	  /*-- source for Age ? --*/
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small"> &#160;</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.agetxt + '</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small">' + val.ageu + '</td>';
	  /*-- source for Threat Day ? --*/
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small"> &#160;</td>  </tr>';

 	  infoHTML += '<tr> <td class="usertext" style="background-color: #d3d3d3">Order of Threat</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Animal&quot;s Pathogen Status</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Common Name</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Planned Arm Code</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3">Description of Planned Arm</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3"> &#160;</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3"> &#160;</td>';
 	  infoHTML += '<td class="usertext" style="background-color: #d3d3d3"> &#160;</td>';
 	  infoHTML += '</tr> <tr>';
	  /*-- source for Order of Threat ? --*/
 	  infoHTML += '<td class="c data"> &#160;</td>';
	  /*-- source for Animal's Pathogen Status ? --*/
 	  infoHTML += '<td class="c data"> &#160;</td>';
	  /*-- source for Common Name ? --*/
 	  infoHTML += '<td class="c data"> &#160;</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small"">' + val.armcd + '</td>';
 	  infoHTML += '<td class="c data" style="color: #000000; font-size: x-small"">' + val.arm_orig + '</td>';
 	  infoHTML += '<td class="c data"> &#160;</td>';
 	  infoHTML += '<td class="c data"> &#160;</td>';
 	  infoHTML += '<td class="c data"> &#160;</td>  </tr>';

	     }  // end of write data only when key equals requested key

      } );   // end of .each loop through HTML2NAME object

    } );   // end of .each loop through JSON data

    infoHTML += '</thead></table>';

    // add completed HTML for the Findings drilldown to unique subject
	$("infoHTML").appendTo("inner");

   // new window name set to _blank to allow multiple windows to display at once, 
   //    rather than data overlaying already opened drill down report
	win2Obj=window.open('','_blank', 	                                     
     'width=800,height=350,toolbar=0,menubar=0,status=0,location=0,scrollbars=1,resizeable=yes,left=0,top=0');
	win2Obj.document.write(infoHTML);
    win2Obj.moveBy(300,200); 


   } );     // end of getJSON

  }   // end of processUsubj




