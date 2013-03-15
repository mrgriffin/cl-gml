#include <boost/test/unit_test.hpp>
#include <cassert>
#include <iomanip>
#include "check_stack.hpp"

std::ostream& operator<<(std::ostream& out, Array const& array)
{
	return out << "{ .begin = " << array.begin << ", .end = " << array.end << " }";
}

bool operator==(Array const& lhs, Array const& rhs)
{
	return lhs.begin == rhs.begin && lhs.end == rhs.end;
}

std::ostream& operator<<(std::ostream& out, Vector3 const& vector)
{
	return out << "(" << vector.x << ", " << vector.y << ", " << vector.z << ")";
}

bool operator==(Vector3 const& lhs, Vector3 const& rhs)
{
	return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

std::ostream& operator<<(std::ostream& out, Edge const& edge)
{
	// HINT: 4 is not enough
	return out << "E"
		   << std::setfill('0') << std::setw(4) << edge.mesh
		   << std::setfill('0') << std::setw(4) << edge.vertex
		   << std::setfill('0') << std::setw(4) << edge.element;
}

bool operator==(Edge const& lhs, Edge const& rhs)
{
	return lhs.mesh == rhs.mesh && lhs.vertex == rhs.vertex && lhs.element == rhs.element;
}

std::ostream& operator<<(std::ostream& out, Mesh const& mesh)
{
	assert(false);
}

bool operator==(Mesh const& lhs, Mesh const& rhs)
{
	assert(false);
}

void checkStack(std::stack<Token> const& actual, std::stack<Token> const& expected)
{
	auto expected_ = expected;
	auto actual_ = actual;
	auto i = actual.size();
	while (!expected_.empty() && !actual_.empty()) {
		BOOST_TEST_CHECKPOINT("checking element at position " << --i);
		BOOST_CHECK_EQUAL(expected_.top().type, actual_.top().type);
		switch (expected_.top().type) {
			#define TYPE(name, repr) case TYPE_ ## name: \
				BOOST_CHECK_EQUAL(expected_.top().data.name, actual_.top().data.name); \
				break;
			#include "types.def"
		}
		expected_.pop();
		actual_.pop();
	}
	BOOST_CHECK_EQUAL(expected.size(), actual.size());
}

void checkStack(std::stack<Token> const& actual, std::initializer_list<Token> expected)
{
	checkStack(actual, std::stack<Token>(std::deque<Token>(expected.begin(), expected.end())));
}
