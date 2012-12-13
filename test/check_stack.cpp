#include <boost/test/unit_test.hpp>
#include "check_stack.hpp"

void checkStack(std::stack<Token> const& actual, std::stack<Token> const& expected)
{
	auto expected_ = expected;
	auto actual_ = actual;
	auto i = actual.size();
	while (!expected_.empty() && !actual_.empty()) {
		BOOST_TEST_CHECKPOINT("checking element at position " << --i);
		BOOST_CHECK_EQUAL(expected_.top().type, actual_.top().type);
		switch (expected_.top().type) {
			#define TYPE(name, value, repr) case TYPE_ ## name: \
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
