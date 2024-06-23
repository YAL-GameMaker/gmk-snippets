/// @author YellowAfterlife

#include "stdafx.h"
#include <string>
#include <sstream>
#include <unordered_set>
#include <map>
#include <vector>
#include <queue>
#include <fstream>
#include "CharTools.h"

const char* rets(std::string& s) {
	static std::string _str{};
	_str = s;
	return _str.c_str();
}

#define set_contains(set, thing) (set.find(thing) != set.end())

static std::unordered_set<std::string> gml_keywords{
	"if", "then", "else", "begin", "end", "for", "while", "do", "until", "repeat",
	"switch", "case", "default", "break", "continue", "with", "exit", "return",
	"self", "other", "noone", "all", "global", "local",
	"mod", "div", "not", "and", "or", "xor",
};
static bool is_gml_keyword(std::string& s) {
	return set_contains(gml_keywords, s);
}

static std::unordered_set<std::string> gml_functions{};

class snippet_preproc_t {
public:
	std::stringstream out{};
	std::string out_name{};
	std::queue<std::string> names{};
	std::queue<std::string> codes{};
	/// (including the ones that were empty and weren't added to output)
	int found = 0;
	int pos = 0;
	int len = 0;
	int start = 0;
	const char* str = nullptr;
	snippet_preproc_t() {}

	void skipSpaces() {
		while (pos < len) {
			auto c = str[pos];
			if (CharTools::isSpace(c)) pos += 1; else break;
		}
	}
	void skipLine() {
		while (pos < len) {
			if (str[pos++] == '\n') break;
		}
	}
	std::string slice(int start, int end) {
		return std::string(str + start, end - start);
	}
	std::string readIdent(bool afterFirst = true) {
		auto identStart = pos;
		if (afterFirst) identStart -= 1;
		while (pos < len) {
			auto c = str[pos];
			if (CharTools::isIdent(c)) pos += 1; else break;
		}
		return std::string(str + identStart, pos - identStart);
	}
	void flush(int till) {
		if (till > start) out.write(str + start, till - start);
	}
	void flushPart(int till, bool last) {
		auto first = found == 0;
		found += 1;

		// #define right at the start?
		if (till == 0 && !last) return;

		flush(till);
		auto code = out.str();

		// if the snip is 100% spaces, we'd like it trimmed:
		int len = (int)code.length();
		int pos = 0;
		while (pos < len) {
			if (CharTools::isSpace(code[pos])) {
				pos += 1;
			} else break;
		}
		if (pos >= len) code = "";

		// and we don't want to add a spaces-only first section unless that's also the last section
		if (!first || last || !code.empty()) {
			names.push(out_name);
			codes.push(code);
		}
		out = std::stringstream();
	}
	int run(const char* first_name, const char* code, const char* splitter) {
		str = code;
		pos = 0;
		start = 0;
		found = 0;
		len = strlen(code);
		out = std::stringstream();
		out_name = first_name;
		while (!names.empty()) names.pop();
		while (!codes.empty()) codes.pop();

		bool is_script = std::string(splitter) == "define";
		
		while (pos < len) {
			auto c = str[pos++];
			if (CharTools::isSpace(c)) continue;

			switch (c) {
				case '/':
					switch (str[pos]) {
						case '/':
							skipLine();
							continue;
						case '*':
							while (pos < len) {
								c = str[pos];
								if (c == '/' && str[pos - 1] == '*') break;
								if (c == '#' && str[pos - 1] == '\n') {
									auto beforeWord = pos++;
									auto word = readIdent(false);
									if (word == splitter) {
										pos = beforeWord;
										break;
									}
								}
								pos += 1;
							}
							continue;
					}
					continue;
				case '"': case '\'':
					while (pos < len) {
						if (str[pos++] == c) break;
					}
					continue;
			}
			if (CharTools::isIdentStart(c)) {
				auto before_pos = pos - 1;
				auto word = readIdent();
				auto wlen = word.size();

				if (is_script && word == "return") { // `return X` -> `for ({}; true; exit) global.__snippet_result = X`
					flush(before_pos);
					out << "for ({}; true; exit) global.__snippet__result =";
					start = pos;
					continue;
				}

				if (word == "var" || word == "globalvar") { // `var i = 1` -> `var i; i = 1`
					skipSpaces();
					auto before_vname = pos;
					auto vname = readIdent(false);
					if (is_gml_keyword(vname)) { // `var var name`
						pos = before_vname;
						continue;
					}
					auto before_equ = pos;
					skipSpaces();
					if (str[pos] == '=' || str[pos] == ':' && str[pos + 1] == '=') {
						flush(before_pos);
						out << word << " " << vname << "; " << vname;
						start = before_equ;
					}
					continue;
				}

				if (is_script && word == "argument_count") {
					flush(before_pos);
					out << "global.__snippet__argument_count";
					start = pos;
					continue;
				}

				// `argument[#]` / `argument#` -> `global.__snippet__argument[#]`
				const auto argn = sizeof("argument") - 1;
				if (is_script && wlen >= argn && wlen <= argn + 2 && strncmp(word.c_str(), "argument", argn) == 0) do {
					int argi;
					if (wlen == argn) {
						argi = -1;
					} else {
						argi = word[argn] - '0';
						if (argi < 0 || argi > 9) break;
						if (wlen > argn + 1) {
							argi = word[argn + 1] - '0';
							if (argi < 0 || argi > 5) break;
							argi += 10;
						}
					}
					flush(before_pos);
					out << "global.__snippet__argument";
					if (argi >= 0) {
						out << "[" << std::to_string(argi) << "]";
					}
					start = pos;
					continue;
				} while (false);

				if (word == splitter && before_pos > 0 && str[before_pos - 1] == '#'
					&& (before_pos == 1 || str[before_pos - 2] == '\n')
				) { // #define
					skipSpaces();
					auto name_start = pos;
					while (pos < len) { // name spans till eol/space/`(`
						c = str[pos];
						if (c == '(') break;
						if (CharTools::isSpace(c)) break;
						pos += 1;
					}
					auto name = slice(name_start, pos);
					flushPart(before_pos - 1, false);
					out_name = name;
					skipLine();
					start = pos;
					continue;
				}

				if (!is_gml_keyword(word) && word != "snippet_call" && !set_contains(gml_functions, word)) { // `func(` -> 
					auto peek = pos;
					bool isCall = false;
					while (peek < len) {
						auto c1 = str[peek++];
						if (!CharTools::isSpace(c1)) {
							isCall = c1 == '(';
							break;
						}
					}
					if (isCall) {
						flush(before_pos);
						pos = peek;
						// it's okay! Trailing commas are allowed in argument lists in GML
						out << "snippet_call(\"" << word << "\",";
						start = pos;
					}
				}
			}
		}
		flushPart(pos, true);
		return names.size();
	}
} snippet_preproc;
/// #gmki
dllx double snippet_preproc_run(const char* name, const char* code, const char* splitter) {
	return snippet_preproc.run(name, code, splitter);
}
/// #gmki
dllx const char* snippet_preproc_pop_name() {
	static std::string s{};
	s = snippet_preproc.names.front();
	snippet_preproc.names.pop();
	return s.c_str();
}
/// #gmki
dllx const char* snippet_preproc_pop_code() {
	static std::string s{};
	s = snippet_preproc.codes.front();
	snippet_preproc.codes.pop();
	return s.c_str();
}
/// #gmki
dllx const char* snippet_preproc_concat_names() {
	static std::queue<std::string> tmp{};
	tmp = snippet_preproc.names;
	std::stringstream out{};
	auto sep = false;
	while (!tmp.empty()) {
		if (sep) out << "\n"; else sep = true;
		out << tmp.front();
		tmp.pop();
	}
	static std::string result{};
	result = out.str();
	return result.c_str();
}

