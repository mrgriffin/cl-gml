#include "pp.h"
#include "token.h"

struct Stack
{
	__global struct Token *bottom; //!< The bottom of this stack.
	__global struct Token *top;    //!< The top of this stack.
	__global struct Token *max;    //!< The maximum top of this stack.
};

#if 0

TYPE(INT, 0, int) =>

// TODO: Assert that top >= bottom.
// TODO: Assert that top->type == TYPE_ ## name.
int pop_INT(struct Stack *stack)
{
	return (--stack->top)->data.INT;
}

// TODO: Assert that top < max.
void push_INT(struct Stack *stack, int INT)
{
	*stack->top++ = (struct Token) { TYPE_INT, { .INT = INT } };
}

#endif

#define TYPE(name, repr) \
repr pop_ ## name (struct Stack *stack) \
{ \
	return (--stack->top)->data.name; \
} \
\
void push_ ## name (struct Stack *stack, repr name) \
{ \
	*stack->top++ = (struct Token) { TYPE_ ## name, { .name = name } }; \
}
#include "types.def"

#if 0

OPERATOR(ADD, 0, ((((INT, int a), (INT, int b)), (push_INT(stack, a - b);)))) =>

void exec_ADD(struct Stack *stack)
{
	__global struct Token *_top;
	_top = stack->top;
	// TODO: Assert that _top will never go below stack->bottom.
	if ((--_top)->type == TYPE_INT && (--_top)->type == TYPE_INT && 1) {
		int b = pop_INT(stack);
		int a = pop_INT(stack);
		push_INT(stack, a + b);
		return;
	}
	// TODO: Assert(false) if we reach here.
}

#endif

#define TYPE_EQ(x) (--_top)->type == CONCAT(TYPE_, ARG1 x) &&
#define DECL_VAR(x) INVOKE_(ARG2, UNBOX x) = CONCAT(pop_, INVOKE_(ARG1, UNBOX x)) (stack);
#define DECL_FN(x) \
_top = stack->top; \
if (INVOKE(FOR_EACH_, TYPE_EQ, INVOKE_U(REVERSE, INVOKE_(ARG1, UNBOX x))) 1) {\
	INVOKE(FOR_EACH_, DECL_VAR, INVOKE_U(REVERSE, INVOKE_(ARG1, UNBOX x))) \
	INVOKE_U(UNBOX, INVOKE_(ARG2, UNBOX x)) \
	/* HACK: Work around Clang bug by putting a break between the UNBOXed tuple and the return statement. */ return; \
}
#define OPERATOR(name, funcs) \
void exec_ ## name (struct Stack *stack) \
{ \
	__global struct Token *_top; \
	FOR_EACH(DECL_FN, UNBOX funcs) \
}
#include "operators.def"
#undef TYPE_EQ
#undef DECL_VAR
#undef DECL_FN

/*!
 * \brief Executes an int token.
 * \detail Pushes the int onto \p stack.
 */
void exec_INT(__global const struct Token *token, struct Stack *stack)
{
	push_INT(stack, token->data.INT);
}

/*!
 * \brief Executes an operator token.
 */
void exec_OP(__global const struct Token *token, struct Stack *stack)
{
	switch (token->data.OP) {
	#define OPERATOR(name, funcs) case OP_ ## name: exec_ ## name (stack); break;
	#include "operators.def"
	// TODO: assert(false) if we reach here.
	}
}

/*!
 * \brief Executes the token at \p token.
 * \param token a pointer to the token to execute.
 * \param out a pointer to the stack.
 * \param out_n the maximum size of the stack.
 * \return a pointer to the token after the token at \p token.
 */
void exec(__global const struct Token *token, struct Stack *stack)
{
	switch (token->type) {
	#define TYPE(name, repr) case TYPE_ ## name: exec_ ## name (token, stack); break;
	#include "types.def"
	// TODO: assert(false) if we reach here.
	}
}

/*!
 * \brief Executes the tokens in the range \p in .. \p in + \p in_n.
 * \param in a pointer to the tokens to execute.
 * \param in_n the length of the tokens.
 * \param out a pointer to the stack.
 * \param out_n the maximum size of the stack.
 */
__kernel void exec_range(__global const struct Token *in, unsigned in_n, __global struct Token *out, __global unsigned *out_n)
{
	struct Stack stack = { out, out, out + *out_n };
	for (__global const struct Token *in_p = in; in_p < in + in_n; in_p++)
		exec(in_p, &stack);

	*out_n = stack.top - stack.bottom;
}
