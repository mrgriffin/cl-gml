#ifndef GML_HPP
#define GML_HPP

#include <cstddef>
#include <initializer_list>
#include <stack>
#define __CL_ENABLE_EXCEPTIONS
#include <CL/cl.hpp>
#include "token.h"

std::stack<Token> exec(Token const* begin, Token const *end, std::size_t maxStackSize = 1024);
std::stack<Token> exec(std::initializer_list<Token> tokens, std::size_t maxStackSize = 1024);

#endif
