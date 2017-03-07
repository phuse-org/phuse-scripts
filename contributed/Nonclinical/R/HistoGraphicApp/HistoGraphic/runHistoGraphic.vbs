Set oShell = CreateObject("WScript.Shell")
strHomeFolder = oShell.ExpandEnvironmentStrings("%USERPROFILE%")
Set FSO = CreateObject("Scripting.FileSystemObject")
textFilePath = FSO.BuildPath(strHomeFolder,"Documents\HistoGraphicTemp\template.xlsm")
Set objExcel = CreateObject("Excel.Application")
Set objWorkbook = objExcel.Workbooks.Open(textFilePath)


Set objWorksheet = objWorkbook.ActiveSheet

textFilePath = FSO.BuildPath(strHomeFolder,"Documents\HistoGraphicTemp\rawData.csv")
Set objWbkCsv = objExcel.Workbooks.Open(textFilePath)
Set objWksCsv = objWbkCsv.Worksheets(1)
Set objRangeSource = objWksCsv.UsedRange

cCount = objRangeSource.Columns.Count
rCount = objRangeSource.Rows.Count + (6 - 1)
Set objRangeDest = objWorksheet.Range(objWorksheet.Cells(6, 1), objWorksheet.Cells(rCount, cCount))

objRangeSource.Copy objRangeDest

objWorkbook.Save
objWorkbook.Close (False)
objExcel.Quit

Set objWorksheet = Nothing
Set objWorkbook = Nothing
Set objExcel = Nothing


textFilePath = FSO.BuildPath(strHomeFolder,"Documents\HistoGraphicTemp\template.xlsm")
Set objExcel = CreateObject("Excel.Application")
Set book = objExcel.Workbooks.Open(textFilePath,,TRUE)
Dim Arg, webBrowser
Set Arg = WScript.Arguments
webBrowser = Arg(0)
objExcel.Run "writeChart" & webBrowser
objExcel.DisplayAlerts = False
objExcel.Application.Quit
Set book = Nothing
Set objExcel = Nothing