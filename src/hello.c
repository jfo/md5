#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <OpenCL/opencl.h>

#define MEM_SIZE (128)
#define MAX_SOURCE_SIZE (0x100000)

#define bitswap(NUM) ((NUM>>24)&0xff) | ((NUM<<8)&0xff0000) | ((NUM>>8)&0xff00) | ((NUM<<24)&0xff000000)

unsigned long constants[64] =
{ 0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
 0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
 0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
 0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391 };

unsigned long rotate_amounts[64] =
{ 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 };

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

    cl_mem outputmem = NULL;
    outputmem = clCreateBuffer(context, CL_MEM_READ_WRITE, MEM_SIZE * sizeof(int), NULL, &ret);
    ret = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&outputmem);

    cl_mem constantsmem = NULL;
    constantsmem = clCreateBuffer(context, CL_MEM_READ_ONLY, 64 * sizeof(long), NULL, &ret);
    ret = clEnqueueWriteBuffer(command_queue, constantsmem, CL_TRUE, 0,
            64 * sizeof(long), constants, 0, NULL, NULL);
    ret = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&constantsmem);

    cl_mem rotatemem = NULL;
    rotatemem = clCreateBuffer(context, CL_MEM_READ_ONLY, 64 * sizeof(long), NULL, &ret);
    ret = clEnqueueWriteBuffer(command_queue, rotatemem, CL_TRUE, 0,
            64 * sizeof(long), rotate_amounts, 0, NULL, NULL);
    ret = clSetKernelArg(kernel, 2, sizeof(cl_mem), (void *)&rotatemem);

    cl_mem indexmem = NULL;
    indexmem = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(int), NULL, &ret);
    ret = clSetKernelArg(kernel, 3, sizeof(cl_mem), (void *)&indexmem);

    /* Execute OpenCL Kernel */
    size_t gws[2] = { 10 };
    size_t lws[2] = { 1 };
    ret = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, gws, lws, 0, NULL,NULL);

    /* Copy results from the memory buffer */
    long outputbuffer[MEM_SIZE];
    ret = clEnqueueReadBuffer(command_queue, outputmem, CL_TRUE, 0,
            MEM_SIZE * sizeof(int), outputbuffer, 0, NULL, NULL);

    /* Display Result */
    /* printf("%08lx%08lx%08lx%08lx", */
    /*         bitswap(outputbuffer[0]), */
    /*         bitswap(outputbuffer[1]), */
    /*         bitswap(outputbuffer[2]), */
    /*         bitswap(outputbuffer[3]) */
    /*       ); */


    for(int i = 0; i < 10; i++)
        printf("%lu\n", outputbuffer[i]);

    /* printf("%i\n", ret); */


    /* Finalization */
    ret = clFlush(command_queue);
    ret = clFinish(command_queue);
    ret = clReleaseKernel(kernel);
    ret = clReleaseProgram(program);
    ret = clReleaseMemObject(outputmem);
    ret = clReleaseCommandQueue(command_queue);
    ret = clReleaseContext(context);

    free(source_str);

    return 0;
}
