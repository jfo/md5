#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <OpenCL/opencl.h>

#define MEM_SIZE (128)
#define MAX_SOURCE_SIZE (0x100000)

int main()
{
    /* Load the source code containing the kernel*/
    FILE *fp = fopen("./src/hello.cl", "r");
    if (!fp) {
        fprintf(stderr, "Failed to load kernel.\n");
        exit(1);
    }
    char *source_str = (char*)malloc(MAX_SOURCE_SIZE);
    size_t source_size = fread(source_str, 1, MAX_SOURCE_SIZE, fp);
    fclose(fp);

    /* Get Platform and Device Info */
    cl_platform_id platform_id = NULL;
    cl_device_id device_id = NULL;
    cl_uint ret_num_devices;
    cl_uint ret_num_platforms;
    cl_int ret;
    ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
    ret = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_DEFAULT, 1, &device_id, &ret_num_devices);

    /* Create OpenCL context */
    cl_context context = NULL;
    context = clCreateContext(NULL, 1, &device_id, NULL, NULL, &ret);

    /* Create Command Queue */
    cl_command_queue command_queue = NULL;
    command_queue = clCreateCommandQueue(context, device_id, 0, &ret);

    /* Create Kernel Program from the source */
    cl_program program = NULL;
    program = clCreateProgramWithSource(context, 1, (const char **)&source_str,
            (const size_t *)&source_size, &ret);

    /* Build Kernel Program */
    ret = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);


    /* Create OpenCL Kernel */
    cl_kernel kernel = NULL;
    kernel = clCreateKernel(program, "hello", &ret);

    cl_mem inputmem = NULL;
    inputmem = clCreateBuffer(context, CL_MEM_READ_WRITE, MEM_SIZE * sizeof(char), NULL, &ret);

    cl_mem outputmem = NULL;
    outputmem = clCreateBuffer(context, CL_MEM_READ_WRITE, MEM_SIZE * sizeof(char), NULL, &ret);

    char inputbuffer[MEM_SIZE];
    sprintf(inputbuffer, "abbhdwsy%i", 0);
    ret = clEnqueueWriteBuffer(command_queue, inputmem, CL_TRUE, 0,
            MEM_SIZE * sizeof(char), inputbuffer, 0, NULL, NULL);

    ret = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&outputmem);
    ret = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&inputmem);

    /* Execute OpenCL Kernel */
    ret = clEnqueueTask(command_queue, kernel, 0, NULL,NULL);

    /* Copy results from the memory buffer */
    char outputbuffer[MEM_SIZE];
    ret = clEnqueueReadBuffer(command_queue, outputmem, CL_TRUE, 0,
            MEM_SIZE * sizeof(char),outputbuffer, 0, NULL, NULL);

    /* Display Result */
    puts(outputbuffer);

    /* Finalization */
    ret = clFlush(command_queue);
    ret = clFinish(command_queue);
    ret = clReleaseKernel(kernel);
    ret = clReleaseProgram(program);
    ret = clReleaseMemObject(outputmem);
    ret = clReleaseMemObject(inputmem);
    ret = clReleaseCommandQueue(command_queue);
    ret = clReleaseContext(context);

    free(source_str);

    return 0;
}
