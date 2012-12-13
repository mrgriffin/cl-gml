bin_PROGRAMS = cl-gml
cl_gml_SOURCES = src/main.cpp src/gml.cpp
AM_CPPFLAGS = -std=c++11 -Idefs -Isrc
LIBS += -lOpenCL

check_PROGRAMS = test-types
TESTS = $(check_PROGRAMS)

test_types_SOURCES = test/types.cpp src/gml.cpp test/check_stack.cpp
test_types_LDFLAGS = -lboost_unit_test_framework

EXTRA_DIST = defs/operators.def defs/pp.h defs/token.h defs/types.def kernel/gml.cl
