/*!
 * \file gml.cl
 * \brief GML interpreter.
 */

#include "pp.h"
#include "token.h"

/*!
 * \def TYPE(name, representation)
 * \brief Defines the token type \p name to be a value of type \p representation.
 */

/*!
 * \def OPERATOR(name, token, overloads)
 * \brief Defines the operator \p name (recognized by the parser as \p token).
 * \detail \p overloads is a parenthesis-enclosed comma-separated list of functions of the form:
 * ~~~{.c}
 *    (((TYPE_NAME_1, TYPE_REPR_1 name_1), ..., (TYPE_NAME_N, TYPE_REPR_N name_N)), (
 *        // Operator code...
 *    ))
 * ~~~
 * \warning limitations in \c pp.h limit the number of overloads and parameters to overloads to 8.
 * \sa pp.h
 */

/*!
 * \brief Token stack used by ::exec for evaluating operators.
 * \sa pop
 * \sa push
 */
struct Stack
{
	__global struct Token *bottom; //!< The bottom of this stack.
	__global struct Token *top;    //!< The top of this stack.
	__global struct Token *max;    //!< The maximum top of this stack.
};

// TODO: Change the heap to a region of chars to conform with ANSI C.

/*!
 * \brief Block of memory on a Heap that can be allocated by ::malloc.
 * \memberof Heap
 */
struct HeapBin
{
	__global struct Token *begin; //!< The first address in this bin.
	__global struct Token *end;   //!< One past the last address in this bin.
	bool free;                    //!< Whether this bin is allocated.
};

/*!
 * \brief The maximum number of simultaneous allocations.
 * \relates Heap
 */
#define MAX_BINS 16

/*!
 * \brief Token heap used by ::exec for dynamic allocations.
 * \sa make_heap
 */
struct Heap
{
	__global struct Token *begin;  //!< The first address in this heap.
	__global struct Token *end;    //!< One past the last address in this heap.
	struct HeapBin bins[MAX_BINS]; //!< The bins in this heap.
};

/*!
 * \brief Initializes \p heap to allocate memory in the range \p begin .. \p end.
 * \memberof Heap
 */
void make_heap(struct Heap *heap, __global struct Token *begin, __global struct Token *end)
{
	heap->begin = begin;
	heap->end = end;
	size_t binSize = (end - begin) / MAX_BINS;
	for (size_t i = 0; i < MAX_BINS; ++i)
		heap->bins[i] = (struct HeapBin) { begin + binSize * i, begin + binSize * (i + 1), true };
}

/*!
 * \brief Allocates a block of \p n `Token`s.
 * \return A pointer to the first Token in the block; or \c 0 if the allocation failed.
 * \warning does not merge bins so allocations bigger than `(heap->end - heap->begin) / MAX_BINS` will fail.
 * \warning does not split bins so more than \c MAX_BINS simultaneous allocations will fail.
 * \warning differs from ANSI C's \c malloc in that \p n is a count of `Token`s not `char`s.
 * \memberof Heap
 * \sa realloc
 * \sa free
 */
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

/*!
 * \brief Reallocates the block at \p ptr to hold \p n `Token`s.
 * \return A pointer to the first Token in the block; or \c 0 if the allocation failed.
 * \warning does not merge bins so allocations bigger than `(heap->end - heap->begin) / MAX_BINS` will fail.
 * \warning does not split bins so more than \c MAX_BINS simultaneous allocations will fail.
 * \warning differs from ANSI C's \c malloc in that \p n is a count of `Token`s not `char`s.
 * \warning differs from ANSI C's \c realloc in that \p ptr will be freed if the allocation fails.
 * \memberof Heap
 * \sa malloc
 * \sa free
 */
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

/*!
 * \brief Frees the block at \p ptr.
 * \memberof Heap
 * \sa realloc
 * \sa free
 */
void free(struct Heap *heap, __global struct Token *ptr)
{
	for (size_t i = 0; i < MAX_BINS; ++i)
		if (!heap->bins[i].free && heap->bins[i].begin == ptr)
			heap->bins[i].free = true;
}

