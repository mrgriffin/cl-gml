#include <cstdio>
#include <iomanip>
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
	case TYPE_VECTOR3:
		out << "(" << token.data.VECTOR3.x << ", " << token.data.VECTOR3.y << ", " << token.data.VECTOR3.z << ")";
		break;
	case TYPE_OP:
		out << ops[token.data.OP];
		break;
	case TYPE_MARKER:
		switch (token.data.MARKER) {
		case MARKER_ARRAY:       out << "["; break;
		case MARKER_BLOCK_BEGIN: out << "{"; break;
		case MARKER_BLOCK_END:   out << "}"; break;
		default:                 out << "[unknown]"; break;
		}
		break;
	case TYPE_ARRAY:
		out << "[ ";
		for (auto i = token.data.ARRAY.begin; i != token.data.ARRAY.end; ++i)
			out << heap[i] << " ";
		out << "]";
		break;
	case TYPE_BLOCK:
		out << "{ ... }";
		break;
	case TYPE_EDGE:
		out << "E"
		    << std::setfill('0') << std::setw(4) << token.data.EDGE.mesh
		    << std::setfill('0') << std::setw(4) << token.data.EDGE.vertex
		    << std::setfill('0') << std::setw(4) << token.data.EDGE.element;

		{
			Mesh* mesh = &heap[token.data.EDGE.mesh].data.MESH;
			Token* vertices = &heap[mesh->vertices];
			Token* elements = &heap[mesh->elements];
			for (auto i = 0; i < mesh->vertex_n; ++i) {
				Vector3 v = vertices[i].data.VECTOR3;
				std::cerr << "v " << v.x << " " << v.y << " " << v.z << std::endl;
			}
			for (auto i = 0; i < mesh->element_n; ++i) {
				Vector3 v0 = elements[i].data.VECTOR3;
				//std::cerr << "f " << int(e.x + 1) << " " << int(e.y + 1) << std::endl;
				for (auto j = i + 1; j < mesh->element_n; ++j) {
					Vector3 v1 = elements[j].data.VECTOR3;
					if (v0.y == v1.x) {
						for (auto k = i + 1; k < mesh->element_n; ++k) {
							Vector3 v2 = elements[k].data.VECTOR3;
							if (v2.y == v0.x && v2.x == v1.y)
								std::cerr << "f " << int(v0.x + 1) << " " << int(v0.y + 1) << " " << int(v1.y + 1) << std::endl;
						}
					} else if (v0.x == v1.y) {
						for (auto k = i + 1; k < mesh->element_n; ++k) {
							Vector3 v2 = elements[k].data.VECTOR3;
							if (v2.x == v0.x && v2.y == v1.y)
								std::cerr << "f " << int(v0.x + 1) << " " << int(v0.y + 1) << " " << int(v1.y + 1) << std::endl;
						}
					}
				}
			}
		}

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

		std::cout << "STACK:" << std::endl;

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
