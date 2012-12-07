#define __CL_ENABLE_EXCEPTIONS
#include <CL/cl.hpp>
#include <utility>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

int main()
{
	int stackIn[] = { 1, 2 };

	try {
		// Get available platforms
		std::vector<cl::Platform> platforms;
		cl::Platform::get(&platforms);

		// Select the default platform and create a context using this platform and the GPU
		cl_context_properties cps[3] = {
			CL_CONTEXT_PLATFORM,
			(cl_context_properties)(platforms[0])(),
			0
		};
		cl::Context context(CL_DEVICE_TYPE_GPU, cps);

		// Get a list of devices on this platform
		std::vector<cl::Device> devices = context.getInfo<CL_CONTEXT_DEVICES>();

		// Create a command queue and use the first device
		cl::CommandQueue queue = cl::CommandQueue(context, devices[0]);

		// Read source file
		std::ifstream sourceFile("kernel//stack_adder.cl");
		std::string sourceCode(
			std::istreambuf_iterator<char>(sourceFile),
			(std::istreambuf_iterator<char>()));
		cl::Program::Sources source(1, std::make_pair(sourceCode.c_str(), sourceCode.length()+1));

		// Make program of the source code in the context
		cl::Program program = cl::Program(context, source);

		// Build program for these specific devices
		program.build(devices);

		// Make kernel
		cl::Kernel kernel(program, "stack_interpret");

		// Create memory buffers
		// TODO: How do we decide the size of the output stack?
		cl::Buffer bufferStackIn = cl::Buffer(context, CL_MEM_READ_ONLY, sizeof stackIn);
		cl::Buffer bufferStackOut = cl::Buffer(context, CL_MEM_WRITE_ONLY, sizeof stackIn);

		// Copy stackIn to the memory buffers
		queue.enqueueWriteBuffer(bufferStackIn, CL_TRUE, 0, sizeof stackIn, stackIn);

		// Set arguments to kernel
		kernel.setArg(0, bufferStackIn);
		kernel.setArg(1, bufferStackOut);

		// Run the kernel
		queue.enqueueTask(kernel);

		// Read buffer stackOut into a local list
		int stackOut;
		queue.enqueueReadBuffer(bufferStackOut, CL_TRUE, 0, sizeof stackOut, &stackOut);

		std::cout << stackIn[0] << " + " << stackIn[1] << " = " << stackOut << std::endl;
	} catch(cl::Error error) {
		std::cout << error.what() << "(" << error.err() << ")" << std::endl;
	}

	return 0;
}
