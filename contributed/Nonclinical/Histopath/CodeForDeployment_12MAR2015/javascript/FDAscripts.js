/*
table ID values are set in ODS text macro as each table is generated
*/

$(document).ready(function() {
  $('#reportTabs').tabs();
   } ); 

$(window).load(function() { 
   var ourtable = $('#MIrptdiv').find('table')[0];
   $(ourtable).attr('id','#MItableID')
   var ourtable = $('#MArptdiv').find('table')[0];
   $(ourtable).attr('id','#MAtableID') 
   var ourtable = $('#sumrptdiv').find('table')[0];
   $(ourtable).attr('id','#sumtableID')   
   $('#MItableID').colResizable( {
      liveDrag:true, gripInnerHtml:'<div class=%quote(grip)></div>', 
      draggingClass:'dragging', fixed:false});
  } );

  //   EXPORT MICROSCOPIC FINDINGS REPORT
$("#MIexpMenu").change(function(e) {
//alert('in #MIexMenu change function');
  e.stopImmediatePropagation();
  //Get table
  var ourtable = $('#MIrptdiv').find('table')[0];
//alert('before setting - ourtable id is: ' + ourtable.id);
  var id = $('[id$="' + 'MItableID' + '"]');
  var ua = window.navigator.userAgent;
  var msie = ua.indexOf("MSIE ");
  if (msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./))  { 
     browserVer = 'IE'    /*parseInt(ua.substring(msie + 5, ua.indexOf(".",msie)));*/
	}
  else {
	 browserVer = 'other';
	}
//alert('browser version is: ' + browserVer);

   if ($(this).val() == 'ExportExcel') {
    exportToExcel(ourtable, id, browserVer, e);
	}  // end export excel was selected
   else 
    if ($(this).val() == 'ExportCSV') {
//alert('Export to CSV was selected');
      exportToCSV(ourtable, e);
    }
     else 
      if ($(this).val() == 'ExportWord') {
//alert('Export to Word was selected');
        if (browserVer == 'other') {
          $("#MIrptdiv").wordExport();
		 }
		else { exportToWord("MIrptdiv", e); }
      }
 
 } );   //end of $("#MIexpMenu") change event


 //   EXPORT MACROSCOPIC FINDINGS REPORT
$("#MAexpMenu").change(function(e) {
  e.stopImmediatePropagation();  
  //Get table
  var ourtable = $('#MArptdiv').find('table')[0];
//alert('in MAEXPMENU - ourtable id is: ' + ourtable.id);
  var id = $('[id$="' + 'MAtableID' + '"]');
  var ua = window.navigator.userAgent;
  var msie = ua.indexOf("MSIE ");
  if (msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./))  { 
     browserVer = 'IE'    /*parseInt(ua.substring(msie + 5, ua.indexOf(".",msie)));*/
	}
  else {
	 browserVer = 'other';
	}

  if ($(this).val() == 'ExportExcel') {
    exportToExcel(ourtable, id, browserVer, e);
	}  // end export excel was selected
   else 
    if ($(this).val() == 'ExportCSV') {
//alert('in MAexpMenu Export to CSV was selected');
      exportToCSV(ourtable, e); 
    }
     else 
      if ($(this).val() == 'ExportWord') {
//alert('in MAexpMenu Export to Word was selected');
        if (browserVer == 'other') {
          $("#MArptdiv").wordExport();
		 }
		else { exportToWord("MArptdiv", e); }
      }
  } );   // end of $("#MAexpmenu") change event

  // EXPORT TRIAL SUMMARY REPORT
$("#sumexpmenu").change(function(e) {
//alert('in sumexpmenu change');
  e.stopImmediatePropagation();
  //Get table
  var sumtable = $('#sumrptdiv').find('table')[0];
//alert('sumtable ID is: ' + sumtable.id);
  var id = $('[id$="' + 'sumtableID' + '"]');
  var ua = window.navigator.userAgent;
  var msie = ua.indexOf("MSIE ");
  if (msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./))  {  
     browserVer = 'IE'    /*parseInt(ua.substring(msie + 5, ua.indexOf(".",msie)));*/
	}
  else {
	 browserVer = 'other';
	}

  if ($(this).val() == 'ExportExcel') {
    exportToExcel(sumtable, id, browserVer, e);
	 }  // end export excel was selected
   else  
    if ($(this).val() == 'ExportCSV') {
//alert('Export to CSV was selected');
      exportToCSV(sumtable, e);
	 }  // end export to csv was selected
     else   
      if ($(this).val() == 'ExportWord') {
//alert('sumexpmenu: Export to Word was selected browserVer is: ' + browserVer);
        if (browserVer == 'other') {
          $("#sumrptdiv").wordExport();
		 }
		else { exportToWord("sumrptdiv", e); } 
      }  // end export to word was selected  
 
  } );   // end of $("#sumexpmenu") change event

  //     EXPORT TO EXCEL FUNCTION
