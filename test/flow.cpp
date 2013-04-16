#define BOOST_TEST_DYN_LINK
#define BOOST_TEST_MODULE GML_FLOW
#include <boost/test/unit_test.hpp>
#include "check_stack.hpp"
#include "gml.hpp"

BOOST_AUTO_TEST_CASE(IF_TRUE)
{
	checkStack(exec({ { TYPE_INT, { .INT = 1 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_BEGIN } }, { TYPE_INT, { .INT = 2 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_END } }, { TYPE_OP, { .OP = OP_IF } } }),
	                { { TYPE_INT, { .INT = 2 } } });
}

BOOST_AUTO_TEST_CASE(IF_FALSE)
{
	checkStack(exec({ { TYPE_INT, { .INT = 1 } }, { TYPE_INT, { .INT = 0 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_BEGIN } }, { TYPE_INT, { .INT = 2 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_END } }, { TYPE_OP, { .OP = OP_IF } } }),
	                { { TYPE_INT, { .INT = 1 } } });
}

BOOST_AUTO_TEST_CASE(IFELSE_TRUE)
{
	checkStack(exec({ { TYPE_INT, { .INT = 1 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_BEGIN } }, { TYPE_INT, { .INT = 0 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_END } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_BEGIN } }, { TYPE_INT, { .INT = 1 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_END } }, { TYPE_OP, { .OP = OP_IFELSE } } }),
	                { { TYPE_INT, { .INT = 0 } } });
}

BOOST_AUTO_TEST_CASE(IFELSE_FALSE)
{
	checkStack(exec({ { TYPE_INT, { .INT = 0 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_BEGIN } }, { TYPE_INT, { .INT = 0 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_END } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_BEGIN } }, { TYPE_INT, { .INT = 1 } }, { TYPE_MARKER, { .MARKER = MARKER_BLOCK_END } }, { TYPE_OP, { .OP = OP_IFELSE } } }),
	                { { TYPE_INT, { .INT = 1 } } });
}
