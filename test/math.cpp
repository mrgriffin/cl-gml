#define BOOST_TEST_DYN_LINK
#define BOOST_TEST_MODULE GML_MATH
#include <boost/test/unit_test.hpp>
#include "check_stack.hpp"
#include "gml.hpp"

BOOST_AUTO_TEST_CASE(ADD)
{
	checkStack(exec({ { TYPE_INT, { .INT = 1 } }, { TYPE_INT, { .INT = 2 } }, { TYPE_OP, { .OP = OP_ADD } } }),
	                { { TYPE_INT, { .INT = 3 } } });

	checkStack(exec({ { TYPE_FLOAT, { .FLOAT = 1 } }, { TYPE_FLOAT, { .FLOAT = 2 } }, { TYPE_OP, { .OP = OP_ADD } } }),
	                { { TYPE_FLOAT, { .FLOAT = 3 } } });

	checkStack(exec({ Token { TYPE_VECTOR3, { .VECTOR3 = { 1, 2, 3 } } }, Token { TYPE_VECTOR3, { .VECTOR3 = { 3, 4, 5 } } }, { TYPE_OP, { .OP = OP_ADD } } }),
	                { Token { TYPE_VECTOR3, { .VECTOR3 = { 4, 6, 8 } } } });
}

BOOST_AUTO_TEST_CASE(SUB)
{
	checkStack(exec({ { TYPE_INT, { .INT = 1 } }, { TYPE_INT, { .INT = 2 } }, { TYPE_OP, { .OP = OP_SUB } } }),
	                { { TYPE_INT, { .INT = -1 } } });

	checkStack(exec({ { TYPE_FLOAT, { .FLOAT = 1 } }, { TYPE_FLOAT, { .FLOAT = 2 } }, { TYPE_OP, { .OP = OP_SUB } } }),
	                { { TYPE_FLOAT, { .FLOAT = -1 } } });

	checkStack(exec({ Token { TYPE_VECTOR3, { .VECTOR3 = { 1, 2, 3 } } }, Token { TYPE_VECTOR3, { .VECTOR3 = { 3, 4, 5 } } }, { TYPE_OP, { .OP = OP_SUB } } }),
	                { Token { TYPE_VECTOR3, { .VECTOR3 = { -2, -2, -2 } } } });
}
