#define __CL_ENABLE_EXCEPTIONS
#include <CL/cl.hpp>
#include <utility>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include "token.h"

int main()
{
	Token in[] = {
		{ TYPE_INT, { .INT = 1 } },
		{ TYPE_INT, { .INT = 2 } },
		{ TYPE_OP,  { .OP = OP_ADD } },
		{ TYPE_INT, { .INT = 4 } },
		{ TYPE_INT, { .INT = 3 } },
		{ TYPE_OP,  { .OP = OP_ADD } },
		{ TYPE_OP,  { .OP = OP_ADD } },
		{ TYPE_INT, { .INT = 5 } },
		//{ TYPE_OP,  { .OP = OP_SUB } },
	};

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
		std::ifstream sourceFile("kernel/ps.cl");
		std::string sourceCode(
			std::istreambuf_iterator<char>(sourceFile),
			(std::istreambuf_iterator<char>()));
		cl::Program::Sources source(1, std::make_pair(sourceCode.c_str(), sourceCode.length()+1));

		// Make program of the source code in the context
		cl::Program program = cl::Program(context, source);

		// Build program for these specific devices
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
			printf("BUILD LOG: \n %s", build_log);
		}, &devices);

		// Make kernel
		cl::Kernel kernel(program, "exec_range");

		// Create memory buffers
		// TODO: How do we decide the size of the output stack?
		cl::Buffer bufferIn = cl::Buffer(context, CL_MEM_READ_ONLY, sizeof in);
		cl::Buffer bufferOut = cl::Buffer(context, CL_MEM_WRITE_ONLY, sizeof in);

		// Copy stackIn to the memory buffers
		queue.enqueueWriteBuffer(bufferIn, CL_TRUE, 0, sizeof in, in);

		// Set arguments to kernel
		kernel.setArg(0, bufferIn);
		kernel.setArg(1, (unsigned int)(sizeof in / sizeof in[0]));
		kernel.setArg(2, bufferOut);
		kernel.setArg(3, (unsigned int)(sizeof in / sizeof in[0]));

		// Run the kernel
		queue.enqueueTask(kernel);

		// Read buffer stackOut into a local list
		Token out[sizeof in / sizeof in[0]];
		queue.enqueueReadBuffer(bufferOut, CL_TRUE, 0, sizeof out, out);

		for (std::size_t i = 0; i < sizeof out / sizeof out[0]; ++i)
			std::cout << "[" << out[i].type << "] " << out[i].data.INT << std::endl;
	} catch(cl::Error error) {
		std::cout << error.what() << "(" << error.err() << ")" << std::endl;
	}

	return 0;
}
