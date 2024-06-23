// stdafx.cpp : source file that includes just the standard includes
// snippets.pch will be the pre-compiled header
// stdafx.obj will contain the pre-compiled type information

#include "stdafx.h"

// TODO: reference any additional headers you need in STDAFX.H
// and not in this file

#ifdef _WINDOWS
// https://yal.cc/printf-without-standard-library/
void show_error(const char* pszFormat, ...) {
	char buf[1024];
	va_list argList;
	va_start(argList, pszFormat);
	wvsprintfA(buf, pszFormat, argList);
	va_end(argList);
	auto len = strlen(buf);
	buf[len] = '\n';
	buf[++len] = 0;
	MessageBoxA(0, buf, gm_extension_name, MB_OK | MB_ICONERROR);
}
#endif
