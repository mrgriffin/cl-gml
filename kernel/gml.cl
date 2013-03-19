#include "pp.h"
#include "token.h"

struct Stack
{
	__global struct Token *bottom; //!< The bottom of this stack.
	__global struct Token *top;    //!< The top of this stack.
	__global struct Token *max;    //!< The maximum top of this stack.
};

// TODO: Change the heap to a region of chars.

struct HeapBin
{
	__global struct Token *begin; //!< The first address in this bin.
	__global struct Token *end;   //!< One past the last address in this bin.
	bool free;                    //!< Whether this bin is allocated.
};

#define MAX_BINS 16

struct Heap
{
	__global struct Token *begin;  //!< The first address in this heap.
	__global struct Token *end;    //!< One past the last address in this heap.
	struct HeapBin bins[MAX_BINS]; //!< The bins in this heap.
};

void make_heap(struct Heap *heap, __global struct Token *begin, __global struct Token *end)
{
	heap->begin = begin;
	heap->end = end;
	size_t binSize = (end - begin) / MAX_BINS;
	for (size_t i = 0; i < MAX_BINS; ++i)
		heap->bins[i] = (struct HeapBin) { begin + binSize * i, begin + binSize * (i + 1), true };
}

__global struct Token *malloc(struct Heap *heap, size_t n)
{
	for (size_t i = 0; i < MAX_BINS; ++i) {
		if (heap->bins[i].free && (heap->bins[i].end - heap->bins[i].begin) >= n) {
			heap->bins[i].free = false;
			return heap->bins[i].begin;
		}
	}

	return 0;
}

__global struct Token *realloc(struct Heap *heap, __global struct Token *ptr, size_t n)
{
	if (ptr == 0)
		return malloc(heap, n);

	// HINT: This assumes that all bins are the same size.
	// HINT: This does not merge bins.
	for (size_t i = 0; i < MAX_BINS; ++i) {
		if (!heap->bins[i].free && heap->bins[i].begin == ptr) {
			if (n >= (heap->bins[i].end - heap->bins[i].begin)) {
				// WARNING: realloc should not free if it fails to allocate.
				heap->bins[i].free = true;
				return 0;
			} else {
				return ptr;
			}
		}
	}
	return 0;
}

void free(struct Heap *heap, __global struct Token *ptr)
{
	for (size_t i = 0; i < MAX_BINS; ++i)
		if (!heap->bins[i].free && heap->bins[i].begin == ptr)
			heap->bins[i].free = true;
}

void push(struct Stack *stack, struct Token token)
{
	*stack->top++ = token;
}

struct Token pop(struct Stack *stack)
{
	return *--stack->top;
}

struct Token pop_TOKEN(struct Stack *stack)
{
	return pop(stack);
}

