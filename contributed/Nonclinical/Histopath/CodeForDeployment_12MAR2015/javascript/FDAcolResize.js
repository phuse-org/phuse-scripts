// for ColResizable plugin for Findings table
$(function() {
  var onTableResized=function(e) {
     var columns = $(e.currentTarget).find("th");
	 var msg = "columns widths: ";
	 columns.each(function() {
	    msg += $(this).width() + "px; ";
	})
	$("#tableID").html(msg);
  };

  $('#tableID').colResizable( { 
     liveDrag:true, 
     gripInnerHtml:"<div class='grip'></div>", 
     draggingClass:'dragging', fixed:false
     onResize: onTableResized )
  } );

});
