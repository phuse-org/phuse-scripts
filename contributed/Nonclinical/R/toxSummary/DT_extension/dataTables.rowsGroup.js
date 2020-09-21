/*! RowsGroup for DataTables v2.0.0
 * 2015-2016 Alexey Shildyakov ashl1future@gmail.com
 * 2016 Tibor Wekerle
 */

/**
 * @summary     RowsGroup
 * @description Group rows by specified columns
 * @version     2.0.0
 * @file        dataTables.rowsGroup.js
 * @author      Alexey Shildyakov (ashl1future@gmail.com)
 * @contact     ashl1future@gmail.com
 * @copyright   Alexey Shildyakov
 * 
 * License      MIT - http://datatables.net/license/mit
 *
 * This feature plug-in for DataTables automatically merges columns cells
 * based on it's values equality. It supports multi-column row grouping
 * in according to the requested order with dependency from each previous 
 * requested columns. Now it supports ordering and searching. 
 * Please see the example.html for details.
 * 
 * Rows grouping in DataTables can be enabled by using any one of the following
 * options:
 *
 * * Setting the `rowsGroup` parameter in the DataTables initialisation
 *   to array which containes columns selectors
 *   (https://datatables.net/reference/type/column-selector) used for grouping. i.e.
 *    rowsGroup = [1, 'columnName:name', ]
 * * Setting the `rowsGroup` parameter in the DataTables defaults
 *   (thus causing all tables to have this feature) - i.e.
 *   `$.fn.dataTable.defaults.RowsGroup = [0]`.
 * * Creating a new instance: `new $.fn.dataTable.RowsGroup( table, columnsForGrouping );`
 *   where `table` is a DataTable's API instance and `columnsForGrouping` is the array
 *   described above.
 *
 * For more detailed information please see:
 *     
 */

