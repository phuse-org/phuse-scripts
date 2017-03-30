inFile = open('app.R','r')

outFileGlobal = open('global.R','w')
outFileServer = open('server.R','w')
outFileUI = open('ui.R','w')

serverFlag = False
uiFlag = False
for line in inFile:
	if uiFlag == False:
		if serverFlag == False:
			if line[0:6] != 'server':
				outFileGlobal.write(line)
			else:
				serverFlag = True
				outFileServer.write('library(shiny)\n\nshinyServer(function(input, output,session) {\n')
		else:
			if line[0:2] != 'ui':
				outFileServer.write(line)
			else:
				uiFlag = True
				outFileServer.write('\n)\n')
				outFileUI.write('library(shiny)\n\nshinyUI('+line[6:len(line)])
	else:
		if (line[0:8] != 'shinyApp'):
			outFileUI.write(line)
		else:
			outFileUI.write(')')

inFile.close()
outFileGlobal.close()
outFileServer.close()
outFileUI.close()