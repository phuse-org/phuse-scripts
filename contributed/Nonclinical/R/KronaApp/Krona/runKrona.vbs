Set oShell = CreateObject("WScript.Shell")
strHomeFolder = oShell.ExpandEnvironmentStrings("%USERPROFILE%")
Set FSO = CreateObject("Scripting.FileSystemObject")
textFilePath = FSO.BuildPath(strHomeFolder,"Documents\KronaTemp\template.xlsm")
Set objExcel = CreateObject("Excel.Application")
Set book = objExcel.Workbooks.Open(textFilePath,,TRUE)
Dim Arg, webBrowser
Set Arg = WScript.Arguments
webBrowser = Arg(0)
objExcel.Run "writeChart" & webBrowser
objExcel.DisplayAlerts = False
objExcel.Application.Quit
Set objExcel = Nothing