#define BOOST_TEST_DYN_LINK
#define BOOST_TEST_MODULE GML_TYPES
#include <boost/test/unit_test.hpp>
#include "check_stack.hpp"
#include "gml.hpp"

BOOST_AUTO_TEST_CASE(INT)
{
	checkStack(exec({ { TYPE_INT, { .INT = 0 } } }),
	                { { TYPE_INT, { .INT = 0 } } });
}

BOOST_AUTO_TEST_CASE(FLOAT)
{
	checkStack(exec({ { TYPE_FLOAT, { .FLOAT = 1 } } }),
	                { { TYPE_FLOAT, { .FLOAT = 1 } } });
}
