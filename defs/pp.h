#ifndef PP_H
#define PP_H

#define UNBOX(x) x

#define FE_1(what, x) what(x)
#define FE_2(what, x, ...) what(x)FE_1(what, __VA_ARGS__)
#define FE_3(what, x, ...) what(x)FE_2(what, __VA_ARGS__)
#define FE_4(what, x, ...) what(x)FE_3(what, __VA_ARGS__)
#define FE_5(what, x, ...) what(x)FE_4(what, __VA_ARGS__)
#define FE_6(what, x, ...) what(x)FE_5(what, __VA_ARGS__)
#define FE_7(what, x, ...) what(x)FE_6(what, __VA_ARGS__)
#define FE_8(what, x, ...) what(x)FE_7(what, __VA_ARGS__)

#define GET_MACRO(_1, _2, _3, _4, _5, _6, _7, _8, name, ...) name

#define FOR_EACH(what, ...) GET_MACRO(__VA_ARGS__, FE_8, FE_7, FE_6, FE_5, FE_4, FE_3, FE_2, FE_1)(what, __VA_ARGS__)

#endif
