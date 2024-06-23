#include "stdafx.h"
#include <sstream>
#include <queue>
#include "CharTools.h"

///
dllx const char* sniptools_file_get_contents(const char* path) {
	std::ifstream fs(path);
	std::ostringstream out{};
	out << fs.rdbuf();
	static std::string result{};
	result.assign(out.str());
	return result.c_str();
}
///
dllx const char* sniptools_string_trim(const char* str) {
	static std::string s;
	s = str;
	s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](int ch) {
		return !std::isspace(ch);
		}));
	s.erase(std::find_if(s.rbegin(), s.rend(), [](int ch) {
		return !std::isspace(ch);
		}).base(), s.end());
	return s.c_str();
}
///
dllx const char* sniptools_string_trim_start(const char* str) {
	static std::string s;
	s = str;
	s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](int ch) {
		return !std::isspace(ch);
		}));
	return s.c_str();
}
///
dllx const char* sniptools_string_trim_end(const char* str) {
	static std::string s;
	s = str;
	s.erase(std::find_if(s.rbegin(), s.rend(), [](int ch) {
		return !std::isspace(ch);
		}).base(), s.end());
	return s.c_str();
}
///
dllx double sniptools_string_is_ident(const char* str) {
	int n = strlen(str);
	if (n == 0 || !CharTools::isIdentStart(str[0])) return false;
	for (int i = 1; i < n; i++) {
		if (!CharTools::isIdent(str[i])) return false;
	}
	return true;
}

static std::queue<std::string> sniptools_string_split_parts{};
///
dllx double sniptools_string_split_start(const char* str, const char* sep) {
	static std::string tmp{};
	tmp = str;

	sniptools_string_split_parts = std::queue<std::string>();
	size_t pos = 0;
	size_t start = 0;
	while ((pos = tmp.find(sep, start)) != std::string::npos) {
		std::string part = tmp.substr(start, pos - start);
		sniptools_string_split_parts.push(part);
		start = pos + 1;
	}
	std::string part = tmp.substr(start);
	sniptools_string_split_parts.push(part);
	return sniptools_string_split_parts.size();
}
/// 
dllx const char* sniptools_string_split_next() {
	if (sniptools_string_split_parts.empty()) return "";
	static std::string result{};
	result = sniptools_string_split_parts.front();
	sniptools_string_split_parts.pop();
	return result.c_str();
}