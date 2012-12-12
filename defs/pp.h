#ifndef PP_H
#define PP_H

#define CONCAT(x, y)   CONCAT_(x, y)
#define CONCAT_(x, y)  x ## y

#define INVOKE(what, ...) what(__VA_ARGS__)
#define INVOKE_(what, ...) what(__VA_ARGS__)
#define INVOKE_U(what, ...) what __VA_ARGS__

#define UNBOX(...) __VA_ARGS__

#define ARG1(x, ...) x
#define ARG2(x, ...) ARG1(__VA_ARGS__)
#define ARG3(x, ...) ARG2(__VA_ARGS__)
#define ARG4(x, ...) ARG3(__VA_ARGS__)
#define ARG5(x, ...) ARG4(__VA_ARGS__)
#define ARG6(x, ...) ARG5(__VA_ARGS__)
#define ARG7(x, ...) ARG6(__VA_ARGS__)
#define ARG8(x, ...) ARG7(__VA_ARGS__)
#define NARGS(...) GET_MACRO(__VA_ARGS__, 8, 7, 6, 5, 4, 3, 2, 1)

#define GET_MACRO(_1, _2, _3, _4, _5, _6, _7, _8, name, ...) name

#define FE_1(what, x) what(x)
#define FE_2(what, x, ...) what(x) FE_1(what, __VA_ARGS__)
#define FE_3(what, x, ...) what(x) FE_2(what, __VA_ARGS__)
#define FE_4(what, x, ...) what(x) FE_3(what, __VA_ARGS__)
#define FE_5(what, x, ...) what(x) FE_4(what, __VA_ARGS__)
#define FE_6(what, x, ...) what(x) FE_5(what, __VA_ARGS__)
#define FE_7(what, x, ...) what(x) FE_6(what, __VA_ARGS__)
#define FE_8(what, x, ...) what(x) FE_7(what, __VA_ARGS__)
#define FOR_EACH(what, ...) GET_MACRO(__VA_ARGS__, FE_8, FE_7, FE_6, FE_5, FE_4, FE_3, FE_2, FE_1)(what, __VA_ARGS__)

#define FE_1_(what, x) what(x)
#define FE_2_(what, x, ...) what(x) FE_1_(what, __VA_ARGS__)
#define FE_3_(what, x, ...) what(x) FE_2_(what, __VA_ARGS__)
#define FE_4_(what, x, ...) what(x) FE_3_(what, __VA_ARGS__)
#define FE_5_(what, x, ...) what(x) FE_4_(what, __VA_ARGS__)
#define FE_6_(what, x, ...) what(x) FE_5_(what, __VA_ARGS__)
#define FE_7_(what, x, ...) what(x) FE_6_(what, __VA_ARGS__)
#define FE_8_(what, x, ...) what(x) FE_7_(what, __VA_ARGS__)
#define FOR_EACH_(what, ...) GET_MACRO(__VA_ARGS__, FE_8_, FE_7_, FE_6_, FE_5_, FE_4_, FE_3_, FE_2_, FE_1_)(what, __VA_ARGS__)

#define REVERSE_1(x) x
#define REVERSE_2(x, ...) __VA_ARGS__, x
#define REVERSE_3(x, ...) REVERSE_2(__VA_ARGS__), x
#define REVERSE_4(x, ...) REVERSE_3(__VA_ARGS__), x
#define REVERSE_5(x, ...) REVERSE_4(__VA_ARGS__), x
#define REVERSE_6(x, ...) REVERSE_5(__VA_ARGS__), x
#define REVERSE_7(x, ...) REVERSE_6(__VA_ARGS__), x
#define REVERSE_8(x, ...) REVERSE_7(__VA_ARGS__), x
#define REVERSE(...) CONCAT(REVERSE_, NARGS(__VA_ARGS__))(__VA_ARGS__)

#endif
