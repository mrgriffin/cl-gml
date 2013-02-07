bin_PROGRAMS = cl-gml cl-parse
cl_gml_SOURCES = src/main.cpp src/gml.cpp
cl_parse_SOURCES = src/parse.l
AM_CPPFLAGS = -Idefs -Isrc
AM_CFLAGS = -std=c99
AM_CXXFLAGS = -std=c++11
LIBS += -lOpenCL

check_PROGRAMS = test-types test-math
TESTS = $(check_PROGRAMS)

test_types_SOURCES = test/types.cpp src/gml.cpp test/check_stack.cpp
test_types_LDFLAGS = -lboost_unit_test_framework

test_math_SOURCES = test/math.cpp src/gml.cpp test/check_stack.cpp
test_math_LDFLAGS = -lboost_unit_test_framework

EXTRA_DIST = defs/operators.def defs/pp.h defs/token.h defs/types.def kernel/gml.cl
