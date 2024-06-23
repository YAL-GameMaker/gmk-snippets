@echo off
set dllPath=%~1
set solutionDir=%~2
set projectDir=%~3
set arch=%~4
set config=%~5

echo Running post-build for %config%

set extName=snippets
set dllName=snippets
set dllRel=%dllName%.dll
set cppRel=%dllName%.cpp
set outDir=%solutionDir%snippets_gml
set cppPath=%outDir%\%cppRel%

echo Combining the source files...
type "%projectDir%*.h" "%projectDir%*.cpp" >"%cppPath%" 2>nul

where /q gmxgen
if %ERRORLEVEL% EQU 0 (
gmxgen "%outDir%\%extName%.gmxgen81" ^
	--copy "%dllPath%" "%dllRel%:%arch%" ^
	--copy "%outDir%/snippets_core.gml" "snippets_core_gm81.gml"^
	--gmk-loader snippet_init_dll

) else (
	
	copy /Y "%dllPath%" "%outDir%\%dllRel%"
	
	echo postBuild.bat: Warning N/A: Could not find GmxGen - extensions will not be updated automatically. See https://github.com/YAL-GameMaker-Tools/GmxGen for setup.
)
:: copy the DLL to the test project too:
copy /Y "%outDir%\%dllRel%" "%outDir%\tester\%dllRel%"

:: clean up the mess that we made:
del /Q "%outDir%\snippets_core_gm81.gml"
del /Q "%outDir%\snippets_discard.gml"
del /Q "%outDir%\snippets_autogen.gml"
