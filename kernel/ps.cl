enum Type
{
	TYPE_INT = 0,
	TYPE_OP = 1,
};

enum Operator
{
	OP_ADD = 0,
	OP_SUB = 1,
};

struct Token
{
	enum Type type;
	union
	{
		int value;
		enum Operator operator;
	} data;
};

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
	return (--stack->top)->data.value;
}

/*!
 * \brief Pushes an int onto \p stack.
 */
void push_int(struct Stack *stack, int value)
{
	// TODO: Assert that top < max.
	*stack->top++ = (struct Token) { TYPE_INT, value };
}

/*!
 * \brief Executes an int token.
 * \detail Pushes the int onto \p stack.
 */
void exec_int(__global const struct Token *token, struct Stack *stack)
{
	push_int(stack, token->data.value);
}

/*!
 * \brief Executes the addition operator.
 * \detail Pops \c b and \c a from \p stack and pushes \c a + \c b to \p stack.
 */
void exec_add(struct Stack *stack)
{
	int b = pop_int(stack);
	int a = pop_int(stack);
	push_int(stack, a + b);
}

/*!
 * \brief Executes the subtraction operator.
 * \detail Pops \c b and \c a from \p stack and pushes \c a - \c b to \p stack.
 */
void exec_sub(struct Stack *stack)
{
	int b = pop_int(stack);
	int a = pop_int(stack);
	push_int(stack, a - b);
}

/*!
 * \brief Executes an operator token.
 */
void exec_op(__global const struct Token *token, struct Stack *stack)
{
	switch (token->data.operator) {
	case OP_ADD: exec_add(stack); break;
	case OP_SUB: exec_sub(stack); break;
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
	case TYPE_INT: exec_int(token, stack); break;
	case TYPE_OP:  exec_op(token, stack); break;
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
__kernel void exec_range(__global const struct Token *in, unsigned int in_n, __global int *out, unsigned int out_n)
{
	struct Stack stack = { out, out, out + out_n };
	for (__global const struct Token *in_p = in; in_p < in + in_n; in_p++)
		exec(in_p, &stack);
}
