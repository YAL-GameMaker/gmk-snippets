#pragma once

namespace CharTools {
	inline bool isLineSpace(char c) {
		return c == ' ' || c == '\t';
	}
	inline bool isSpace(char c) {
		switch (c) {
			case ' ': case '\t': case '\r': case '\n': return true;
			default: return false;
		}
	}
	inline bool isIdentStart(char c) {
		return c == '_' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z';
	}
	inline bool isIdent(char c) {
		return c == '_' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9';
	}
}