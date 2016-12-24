__kernel void hello(__global long* output, __global char* input)
{
    unsigned long acc[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };
    for (int i=0; i < 4; i++)
        output[i] = acc[i];

}
