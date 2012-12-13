#include <iostream>
#include "gml.hpp"

int main()
{
	Token in[] = {
		{ TYPE_INT, { .INT = 1 } },
		{ TYPE_INT, { .INT = 2 } },
		{ TYPE_OP,  { .OP = OP_ADD } },
		{ TYPE_INT, { .INT = 4 } },
		{ TYPE_INT, { .INT = 3 } },
		{ TYPE_OP,  { .OP = OP_ADD } },
		{ TYPE_OP,  { .OP = OP_ADD } },
		{ TYPE_INT, { .INT = 5 } },
		{ TYPE_OP,  { .OP = OP_SUB } },
	};

	try {
		auto stack = exec(in, in + sizeof in / sizeof in[0]);
		
		while (!stack.empty()) {
			auto e = stack.top();
			std::cout << "[" << e.type << "] " << e.data.INT << std::endl;
			stack.pop();
		}
	} catch(cl::Error error) {
		std::cout << error.what() << "(" << error.err() << ")" << std::endl;
	}

	return 0;
}
