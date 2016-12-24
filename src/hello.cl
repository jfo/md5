unsigned long left_rotate(unsigned long x, int amount) {
    x = x & 0xffffffff;
    return ((x << amount) | (x >> (32 - amount))) & 0xffffffff;
}

__kernel void hello(
        __global long* output,
        __global char* input,
        __global long* constants
) {

    const unsigned long rotate_amounts[64] =
    { 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
      5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
      4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
      6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 };

    unsigned long acc[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };

    unsigned char output_buffer[64];

    unsigned long orig_length_in_bytes;
    for (orig_length_in_bytes = 0; input[orig_length_in_bytes] != 0x0; ++orig_length_in_bytes);

    unsigned long orig_length_in_bits = (orig_length_in_bytes * 8) & 0xffffffffffffffff;

    unsigned long padded_length = orig_length_in_bytes;

    padded_length += 4;
    while (padded_length % 64 != 0) {
        padded_length += 1;
    }

    for (int i = 0; i <= orig_length_in_bytes; i++)
        output_buffer[i] = input[i];

    int i;
    output_buffer[orig_length_in_bytes] = 0x80;
    for (i = orig_length_in_bytes + 1; i % 64 != 56; i++) {
        output_buffer[i] = 0x0;
    }

// TODO: proper bit shifting here instead of this garbage <<<
    output_buffer[i] = orig_length_in_bits;
    for (++i; i % 64 != 0; i++) {
        output[i] = 0;
    }
// TODO: proper bit shifting here instead of this garbage ^^^

    for (int chunk_index = 0; chunk_index < 512 / 64; chunk_index += 64) {
        unsigned long a,b,c,d; a = acc[0]; b = acc[1]; c = acc[2]; d = acc[3];

        unsigned long f = 0;
        unsigned long g = 0;
        for (int i = 0; i < 64; i++) {
            if (i < 16) {
                f = (b & c) | (~b & d);
                g = i;
            } else if (i < 32) {
                f = (d & b) | (~d & c);
                g = (5 * i + 1) % 16;
            } else if (i < 48) {
                f = b ^ c ^ d;
                g = (3 * i + 5) % 16;
            } else if (i < 64) {
                f = c ^ (b | ~d);
                g = (7 * i) % 16;
            }
            unsigned long to_rotate = a + f + constants[i] +
               (output_buffer[g*4 + 0]       |
                output_buffer[g*4 + 1] << 8  |
                output_buffer[g*4 + 2] << 16 |
                output_buffer[g*4 + 3] << 24);

            unsigned long new_b = b + left_rotate(to_rotate, rotate_amounts[i]);
            a = d;
            d = c;
            c = b;
            b = new_b;
        }
        acc[0] += a;
        acc[0] &= 0xffffffff;
        acc[1] += b;
        acc[1] &= 0xffffffff;
        acc[2] += c;
        acc[2] &= 0xffffffff;
        acc[3] += d;
        acc[3] &= 0xffffffff;
    }

    for (int i=0; i < 4; i++)
        output[i] = acc[i];
}
