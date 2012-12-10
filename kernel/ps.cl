int pop_int(__global const int *stack, unsigned int length, unsigned int *i)
{
	// TODO: Assert that i < length.
	return stack[--(*i)];
}

void push_int(__global int *stack, unsigned int length, unsigned int *i, int value)
{
	// TODO: Assert that i < length.
	stack[(*i)++] = value;
}

__global const int *exec_int(__global const int *token, __global int *out, unsigned int out_n, unsigned int *op)
{
	int value = *(token + 1);

	push_int(out, out_n, op, value);

	return token + 2;
}

__global const int *exec_add(__global int *out, unsigned int out_n, unsigned int *op)
{
	int b = pop_int(out, out_n, op);
	int a = pop_int(out, out_n, op);
	push_int(out, out_n, op, a + b);
}

__global const int *exec_sub(__global int *out, unsigned int out_n, unsigned int *op)
{
	int b = pop_int(out, out_n, op);
	int a = pop_int(out, out_n, op);
	push_int(out, out_n, op, a - b);
}

__global const int *exec_op(__global const int *token, __global int *out, unsigned int out_n, unsigned int *op)
{
	enum {
		OP_ADD = 1,
		OP_SUB = 2,
	} op_ = *(token + 1);

	switch (op_) {
	case OP_ADD: exec_add(out, out_n, op); return token + 2;
	case OP_SUB: exec_sub(out, out_n, op); return token + 2;
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
__global const int *exec(__global const int *token, __global int *out, unsigned int out_n, unsigned int *op)
{
	enum {
		TYPE_INT = 0,
		TYPE_OP = 1
	} type = *token;

	switch (type) {
	case TYPE_INT: return exec_int(token, out, out_n, op); break;
	case TYPE_OP:  return exec_op(token, out, out_n, op); break;
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
	unsigned int op = 0;
	while (in_p < in + in_n) {
		in_p = exec(in_p, out, out_n, &op);
	}
}