// TODO: Assert that stack has enough space.
void pop_n(struct Stack *stack, size_t n)
{
	stack->top -= n;
}

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
	*stack->top++ = (struct Token) { .type = TYPE_ ## name, { .name = name } }; \
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

bool is_TOKEN(__global struct Token *token)
{
	return true;
}

#define TYPE(name, repr) \
bool is_ ## name (__global struct Token *token) \
{ \
	return token->type == TYPE_ ## name; \
}
#include "types.def"

#define TYPE_EQ(x) CONCAT(is_, ARG1 x)(--_top) &&
#define DECL_VAR(x) INVOKE_(ARG2, UNBOX x) = CONCAT(pop_, INVOKE_(ARG1, UNBOX x)) (stack);
#define DECL_FN(x) \
_top = stack->top; \
if (INVOKE(FOR_EACH_, TYPE_EQ, INVOKE_U(REVERSE, INVOKE_(ARG1, UNBOX x))) 1) {\
	INVOKE(FOR_EACH_, DECL_VAR, INVOKE_U(REVERSE, INVOKE_(ARG1, UNBOX x))) \
	INVOKE_U(UNBOX, INVOKE_(ARG2, UNBOX x)) \
	return; \
}
#define OPERATOR(name, token, funcs) \
void exec_ ## name (struct Stack *stack, struct Heap *heap) \
{ \
	__global struct Token *_top; \
	FOR_EACH(DECL_FN, UNBOX funcs) \
	/* TODO: Throw an error if no overloads matched. */ \
	/* HACK: Work around nVidia bug where last generated overload will be skipped. */ return; \
}
#include "operators.def"
#undef TYPE_EQ
#undef DECL_VAR
#undef DECL_FN

/*!
 * \brief Executes an operator token.
 */
void exec_OP(__global const struct Token *token, struct Stack *stack, struct Heap *heap)
{
	switch (token->data.OP) {
	#define OPERATOR(name, token, funcs) case OP_ ## name: exec_ ## name (stack, heap); break;
	#include "operators.def"
	// TODO: assert(false) if we reach here.
	}
}

/*!
 * \brief Executes a block of operators.
 */
// TODO: Allow nested blocks (OpenCL does not allow recursion).
void exec_BLOCK(__global const struct Token *token, struct Stack *stack, struct Heap *heap)
{
	for (__global const struct Token *in_p = token->data.BLOCK.begin; in_p < token->data.BLOCK.end; ++in_p) {
		switch (in_p->type) {
			case TYPE_OP:    exec_OP(in_p, stack, heap); break;
			default:         push(stack, *in_p); break;
		}
	}
}

/*!
 * \brief Executes the token at \p token.
 * \param token a pointer to the token to execute.
 * \param out a pointer to the stack.
 * \param out_n the maximum size of the stack.
 * \return a pointer to the token after the token at \p token.
 */
void exec(__global const struct Token *token, struct Stack *stack, struct Heap *heap)
{
	switch (token->type) {
		case TYPE_OP:    exec_OP(token, stack, heap); break;
		case TYPE_BLOCK: exec_BLOCK(token, stack, heap); break;
		default:         push(stack, *token); break;
	}
}

/*!
 * \brief Executes the tokens in the range \p in .. \p in + \p in_n.
 * \param in a pointer to the tokens to execute.
 * \param in_n the length of the tokens.
 * \param out a pointer to the stack.
 * \param out_n the maximum size of the stack.
 */
__kernel void exec_range(__global const struct Token *in, unsigned in_n, __global struct Token *out, __global unsigned *out_n, __global struct Token *heap, unsigned heap_n)
{
	struct Stack stack = { out, out, out + *out_n };

	struct Heap heap_;
	make_heap(&heap_, heap, heap + heap_n);

	for (__global const struct Token *in_p = in; in_p < in + in_n; in_p++) {
		// WARNING: This can not handle nested blocks.
		if (in_p->type == TYPE_MARKER && in_p->data.MARKER == MARKER_BLOCK_BEGIN) {
			__global const struct Token *in_e = in_p + 1;
			while (in_e < in + in_n) {
				// TODO: Move this up into the while condition.
				if (in_e->type == TYPE_MARKER && in_e->data.MARKER == MARKER_BLOCK_END)
					break;
				in_e++;
			}
			// WARNING: We must not alter the contents of blocks as they alias the input tokens.
			push(&stack, (struct Token) { TYPE_BLOCK, { .BLOCK = (struct Array) { (__global struct Token *)(in_p + 1), (__global struct Token *)(in_e) } } });
			in_p = in_e;
		} else {
			exec(in_p, &stack, &heap_);
		}
	}

	// HACK: Change array pointers into indicies into the heap.
	// TODO: Instead pass back heap_.begin so that C++ can do the transformations.
	// HINT: Block pointers are not into the heap and therefore unchanged (and useless).
	for (__global struct Token *token = stack.bottom; token != stack.top; ++token) {
		if (token->type == TYPE_ARRAY) {
			token->data.ARRAY.begin = (__global struct Token *)(token->data.ARRAY.begin - heap);
			token->data.ARRAY.end = (__global struct Token *)(token->data.ARRAY.end - heap);
		} else if (token->type == TYPE_EDGE) {
			token->data.EDGE.mesh = (__global struct Token *)(token->data.EDGE.mesh - heap);
		} else if (token->type == TYPE_MESH) {
			token->data.MESH.vertices = (__global struct Token *)(token->data.MESH.vertices - heap);
			token->data.MESH.elements = (__global struct Token *)(token->data.MESH.elements - heap);
		}
	}

	for (__global struct Token *token = heap_.begin; token != heap_.end; ++token) {
		if (token->type == TYPE_ARRAY) {
			token->data.ARRAY.begin = (__global struct Token *)(token->data.ARRAY.begin - heap);
			token->data.ARRAY.end = (__global struct Token *)(token->data.ARRAY.end - heap);
		} else if (token->type == TYPE_EDGE) {
			token->data.EDGE.mesh = (__global struct Token *)(token->data.EDGE.mesh - heap);
		} else if (token->type == TYPE_MESH) {
			token->data.MESH.vertices = (__global struct Token *)(token->data.MESH.vertices - heap);
			token->data.MESH.elements = (__global struct Token *)(token->data.MESH.elements - heap);
		}
	}

	*out_n = stack.top - stack.bottom;
}