function exportToExcel(table, id, browserVer, e) {

	  var infoHTML = table.outerHTML;
	  /* replace special characters for spaces */
	  infoHTML.replace(/\&nbsp;/g,' ');

//alert('in export to excel, infoHTML = : ' + infoHTML); 
    if (browserVer == 'other') {
      window.open('data:application/vnd.ms-excel,' + encodeURIComponent(infoHTML));
	  e.preventDefault();
    }
	else {
	    window.clipboardData.setData("Text", infoHTML);
//alert('in export to excel, infoHTML = ' + infoHTML);
		objExcel = new ActiveXObject("Excel.Application");
		objExcel.visible = false;
		var objWorkbook = objExcel.Workbooks.Add;
		var objWorksheet = objWorkbook.Worksheets(1);
		objWorksheet.Paste;
		objExcel.visible = true;
	}
 } // end of exportToExcel function

 
  //     EXPORT TO WORD FUNCTION
function exportToWord(table, e) {

	  
//alert('in export to word for IE'); 

        var supportsDOMRanges = document.implementation.hasFeature("Range", "2.0");
        if (supportsDOMRanges) {
          var objRange = document.createRange(); 
          objRange.selectNodeContents(document.getElementById('table'));
 
          window.getSelection().removeAllRanges();
          window.getSelection().addRange(objRange);
  
          if ( objRange.execCommand ) { 
             objRange.execCommand("Copy"); }
          else {
alert('This action may take a few minutes. If the report does not appear in the word doc, right click the highlighed report then copy and paste.');
               }
			}
		else {
	// IE browser version prior to 9
             // get the reports data and replace special characters for spaces
	         var infoHTML = document.getElementById(table).innerText.replace(/\&nbsp;/g,' ');
	         window.clipboardData.setData("Text", infoHTML);
alert('Your IE browser version does not support the feature Range, the table may lose its formatting in the Word doc.');
			 }

        if (window.ActiveXObject("Word.Application")) {
		  objWord = new ActiveXObject("Word.Application");
		  objWord.visible = false;
		  objWord.Documents.Add();
		  objWord.Selection.Paste();
		  objWord.visible = true;
		}
	
 } // end of exportToWord function

 //    EXPORT TO CSV FUNCTION
function exportToCSV(table, e) {
    //Get number of rows/columns
    var rowLength = table.rows.length;
    var colLength = table.rows[0].cells.length;
	/*-- Trial Summary has heading and column in the same row
	       and a one column heading as the first row
		   get true number of columns for the data to allow for this --*/
    var col1Length = table.rows[1].cells.length;

    //Declare string to fill with table data
    var tableString = "";

    //Get column headers
    for (var i = 0; i < colLength; i++) {
        var tableMod = table.rows[0].cells[i].innerHTML.replace(/&nbsp;/gi,'');
        tableString += tableMod.split(",").join("") + ",";
    }

    tableString = tableString.substring(0, tableString.length - 1);
    tableString += "\r\n";

    //Get row data
    for (var j = 1; j < rowLength; j++) {
        for (var k = 0; k < col1Length; k++) {
            var tableMod = table.rows[j].cells[k].innerHTML.replace(/&nbsp;/gi,'');
            tableString += tableMod.split(",").join("") + ",";
        }
        tableString += "\r\n";
    }

    //Save file
    if (navigator.appName === "Microsoft Internet Explorer" || !!navigator.userAgent.match(/Trident\/7\./)) {
        //Optional: If you run into delimiter issues (where the commas are not interpreted and all data is one cell), then use this line to manually specify the delimeter
        tableString = 'sep=,\r\n' + tableString;
	var newwindow = window.open('','_blank','');
        newwindow.document.write(tableString);
        newwindow.document.execCommand('SaveAs', true, 'data.csv');
	newwindow.close();

    } else {

    	var link=document.createElement('a');
    	link.mimeType = 'application/CSV';

    	var blob=new Blob([tableString],{type:link.mimeType});
    	var url=URL.createObjectURL(blob);
    	link.href=url;

    	link.setAttribute('download', 'data.txt');
    	link.innerHTML = "Export to CSV";
    	document.body.appendChild(link);
    	link.click();
    }
}   // end of exportToCSV function
