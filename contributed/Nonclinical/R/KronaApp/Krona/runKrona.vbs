Set FSO = CreateObject("Scripting.FileSystemObject")
scriptPath = FSO.GetParentFolderName(WScript.ScriptFullName)
textFilePath = FSO.BuildPath(scriptPath, "temp\template.xlsm")

Set objExcel = CreateObject("Excel.Application")
Set book = objExcel.Workbooks.Open(textFilePath,,TRUE)
objExcel.Run "writeChart"
objExcel.DisplayAlerts = False
objExcel.Application.Quit
Set objExcel = Nothing