#include "pp.h"
#include "token.h"

struct Stack
{
	__global struct Token *bottom; //!< The bottom of this stack.
	__global struct Token *top;    //!< The top of this stack.
	__global struct Token *max;    //!< The maximum top of this stack.
};

/*!
 * \brief Pops an int off \p stack.
 */
int pop_int(struct Stack *stack)
{
	// TODO: Assert that top >= bottom.
	// TODO: Assert that top->type == TYPE_INT.
	return (--stack->top)->data.INT;
}

/*!
 * \brief Pushes an int onto \p stack.
 */
void push_int(struct Stack *stack, int value)
{
	// TODO: Assert that top < max.
	*stack->top++ = (struct Token) { TYPE_INT, { .INT = value } };
}

/*!
 * \brief Executes an int token.
 * \detail Pushes the int onto \p stack.
 */
void exec_INT(__global const struct Token *token, struct Stack *stack)
{
	push_int(stack, token->data.INT);
}

#define OPERATOR(name, value, func) void exec_ ## name (struct Stack *stack) UNBOX func
#include "operators.def"

/*!
 * \brief Executes an operator token.
 */
void exec_OP(__global const struct Token *token, struct Stack *stack)
{
	switch (token->data.op) {
	#define OPERATOR(name, value, func) case OP_ ## name: exec_ ## name (stack); break;
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
	#define TYPE(name, value, repr) case TYPE_ ## name: exec_ ## name (token, stack); break;
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
__kernel void exec_range(__global const struct Token *in, unsigned int in_n, __global const struct Token *out, unsigned int out_n)
{
	struct Stack stack = { out, out, out + out_n };
	for (__global const struct Token *in_p = in; in_p < in + in_n; in_p++)
		exec(in_p, &stack);

	for (__global struct Token *stack_p = stack.top; stack_p < stack.max; ++stack_p)
		*stack_p = (struct Token) { -1, { .value = -1 } };
}
