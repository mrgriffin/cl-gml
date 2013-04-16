#ifndef CHECK_STACK_HPP
#define CHECK_STACK_HPP

#include <initializer_list>
#include <stack>
#include "token.h"

void checkStack(std::stack<Token> const& actual, std::stack<Token> const& expected);
void checkStack(std::stack<Token> const& actual, std::initializer_list<Token> expected);

#endif
