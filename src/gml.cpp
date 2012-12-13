#include <cassert>
#include <deque>
#include <fstream>
#include <vector>
#include <utility>
#include <vector>
#include "gml.hpp"

std::stack<Token> exec(Token const* begin, Token const *end, std::size_t maxStackSize)
{
	// Get available platforms.
	std::vector<cl::Platform> platforms;
	cl::Platform::get(&platforms);

	// Select the default platform and create a context using this platform and the GPU.
	cl_context_properties cps[3] = {
		CL_CONTEXT_PLATFORM,
		(cl_context_properties)(platforms[0])(),
		0
	};
	cl::Context context(CL_DEVICE_TYPE_GPU, cps);

	// Get a list of devices on this platform.
	std::vector<cl::Device> devices = context.getInfo<CL_CONTEXT_DEVICES>();

	// Create a command queue and use the first device.
	cl::CommandQueue queue = cl::CommandQueue(context, devices[0]);

	// Read source file.
	std::ifstream sourceFile("kernel/gml.cl");
	std::string sourceCode(
		std::istreambuf_iterator<char>(sourceFile),
		(std::istreambuf_iterator<char>()));
	cl::Program::Sources source(1, std::make_pair(sourceCode.c_str(), sourceCode.length()+1));

	// Make program of the source code in the context.
	cl::Program program = cl::Program(context, source);

	// Build program for these specific devices.
	program.build(devices, "-Idefs", [] (cl_program program, void* data) {
		std::vector<cl::Device> const& devices = *(std::vector<cl::Device>*)data;
		cl_build_status build_status;
		clGetProgramBuildInfo(program, devices[0](), CL_PROGRAM_BUILD_STATUS, sizeof(cl_build_status), &build_status, NULL);

		char *build_log;
		size_t ret_val_size;
		clGetProgramBuildInfo(program, devices[0](), CL_PROGRAM_BUILD_LOG, 0, NULL, &ret_val_size);

		build_log = new char[ret_val_size+1];
		clGetProgramBuildInfo(program, devices[0](), CL_PROGRAM_BUILD_LOG, ret_val_size, build_log, NULL);
		build_log[ret_val_size] = '\0';
		// XXX: printf should not be used here.
		printf("BUILD LOG: \n %s", build_log);
	}, &devices);

	// Make kernel.
	cl::Kernel kernel(program, "exec_range");

	// Create memory buffers.
	cl::Buffer bufferIn = cl::Buffer(context, CL_MEM_READ_ONLY, (end - begin) * sizeof(Token));
	cl::Buffer bufferOut = cl::Buffer(context, CL_MEM_WRITE_ONLY, maxStackSize * sizeof(Token));
	cl::Buffer bufferOutN = cl::Buffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint));

	// Copy stackIn to the memory buffers.
	queue.enqueueWriteBuffer(bufferIn, CL_TRUE, 0, (end - begin) * sizeof(Token), begin);

	cl_uint stackSize = maxStackSize;
	queue.enqueueWriteBuffer(bufferOutN, CL_TRUE, 0, sizeof stackSize, &stackSize);

	// Set arguments to kernel.
	kernel.setArg(0, bufferIn);
	kernel.setArg(1, (unsigned)(end - begin));
	kernel.setArg(2, bufferOut);
	kernel.setArg(3, bufferOutN);

	// Run the kernel.
	queue.enqueueTask(kernel);

	// Read buffer stackOut into a local list.
	queue.enqueueReadBuffer(bufferOutN, CL_TRUE, 0, sizeof stackSize, &stackSize);
	auto stack = std::vector<Token>(stackSize);
	queue.enqueueReadBuffer(bufferOut, CL_TRUE, 0, stackSize * sizeof(Token), stack.data());
	return std::stack<Token>(std::deque<Token>(stack.begin(), stack.end()));
}

std::stack<Token> exec(std::initializer_list<Token> tokens, std::size_t maxStackSize)
{
	return exec(tokens.begin(), tokens.end(), maxStackSize);
}
