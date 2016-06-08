// function for Findings drill down 1 report
function processFindings(thisRpt, htmlval, studyid, domain, numDays) {

  var jsonFileNm = studyid + "_" + "DRILLDOWN.json";
  var firstRow = 1;

// alerts can be uncommented for debugging purposes
//alert("jsonFileNm=" + jsonFileNm + " htmlval=" + htmlval);

  $.getJSON(jsonFileNm,{key : htmlval}, function(data) {

//alert("success" + " htmlval = " + htmlval);

    // create empty string variable for HTML report
    var infoHTML = '';

    // loop through each object writing data if the id matches
    $.each(data, function() {

        $.each(this, function(dataarray, val) {

         if (val.htmlfilename == htmlval) {

//alert("in each function: htmlfilename= " + val.htmlfilename + " usubjid=" + val.usubjid);

 // write title if this is the first object from JSON for the htmlval (first unique subject)
           if (firstRow == 1) {
		     infoHTML += '<head> ';
			 infoHTML += "<script src=\'javascript/jquery-1.11.2.min.js'\></script>" +
                         "<script src=\'javascript/jquery-ui.js\'></script>" +
                         "<script src=\'javascript/FDAdrilldown.js\'></script>" +
                         "<script src=\'javascript/FDAdrillUsubj.js'\></script>";
             infoHTML += '<style>.systemtitle { background-color: #fafbfe; color: #112277;' +
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
                'Study ID: ' + studyid +  '  ' + val.findingstitle + ': ' +val.findings +
                '</span></span> </p></div>';
 
// write title headings while first unique subject
             infoHTML += '<p class="hdgtext"style=" background-color: #add8e6;' +
                'color: #112277; font-weight: bold">';
	         infoHTML += 'Group: ' + val.grouptitle + '<br>';
             infoHTML += 'Sex: ' +val.sexval + '<br>';
             infoHTML += 'Tissue Name: ' + val.tissuename ;
			 infoHTML += '</p>';

	         infoHTML += '<table style="border-spacing: 0"> <thead> <tr> ' ;
             infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;' +
                'font-weight: bold">Unique Subject Identifier</td>';
             infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;' +
                'font-weight: bold">Severity</td>';
             infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;' +
                'font-weight: bold">Result Category</td>';
  /*  trying to assign the name to retrieve from the object dynamically	         
	         for (var j = 1; j <= numDays; j++) {
			    ourDay = 'day'+j;
			    infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                   val.ourDay + '</td>';
			  }
	*/
	     // meanwhile, hardcoded up to 8 days ...
             infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                val.day1 + '</td>';
			 if (numDays > 1) {
               infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                           val.day2 + '</td>';     }
			 if (numDays > 2)  {
               infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                           val.day3 + '</td>';   }
			 if (numDays > 3)  {
               infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                           val.day4 + '</td>';   }
			 if (numDays > 4)  {
               infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                           val.day5 + '</td>';   }
			 if (numDays > 5)  {
               infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                           val.day6 + '</td>';   }
			 if (numDays > 6)  {
               infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                           val.day7 + '</td>';   }
			 if (numDays > 7)  {
               infoHTML += '<td class="c data" style="background-color: #d3d3d3; font-size: x-small;">' +
                           val.day8 + '</td>';   }

		     infoHTML += '</tr>';
 		 
			 firstRow = 0;
		}  // end write title and headings

// write each unique subject id row
//         infoHTML += '<tr><td class="data" style="color: #000000; font-size: x-small"> ' + val.usubjid + '</td>';
		  // construct HREF for 2nd drill down to individual subjid id data
          infoHTML += '<tr><td style="font-size: x-small"> ' +
		              '<a href="javascript:processUsubj(' + "'usubject', '" +  val.html2ndname + "', '" + 
                      studyid + "', '" + domain + "');" + '">' + val.usubjid + '</a>' + '</td>';

          infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.severity + '</td>';
          infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.rescat + '</td>';
	
	/*	trying to dynamically assign the name to find the day value   	         
	         for (var j = 1; j <= numDays; j++) {
			    ourval = 'day'+j+'val'; 				
			    infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' +
                  val.ourval + '</td>';
			  }
   */
       // until I can get the above working...
          infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day1val + '</td>';
		  if (numDays > 1) {
             infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day2val + '</td>';
			}
		  if (numDays > 2) {
             infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day3val + '</td>';
			}
		  if (numDays > 3) {
             infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day4val + '</td>';
			}
		  if (numDays > 4) {
             infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day5val + '</td>';
			}
		  if (numDays > 5) {
             infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day6val + '</td>';
			}
		  if (numDays > 6) {
             infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day7val + '</td>';
			}
		  if (numDays > 7) {
             infoHTML += '<td class="data" style="color: #000000; font-size: x-small">' + val.day8val + '</td>';
			}
	
          infoHTML += '<td class="data"> &#160;</td></tr>';

	     }  // write data only when key equals request key
	  });  //end of inner each(dataarray,val)

    }); //end of outer each()

    infoHTML += '</thead></table>';

    // add completed HTML for the Findings drilldown
	$("infoHTML").appendTo("inner");

   // new window name set to _blank to allow multiple windows to display at once, 
   //    rather than data overlaying already opened drill down report
	win2Obj=window.open('','_blank', 	                                     
     'width=600,height=450,toolbar=0,menubar=0,status=0,location=0,scrollbars=1,resizeable=yes,left=0,top=0');
	win2Obj.document.write(infoHTML);
    win2Obj.moveBy(100,100); 
 
  } );    // end of getJSON
 
 }    // end of function for Findings drill down 1 report