bool snippet_def_parse_impl(const char* def) {
	int pos = 0;
	int len = strlen(def);

	// spaces at line start:
	while (pos < len) {
		if (CharTools::isSpace(def[pos])) pos += 1; else break;
	}

	// read name:
	int name_start = pos;
	if (!CharTools::isIdentStart(def[pos])) return false;
	while (pos < len) {
		if (CharTools::isIdent(def[pos])) pos += 1; else break;
	}
	auto name = std::string(def + name_start, pos - name_start);

	// more spaces?
	while (pos < len) {
		if (CharTools::isSpace(def[pos])) pos += 1; else break;
	}

	if (def[pos] == '(') { // a function!
		if (!set_contains(gml_functions, name)) gml_functions.insert(name);
		return true;
	}
	
	return false;
}

///
dllx double snippet_function_add(const char* name) {
	if (set_contains(gml_functions, name)) return -1;
	gml_functions.insert(name);
	return true;
}
///
dllx double snippet_function_remove(const char* name) {
	auto item = gml_functions.find(name);
	if (item == gml_functions.end()) return -1;
	gml_functions.erase(item);
	return 1;
}

///
dllx double snippet_parse_api_entry(const char* line) {
	return snippet_def_parse_impl(line);
}
///
dllx double snippet_parse_api_file(const char* path) {
	std::ifstream fs(path);
	std::string line{};
	int n = 0;
	while (std::getline(fs, line)) {
		if (snippet_def_parse_impl(line.c_str())) n += 1;
	}
	return n;
}

