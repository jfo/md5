
__kernel void hello(__global char* output, __global char* input)
{
    for (int i = 0; i < 100; i++) {
        output[i] = input[i] + 1;
    }
}
