struct Stack
{
	__global int *bottom; //!< The bottom of this stack.
	__global int *top;    //!< The top of this stack.
	__global int *max;    //!< The maximum top of this stack.
};

/*!
 * \brief Pops an int off \p stack.
 */
int pop_int(struct Stack *stack)
{
	// TODO: Assert that top >= bottom.
	return *--stack->top;
}

/*!
 * \brief Pushes an int onto \p stack.
 */
void push_int(struct Stack *stack, int value)
{
	// TODO: Assert that top < max.
	*stack->top++ = value;
}

/*!
 * \brief Executes an int token.
 * \detail Pushes the int onto \p stack.
 */
__global const int *exec_int(__global const int *token, struct Stack *stack)
{
	int value = *(token + 1);

	push_int(stack, value);

	return token + 2;
}

/*!
 * \brief Executes the addition operator.
 * \detail Pops \c b and \c a from \p stack and pushes \c a + \c b to \p stack.
 */
__global const int *exec_add(struct Stack *stack)
{
	int b = pop_int(stack);
	int a = pop_int(stack);
	push_int(stack, a + b);
}

/*!
 * \brief Executes the subtraction operator.
 * \detail Pops \c b and \c a from \p stack and pushes \c a - \c b to \p stack.
 */
__global const int *exec_sub(struct Stack *stack)
{
	int b = pop_int(stack);
	int a = pop_int(stack);
	push_int(stack, a - b);
}

/*!
 * \brief Executes an operator token.
 */
__global const int *exec_op(__global const int *token, struct Stack *stack)
{
	enum {
		OP_ADD = 1,
		OP_SUB = 2,
	} op = *(token + 1);

	switch (op) {
	case OP_ADD: exec_add(stack); return token + 2;
	case OP_SUB: exec_sub(stack); return token + 2;
	default: return 0; // TODO: assert(false) if we reach here.
	}
}

/*!
 * \brief Executes the token at \p token.
 * \param token a pointer to the token to execute.
 * \param out a pointer to the stack.
 * \param out_n the maximum size of the stack.
 * \return a pointer to the token after the token at \p token.
 */
__global const int *exec(__global const int *token, struct Stack *stack)
{
	enum {
		TYPE_INT = 0,
		TYPE_OP = 1
	} type = *token;

	switch (type) {
	case TYPE_INT: return exec_int(token, stack); break;
	case TYPE_OP:  return exec_op(token, stack); break;
	default: return 0; // TODO: assert(false) if we reach here.
	}
}

/*!
 * \brief Executes the tokens in the range \p in .. \p in + \p in_n.
 * \param in a pointer to the tokens to execute.
 * \param in_n the length of the tokens.
 * \param out a pointer to the stack.
 * \param out_n the maximum size of the stack.
 */
__kernel void exec_range(__global const int *in, unsigned int in_n, __global int *out, unsigned int out_n)
{
	__global const int *in_p = in;
	while (in_p < in + in_n) {
		in_p = exec(in_p, &(struct Stack) { out, out, out + out_n });
	}
}
