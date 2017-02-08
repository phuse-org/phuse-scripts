Set oShell = CreateObject("WScript.Shell")
strHomeFolder = oShell.ExpandEnvironmentStrings("%USERPROFILE%")
Set FSO = CreateObject("Scripting.FileSystemObject")
textFilePath = FSO.BuildPath(strHomeFolder,"Documents\KronaTemp\template.xlsm")
Set objExcel = CreateObject("Excel.Application")
Set book = objExcel.Workbooks.Open(textFilePath,,TRUE)
objExcel.Run "writeChart"
objExcel.DisplayAlerts = False
objExcel.Application.Quit
Set objExcel = Nothing