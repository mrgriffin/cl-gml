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

BOOST_AUTO_TEST_CASE(ARRAY_EMPTY)
{
	checkStack(exec({ { TYPE_MARKER, { .MARKER = MARKER_ARRAY } }, { TYPE_OP, { .OP = OP_ARRAY } } }),
	                { { TYPE_ARRAY, { .ARRAY = { 0 } } } });
}

BOOST_AUTO_TEST_CASE(ARRAY_ONE)
{
	checkStack(exec({ { TYPE_MARKER, { .MARKER = MARKER_ARRAY } }, { TYPE_INT, { .INT = 1 } }, { TYPE_OP, { .OP = OP_ARRAY } } }),
	                { Token { TYPE_ARRAY, { .ARRAY = { 0, 1 } } } });
	// TODO: Do not address directly into the heap.
	BOOST_CHECK_EQUAL(heap[0].type, TYPE_INT);
	BOOST_CHECK_EQUAL(heap[0].data.INT, 1);
}
