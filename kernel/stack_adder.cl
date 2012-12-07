__kernel void stack_interpret(__global const int *stack_in, unsigned int in_len, __global int *stack_out)
{
	const int OP_INT = 0;
	const int OP_ADD = 1;
	const int OP_SUB = 2;

	int ip = 0;
	int op = 0;
	while (ip < in_len) {
		int type = stack_in[ip++];
		if (type == OP_INT) {
			stack_out[op++] = stack_in[ip++];
		} else if (type == OP_ADD) {
			int b = stack_out[op - 1];
			int a = stack_out[op - 2];
			stack_out[op - 2] = a + b;
			op -= 1;
		} else if (type == OP_SUB) {
			int b = stack_out[op - 1];
			int a = stack_out[op - 2];
			stack_out[op - 2] = a - b;
			op -= 1;
		} else {
			// TODO: Throw an exception.
		}
	}
}