(function($){

ShowedDataSelectorModifier = {
	order: 'current',
	page: 'current',
	search: 'applied',
}

GroupedColumnsOrderDir = 'asc';


/*
 * columnsForGrouping: array of DTAPI:cell-selector for columns for which rows grouping is applied
 */
var RowsGroup = function ( dt, columnsForGrouping )
{
	this.table = dt.table();
	this.columnsForGrouping = columnsForGrouping;
	 // set to True when new reorder is applied by RowsGroup to prevent order() looping
	this.orderOverrideNow = false;
	this.mergeCellsNeeded = false; // merge after init
	this.order = []
	
	var self = this;
	dt.on('order.dt', function ( e, settings) {
		if (!self.orderOverrideNow) {
			self.orderOverrideNow = true;
			self._updateOrderAndDraw()
		} else {
			self.orderOverrideNow = false;
		}
	})
	
	dt.on('preDraw.dt', function ( e, settings) {
		if (self.mergeCellsNeeded) {
			self.mergeCellsNeeded = false;
			self._mergeCells()
		}
	})
	
	dt.on('column-visibility.dt', function ( e, settings) {
		self.mergeCellsNeeded = true;
	})

	dt.on('search.dt', function ( e, settings) {
		// This might to increase the time to redraw while searching on tables
		//   with huge shown columns
		self.mergeCellsNeeded = true;
	})

	dt.on('page.dt', function ( e, settings) {
		self.mergeCellsNeeded = true;
	})

	dt.on('length.dt', function ( e, settings) {
		self.mergeCellsNeeded = true;
	})

	dt.on('xhr.dt', function ( e, settings) {
		self.mergeCellsNeeded = true;
	})

	this._updateOrderAndDraw();
	
/* Events sequence while Add row (also through Editor)
 * addRow() function
 *   draw() function
 *     preDraw() event
 *       mergeCells() - point 1
 *     Appended new row breaks visible elements because the mergeCells() on previous step doesn't apllied to already processing data
 *   order() event
 *     _updateOrderAndDraw()
 *       preDraw() event
 *         mergeCells()
 *       Appended new row now has properly visibility as on current level it has already applied changes from first mergeCells() call (point 1)
 *   draw() event
 */
};


RowsGroup.prototype = {
	setMergeCells: function(){
		this.mergeCellsNeeded = true;
	},

	mergeCells: function()
	{
		this.setMergeCells();
		this.table.draw();
	},

	_getOrderWithGroupColumns: function (order, groupedColumnsOrderDir)
	{
		if (groupedColumnsOrderDir === undefined)
			groupedColumnsOrderDir = GroupedColumnsOrderDir
			
		var self = this;
		var groupedColumnsIndexes = this.columnsForGrouping.map(function(columnSelector){
			return self.table.column(columnSelector).index()
		})
		var groupedColumnsKnownOrder = order.filter(function(columnOrder){
			return groupedColumnsIndexes.indexOf(columnOrder[0]) >= 0
		})
		var nongroupedColumnsOrder = order.filter(function(columnOrder){
			return groupedColumnsIndexes.indexOf(columnOrder[0]) < 0
		})
		var groupedColumnsKnownOrderIndexes = groupedColumnsKnownOrder.map(function(columnOrder){
			return columnOrder[0]
		})
		var groupedColumnsOrder = groupedColumnsIndexes.map(function(iColumn){
			var iInOrderIndexes = groupedColumnsKnownOrderIndexes.indexOf(iColumn)
			if (iInOrderIndexes >= 0)
				return [iColumn, groupedColumnsKnownOrder[iInOrderIndexes][1]]
			else
				return [iColumn, groupedColumnsOrderDir]
		})
		
		groupedColumnsOrder.push.apply(groupedColumnsOrder, nongroupedColumnsOrder)
		return groupedColumnsOrder;
	},
 
	// Workaround: the DT reset ordering to 'asc' from multi-ordering if user order on one column (without shift)
	//   but because we always has multi-ordering due to grouped rows this happens every time
	_getInjectedMonoSelectWorkaround: function(order)
	{
		if (order.length === 1) {
			// got mono order - workaround here
			var orderingColumn = order[0][0]
			var previousOrder = this.order.map(function(val){
				return val[0]
			})
			var iColumn = previousOrder.indexOf(orderingColumn);
			if (iColumn >= 0) {
				// assume change the direction, because we already has that in previos order
				return [[orderingColumn, this._toogleDirection(this.order[iColumn][1])]]
			} // else This is the new ordering column. Proceed as is.
		} // else got milti order - work normal
		return order;
	},
	
	_mergeCells: function()
	{
		var columnsIndexes = this.table.columns(this.columnsForGrouping, ShowedDataSelectorModifier).indexes().toArray()
		var showedRowsCount = this.table.rows(ShowedDataSelectorModifier)[0].length 
		this._mergeColumn(0, showedRowsCount - 1, columnsIndexes)
	},
	
	// the index is relative to the showed data
	//    (selector-modifier = {order: 'current', page: 'current', search: 'applied'}) index
	_mergeColumn: function(iStartRow, iFinishRow, columnsIndexes)
	{
		var columnsIndexesCopy = columnsIndexes.slice()
		currentColumn = columnsIndexesCopy.shift()
		currentColumn = this.table.column(currentColumn, ShowedDataSelectorModifier)
		
		var columnNodes = currentColumn.nodes()
		var columnValues = currentColumn.data()
		
		var newSequenceRow = iStartRow,
			iRow;
		for (iRow = iStartRow + 1; iRow <= iFinishRow; ++iRow) {
			
			if (columnValues[iRow] === columnValues[newSequenceRow]) {
				$(columnNodes[iRow]).hide()
			} else {
				$(columnNodes[newSequenceRow]).show()
				$(columnNodes[newSequenceRow]).attr('rowspan', (iRow-1) - newSequenceRow + 1)
				
				if (columnsIndexesCopy.length > 0)
					this._mergeColumn(newSequenceRow, (iRow-1), columnsIndexesCopy)
				
				newSequenceRow = iRow;
			}
			
		}
		$(columnNodes[newSequenceRow]).show()
		$(columnNodes[newSequenceRow]).attr('rowspan', (iRow-1)- newSequenceRow + 1)
		if (columnsIndexesCopy.length > 0)
			this._mergeColumn(newSequenceRow, (iRow-1), columnsIndexesCopy)
	},
	
	_toogleDirection: function(dir)
	{
		return dir == 'asc'? 'desc': 'asc';
	},
 
	_updateOrderAndDraw: function()
	{
		this.mergeCellsNeeded = true;
		
		var currentOrder = this.table.order();
		currentOrder = this._getInjectedMonoSelectWorkaround(currentOrder);
		this.order = this._getOrderWithGroupColumns(currentOrder)
		this.table.order($.extend(true, Array(), this.order))
		this.table.draw()
	},
};


$.fn.dataTable.RowsGroup = RowsGroup;
$.fn.DataTable.RowsGroup = RowsGroup;

// Automatic initialisation listener
$(document).on( 'init.dt', function ( e, settings ) {
	if ( e.namespace !== 'dt' ) {
		return;
	}

	var api = new $.fn.dataTable.Api( settings );
	
	if ( settings.oInit.rowsGroup ||
		 $.fn.dataTable.defaults.rowsGroup )
	{
		options = settings.oInit.rowsGroup?
			settings.oInit.rowsGroup:
			$.fn.dataTable.defaults.rowsGroup;
		var rowsGroup = new RowsGroup( api, options );
		$.fn.dataTable.Api.register( 'rowsgroup.update()', function () {
			rowsGroup.mergeCells();
			return this;
		} );
		$.fn.dataTable.Api.register( 'rowsgroup.updateNextDraw()', function () {
			rowsGroup.setMergeCells();
			return this;
		} );
	}
} );

}(jQuery));

/*

TODO: Provide function which determines the all <tr>s and <td>s with "rowspan" html-attribute is parent (groupped) for the specified <tr> or <td>. To use in selections, editing or hover styles.

TODO: Feature
Use saved order direction for grouped columns
	Split the columns into grouped and ungrouped.
	
	user = grouped+ungrouped
	grouped = grouped
	saved = grouped+ungrouped
	
	For grouped uses following order: user -> saved (because 'saved' include 'grouped' after first initialisation). This should be done with saving order like for 'groupedColumns'
	For ungrouped: uses only 'user' input ordering
*/
