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

__kernel void stack_interpret(__global const int *in, unsigned int in_n, __global int *out, unsigned int out_n)
{
	const int OP_INT = 0;
	const int OP_ADD = 1;
	const int OP_SUB = 2;

	int ip = 0;
	int op = 0;
	while (ip < in_n) {
		// TODO: Assert ip < in_n.
		int type = in[ip++];
		if (type == OP_INT) {
			push_int(out, out_n, &op, in[ip++]);
		} else if (type == OP_ADD) {
			int b = pop_int(out, out_n, &op);
			int a = pop_int(out, out_n, &op);
			push_int(out, out_n, &op, a + b);
		} else if (type == OP_SUB) {
			int b = pop_int(out, out_n, &op);
			int a = pop_int(out, out_n, &op);
			push_int(out, out_n, &op, a - b);
		} else {
			// TODO: Throw an exception.
		}
	}
}