/*!
 * \brief Pops a token from \p stack.
 * \return The popped token.
 * \warning will cause a stack underflow if \p stack is empty (`stack->top == stack->bottom`).
 * \memberof Stack
 */
struct Token pop(struct Stack *stack)
{
	return *--stack->top;
}

/*!
 * \brief Pops a token of type \c TOKEN from \p stack.
 * \return The popped token.
 * \warning will cause a stack underflow if \p stack is empty (`stack->top == stack->bottom`).
 * \sa pop
 * \sa pop_TYPE
 */
struct Token pop_TOKEN(struct Stack *stack)
{
	return pop(stack);
}

/*!
 * \brief Pushes \p token onto \p stack.
 * \warning will cause a stack overflow if \p stack is full (`stack->top == stack->max`).
 * \memberof Stack
 */
void push(struct Stack *stack, struct Token token)
{
	*stack->top++ = token;
}

/*!
 * \fn TYPE pop_TYPE(struct Stack *stack)
 * \brief Pops a token of type \c TYPE from \p stack.
 * \detail Expands from `TYPE(NAME, REPR)` to
 * ~~~{.c}
 *    REPR pop_NAME(struct Stack *stack)
 *    {
 *        return pop(stack)->data.NAME;
 *    }
 * ~~~
 * \return The internal value of the token (`token->data.TYPE`).
 * \warning will cause a stack underflow if \p stack is empty (`stack->top == stack->bottom`).
 * \relates TYPE
 * \sa pop
 * \sa pop_TOKEN
 * \sa push_TYPE
 */

/*!
 * \fn push_TYPE(struct Stack *stack, TYPE value)
 * \brief Pushes a value as a token of type \c TYPE to \p stack.
 * \detail Expands from `TYPE(NAME, REPR)` to
 * ~~~{.c}
 *    void push_NAME(struct Stack *stack, REPR value)
 *    {
 *        push(stack, (struct Token) { TYPE_NAME, { .NAME = value } });
 *    }
 * ~~~
 * \warning will cause a stack overflow if \p stack is full (`stack->top == stack->max`).
 * \relates TYPE
 * \sa push
 * \sa pop_TYPE
 */

#define TYPE(name, repr) \
repr pop_ ## name (struct Stack *stack) \
{ \
	return (--stack->top)->data.name; \
} \
\
void push_ ## name (struct Stack *stack, repr value) \
{ \
	*stack->top++ = (struct Token) { .type = TYPE_ ## name, { .name = value } }; \
}
#include "types.def"

/*!
 * \brief Checks if \p token is of type \c TOKEN.
 * \return \c true if \p token is of type \c TOKEN; \c false otherwise.
 * \sa is_TYPE
 */
bool is_TOKEN(__global struct Token *token)
{
	return true;
}

/*!
 * \fn bool is_TYPE(__global struct Token *token)
 * \brief Checks if \p token is of type \c TYPE.
 * \detail Expands from `TYPE(NAME, REPR)` to
 * ~~~{.c}
 *    bool is_NAME(__global struct Token *token)
 *    {
 *        return token->type == TYPE_NAME;
 *    }
 * ~~~
 * \relates TYPE
 * \sa is_TOKEN
 */

#define TYPE(name, repr) \
bool is_ ## name (__global struct Token *token) \
{ \
	return token->type == TYPE_ ## name; \
}
#include "types.def"

/*!
 * \brief Maximum number of stack frames in ::exec.
 * \relates exec
 */
#define STACK_FRAMES 16

/*!
 * \brief Begins a new subroutine that executes the tokens in the range \p begin .. \p end.
 * \detail The tokens will be executed until end is reached or an operator calls \c RETURN.
 * \warning will overflow the stack if \c STACK_FRAMES stack frames are currently active.
 * \relates OPERATOR
 * \sa RETURN
 */
#define GOSUB(begin, end) do { \
	if (sp < STACK_FRAMES) \
		stack_frames[++sp] = (struct StackFrame) { begin, end }; \
	else \
		; /* TODO: Throw a StackOverflowError. */ \
} while (0)

