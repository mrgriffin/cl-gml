#ifndef TOKEN_H
#define TOKEN_H

enum Marker
{
	MARKER_ARRAY
};

#ifdef __OPENCL_VERSION__
	typedef __global struct Token *HeapPointer;
#else
	typedef int HeapPointer;
#endif

struct Array
{
	HeapPointer begin;
	HeapPointer end;
};

enum Type
{
	#define TYPE(name, repr) TYPE_ ## name,
	#include "types.def"
};

enum Operator
{
	#define OPERATOR(name, token, funcs) OP_ ## name,
	#include "operators.def"
};

struct Token
{
	enum Type type;
	union
	{
		#define TYPE(name, repr) repr name;
		#include "types.def"
	} data;
};

#endif
