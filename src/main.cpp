#include <iostream>
#include "gml.hpp"

int main()
{
	Token in[] = {
		{ TYPE_FLOAT, { .FLOAT = 1 } },
		{ TYPE_FLOAT, { .FLOAT = 2 } },
		{ TYPE_OP,  { .OP = OP_SUB } },
	};

	try {
		auto stack = exec(in, in + sizeof in / sizeof in[0]);
		
		while (!stack.empty()) {
			auto e = stack.top();
			std::cout << "[" << e.type << "] " << e.data.FLOAT << std::endl;
			stack.pop();
		}
	} catch(cl::Error error) {
		std::cout << error.what() << "(" << error.err() << ")" << std::endl;
	}

	return 0;
}