/*!
 * \brief Ends the execution of a subroutine.
 * \relates OPERATOR
 * \sa GOSUB
 */
#define RETURN do { \
	--sp; \
} while (0)

/*!
 * \brief Executes the tokens in the range \p begin .. \p end.
 * \param begin the first token to execute.
 * \param end one past the last token to execute.
 * \param stack the stack to use for operators.
 * \param heap the heap to use for allocations.7
 * \warning will crash if the tokens recurse \c STACK_FRAMES times.
 * \sa OPERATOR
 * \sa STACK_FRAMES
 */
void exec(__global const struct Token *begin, __global const struct Token *end, struct Stack *stack, struct Heap *heap)
{
	struct StackFrame {
		__global const struct Token *pc;
		__global const struct Token *end;
	} stack_frames[STACK_FRAMES] = { { begin, end }, 0 };

	int sp = 0;

	while (sp >= 0) {
		__global const struct Token *ci = stack_frames[sp].pc++;

		switch (ci->type) {
			case TYPE_OP:
				switch (ci->data.OP) {
					/*
					 * OPERATOR(ADD, "add", ((((INT, int a), (INT, int b)), (push_INT(stack, a - b);))))
					 *
					 * void exec_ADD(struct Stack *stack)
					 * {
					 * 	__global struct Token *_top;
					 * 	_top = stack->top;
					 * 	if (is_INT(--_top) && is_INT(--_top) && 1) {
					 * 		int b = pop_INT(stack);
					 * 		int a = pop_INT(stack);
					 * 		push_INT(stack, a + b);
					 * 		return;
					 * 	}
					 * }
					 */
					#define TYPE_EQ(x) CONCAT(is_, ARG1 x)(--_top) &&
					#define DECL_VAR(x) INVOKE_(ARG2, UNBOX x) = CONCAT(pop_, INVOKE_(ARG1, UNBOX x)) (stack);
					#define DECL_FN(x) \
					_top = stack->top; \
					/* TODO: Skip this overload if the stack contains too few elements to match. */ \
					if (INVOKE(FOR_EACH_, TYPE_EQ, INVOKE_U(REVERSE, INVOKE_(ARG1, UNBOX x))) 1) {\
						INVOKE(FOR_EACH_, DECL_VAR, INVOKE_U(REVERSE, INVOKE_(ARG1, UNBOX x))) \
						INVOKE_U(UNBOX, INVOKE_(ARG2, UNBOX x)) \
						break; \
					}
					#define OPERATOR(name, token, funcs) \
					case OP_ ## name: \
					{ \
						__global struct Token *_top; \
						FOR_EACH(DECL_FN, UNBOX funcs) \
						/* TODO: Throw an error if no overloads matched. */ \
						break; \
					}
					#include "operators.def"
					#undef TYPE_EQ
					#undef DECL_VAR
					#undef DECL_FN
				}
				break;
			case TYPE_MARKER:
				if (ci->data.MARKER == MARKER_BLOCK_BEGIN) {
					__global const struct Token *ni = ci + 1;
					int markers = 1;
					while (ni < stack_frames[sp].end) {
						// TODO: Move this up into the while condition.
						if (ni->type == TYPE_MARKER && ni->data.MARKER == MARKER_BLOCK_BEGIN)
							++markers;
						if (ni->type == TYPE_MARKER && ni->data.MARKER == MARKER_BLOCK_END && --markers == 0)
							break;
						++ni;
					}
					// WARNING: We must not alter the contents of blocks as they alias the input tokens.
					push(stack, (struct Token) { TYPE_BLOCK, { .BLOCK = (struct Array) { (__global struct Token *)(ci + 1), (__global struct Token *)(ni) } } });
					stack_frames[sp].pc = ni + 1;
				} else {
					push(stack, *ci);
				}
				break;
			default:
				push(stack, *ci);
				break;
		}

		while (sp >= 0 && stack_frames[sp].pc == stack_frames[sp].end)
			RETURN;
	}
}

#undef RETURN
#undef GOSUB

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

	exec(in, in + in_n, &stack, &heap_);

	// HACK: Change array pointers into indicies into the heap.
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
