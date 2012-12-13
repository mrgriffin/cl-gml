#ifndef TOKEN_H
#define TOKEN_H

enum Type
{
	#define TYPE(name, repr) TYPE_ ## name,
	#include "types.def"
};

enum Operator
{
	#define OPERATOR(name, funcs) OP_ ## name,
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
