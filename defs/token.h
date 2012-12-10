#ifndef TOKEN_H
#define TOKEN_H

enum Type
{
	#define TYPE(name, value) TYPE_ ## name = value,
	#include "types.def"
};

enum Operator
{
	#define OPERATOR(name, value, func) OP_ ## name = value,
	#include "operators.def"
};

struct Token
{
	enum Type type;
	union
	{
		int value;
		enum Operator op;
	} data;
};

#endif
