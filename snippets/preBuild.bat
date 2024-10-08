@echo off
goto bye
set dllPath=%~1
set solutionDir=%~2
set projectDir=%~3
set arch=%~4
set config=%~5

echo Running pre-build for %config%

where /q GmlCppExtFuncs
if %ERRORLEVEL% EQU 0 (
	echo Running GmlCppExtFuncs...
	GmlCppExtFuncs ^
	--prefix snippets^
	--cpp "%projectDir%autogen.cpp"^
	--gml "%solutionDir%snippets_gml/snippets_discard.gml"^
	--gmk "%solutionDir%snippets_gml/snippets_autogen.gml"^
	%projectDir%snippets.cpp
)
:bye