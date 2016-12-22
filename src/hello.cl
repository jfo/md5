
__kernel void hello(__global char* output, __global char* input, __private int x)
{
    output[0] = x;
    output[1] = 0x0;
}
