del /Q snippets-ext.zip
del /Q snippets-tester.zip

cmd /C 7z a snippets-ext.zip snippets.gml snippets.dll
cd tester
cmd /C 7z a ..\snippets-ext.zip fnames events.gml

cmd /C 7z a ..\snippets-tester.zip *
cmd /C 7z d ..\snippets-tester.zip snippet_tester.gb1

pause