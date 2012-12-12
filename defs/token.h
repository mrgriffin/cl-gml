#ifndef TOKEN_H
#define TOKEN_H

enum Type
{
	#define TYPE(name, value, repr) TYPE_ ## name = value,
	#include "types.def"
};

enum Operator
{
	#define OPERATOR(name, value, funcs) OP_ ## name = value,
	#include "operators.def"
};

struct Token
{
	enum Type type;
	union
	{
		#define TYPE(name, value, repr) repr name;
		#include "types.def"
	} data;
};

#endif
