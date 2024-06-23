// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once
#define gm_extension_name "snippets"

#ifdef _WINDOWS
	#include "targetver.h"
	
	#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
	#include <windows.h>
#endif

#if defined(WIN32)
#define dllx extern "C" __declspec(dllexport)
#elif defined(GNUC)
#define dllx extern "C" __attribute__ ((visibility("default"))) 
#else
#define dllx extern "C"
#endif

#define trace(...) { printf("[" gm_extension_name ":%d] ", __LINE__); printf(__VA_ARGS__); printf("\n"); fflush(stdout); }

void show_error(const char* format, ...);

#include "gml_ext.h"
#include <fstream>
#include <string>

// TODO: reference additional headers your program requires here