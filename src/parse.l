%{
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

#include "token.h"

const char *ops[] = {
	#define OPERATOR(name, token, funcs) token,
	#include "operators.def"
};
%}

%option noyywrap

%%

\%.*\n {}

\[ {
	struct Token token = { .type = TYPE_MARKER, { .MARKER = MARKER_ARRAY } };
	fwrite(&token, sizeof token, 1, stdout);
}

\{ {
	struct Token token = { .type = TYPE_MARKER, { .MARKER = MARKER_BLOCK_BEGIN } };
	fwrite(&token, sizeof token, 1, stdout);
}

\} {
	struct Token token = { .type = TYPE_MARKER, { .MARKER = MARKER_BLOCK_END } };
	fwrite(&token, sizeof token, 1, stdout);
}

-?[0-9]+\.[0-9]+ {
	struct Token token = { .type = TYPE_FLOAT };
	token.data.FLOAT = atof(yytext);
	fwrite(&token, sizeof token, 1, stdout);
}

-?[0-9]+ {
	struct Token token = { .type = TYPE_INT };
	token.data.INT = atoi(yytext);
	fwrite(&token, sizeof token, 1, stdout);
}

\(-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?\) {
	struct Token token = { .type = TYPE_VECTOR3 };
	sscanf(yytext, "(%f,%f,%f)", &token.data.VECTOR3.x, &token.data.VECTOR3.y, &token.data.VECTOR3.z);
	fwrite(&token, sizeof token, 1, stdout);
}

[^[:space:]]+ {
	bool defined = false;

	for (size_t i = 0; i < sizeof ops / sizeof ops[0]; ++i) {
		if (strcmp(yytext, ops[i]) == 0) {
			struct Token token = { .type = TYPE_OP };
			// HINT: We know i is correct because enums start at 0.
			token.data.OP = i;
			fwrite(&token, sizeof token, 1, stdout);
			defined = true;
		}
	}

	if (!defined)
		fprintf(stderr, "skipping undefined operator '%s'\n", yytext);
}

.|\n {}

%%

int main(int argc, char *argv[])
{
	yylex();
	return 0;
}
