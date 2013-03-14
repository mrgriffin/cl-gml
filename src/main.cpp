#include <cstdio>
#include <iostream>
#include <vector>
#include "gml.hpp"

std::ostream& operator<<(std::ostream& out, Token const& token)
{
	static const char *types[] = {
		#define TYPE(name, repr) #name,
		#include "types.def"
	};

	static const char *ops[] = {
		#define OPERATOR(name, token, funcs) token,
		#include "operators.def"
	};

	switch (token.type) {
	case TYPE_INT:
		out << token.data.INT;
		break;
	case TYPE_FLOAT:
		out << token.data.FLOAT;
		break;
	case TYPE_OP:
		out << ops[token.data.OP];
		break;
	case TYPE_MARKER:
		out << "[";
		break;
	case TYPE_ARRAY:
		out << "[ ";
		for (auto i = token.data.ARRAY.begin; i != token.data.ARRAY.end; ++i)
			out << heap[i] << " ";
		out << "]";
		break;
	default:
		out << "[unknown]";
		break;
	}

	out << " : " << types[token.type];

	return out;
}

int main()
{
	std::vector<Token> tokens;
	Token token;
	while (std::fread(&token, sizeof token, 1, stdin) == 1)
		tokens.push_back(token);

	try {
		auto stack = exec(tokens.data(), tokens.data() + tokens.size());
		
		while (!stack.empty()) {
			auto e = stack.top();
			std::cout << e << std::endl;
			stack.pop();
		}
	} catch(cl::Error error) {
		std::cout << error.what() << "(" << error.err() << ")" << std::endl;
	}

	return 0;
}
