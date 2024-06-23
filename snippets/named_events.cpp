#include "stdafx.h"
#include <unordered_map>
#include <fstream>
#include <string>

struct gml_event_pair {
	int type, number;
	gml_event_pair() : type(-1), number(-1) {}
	gml_event_pair(int _type, int _number) : type(_type), number(_number) {}
};
std::unordered_map<std::string, gml_event_pair> gml_named_events{
	{"properties", gml_event_pair(-1, 0)}
};

enum class gml_event_type_arg : int {
	index,
	object,
	key,
};
struct gml_event_type_pair {
	int type;
	gml_event_type_arg arg;
	gml_event_type_pair() : type(-1), arg(gml_event_type_arg::index) {}
	gml_event_type_pair(int _type) : type(_type), arg(gml_event_type_arg::index) {}
	gml_event_type_pair(int _type, gml_event_type_arg _number) : type(_type), arg(_number) {}
};
std::unordered_map<std::string, gml_event_type_pair> gml_named_event_types{
	{"create", gml_event_type_pair(0)},
	{"destroy", gml_event_type_pair(1)},
	{"alarm", gml_event_type_pair(2)},
	{"step", gml_event_type_pair(3)},
	{"collision", gml_event_type_pair(4, gml_event_type_arg::object)},
	{"keyboard", gml_event_type_pair(5, gml_event_type_arg::key)},
	{"mouse", gml_event_type_pair(6)},
	{"other", gml_event_type_pair(7)},
	{"draw", gml_event_type_pair(8)},
	{"keypress", gml_event_type_pair(9, gml_event_type_arg::key)},
	{"keyrelease", gml_event_type_pair(10, gml_event_type_arg::key)},
};

std::unordered_map<std::string, int> gml_keycodes_init() {
	std::unordered_map<std::string, int> map{
		{"vk_nokey", 0},
		{"vk_anykey", 1},
		{"vk_backspace", 8},
		{"vk_tab", 9},
		{"vk_return", 13},
		{"vk_enter", 13},
		{"vk_shift", 16},
		{"vk_control", 17},
		{"vk_alt", 18},
		{"vk_pause", 19},
		{"vk_escape", 27},
		{"vk_space", 32},
		{"vk_pageup", 33},
		{"vk_pagedown", 34},
		{"vk_end", 35},
		{"vk_home", 36},
		{"vk_left", 37},
		{"vk_up", 38},
		{"vk_right", 39},
		{"vk_down", 40},
		{"vk_printscreen", 44},
		{"vk_insert", 45},
		{"vk_delete", 46},
		{"vk_numpad0", 96},
		{"vk_numpad1", 97},
		{"vk_numpad2", 98},
		{"vk_numpad3", 99},
		{"vk_numpad4", 100},
		{"vk_numpad5", 101},
		{"vk_numpad6", 102},
		{"vk_numpad7", 103},
		{"vk_numpad8", 104},
		{"vk_numpad9", 105},
		{"vk_multiply", 106},
		{"vk_add", 107},
		{"vk_subtract", 109},
		{"vk_decimal", 110},
		{"vk_divide", 111},
		{"vk_lshift", 160},
		{"vk_rshift", 161},
		{"vk_lcontrol", 162},
		{"vk_rcontrol", 163},
		{"vk_lalt", 164},
		{"vk_ralt", 165},
	};
	for (int c = 'A'; c <= 'Z'; c++) map[std::string(1, c)] = c;
	for (int c = '0'; c <= '9'; c++) map[std::string(1, c)] = c;
	for (int i = 1; i <= 24; i++) {
		map["vk_f" + std::to_string(i)] = 111 + i;
	}
	return map;
}
std::unordered_map<std::string, int> gml_keycodes = gml_keycodes_init();

///
dllx double snippet_event_get_type(const char* name) {
	static std::string str{};
	str.assign(name);
	auto pos = str.find(':');
	if (pos != std::string::npos) {
		auto pair = gml_named_event_types.find(str.substr(0, pos));
		if (pair == gml_named_event_types.end()) return -1;
		return pair->second.type;
	} else {
		auto pair = gml_named_events.find(name);
		if (pair == gml_named_events.end()) return -1;
		return pair->second.type;
	}
}

static std::string snippet_event_object;
///
dllx double snippet_event_get_number(const char* name) {
	static std::string str{};
	str.assign(name);
	auto pos = str.find(':');
	if (pos != std::string::npos) {
		auto pair = gml_named_event_types.find(str.substr(0, pos));
		if (pair == gml_named_event_types.end()) return -1;
		switch (pair->second.arg) {
			case gml_event_type_arg::index: {
				int numb = 0;
				if (std::sscanf(str.c_str() + pos + 1, "%d", &numb)) {
					if (numb < 0) numb = -1;
					return numb;
				}
				return -1;
			};
			case gml_event_type_arg::object:
				snippet_event_object = str.substr(pos + 1);
				return -2;
			case gml_event_type_arg::key: {
				auto key = str.substr(pos + 1);
				auto kp = gml_keycodes.find(key);
				if (kp != gml_keycodes.end()) kp->second;

				int numb = 0;
				if (std::sscanf(key.c_str(), "%d", &numb)) {
					if (numb < 0) numb = -1;
					return numb;
				}

				return -1;
			};
			default: return -1;
		}
	} else {
		auto pair = gml_named_events.find(name);
		if (pair == gml_named_events.end()) return -1;
		return pair->second.number;
	}
}
///
dllx const char* snippet_event_get_number_object() {
	return snippet_event_object.c_str();
}

///
dllx double snippet_event_register(const char* name, double type, double number) {
	gml_event_pair pair{};
	pair.type = (int)type;
	pair.number = (int)number;
	gml_named_events[name] = pair;
	return 1;
}

///
dllx double snippet_event_register_type(const char* name, double type, double arg_type) {
	gml_event_type_pair pair{};
	pair.type = (int)type;
	pair.arg = (gml_event_type_arg)arg_type;
	gml_named_event_types[name] = pair;
	return 1;
}

///
dllx double snippet_parse_event_file(const char* path) {
	std::ifstream fs(path);
	std::string line{};
	char ename[33]{};
	int n = 0;
	while (std::getline(fs, line)) {
		if (line.length() == 0) continue;
		int type = 0, number = 0;
		if (std::sscanf(line.c_str(), "%d:%d %32s", &type, &number, ename) > 0) {
			snippet_event_register(ename, type, number);
			//std::string m = std::string("type: ") + std::to_string(type) + " n:" + std::to_string(number) + " s:" + ename;
			//MessageBoxA(0, m.c_str(), "", 0);
			n += 1;
		}
	}
	return n;
}
