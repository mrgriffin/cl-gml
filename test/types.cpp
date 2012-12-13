#define BOOST_TEST_DYN_LINK
#define BOOST_TEST_MODULE GML_TYPES
#include <boost/test/unit_test.hpp>
#include "check_stack.hpp"
#include "gml.hpp"

BOOST_AUTO_TEST_CASE(INT)
{
	auto out = exec({ { TYPE_INT, { .INT = 0 } } });
	checkStack(out, { { TYPE_INT, { .INT = 0 } } });
}
