#define bitswap(NUM) ((NUM>>24)&0xff) | ((NUM<<8)&0xff0000) | ((NUM>>8)&0xff00) | ((NUM<<24)&0xff000000)

unsigned long left_rotate(unsigned long x, int amount) {
    x = x & 0xffffffff;
    return ((x << amount) | (x >> (32 - amount))) & 0xffffffff;
}

__kernel void hello(
        __global long* constants,
        __global long* rotate_amounts
) {

    unsigned long acc[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };
    unsigned char output_buffer[64];

    char input[16] = "abbhdwsy";
    char med[16] = { 0 } ;
    int num = get_global_id(0);
    int in = 0;
    while (num != 0) {
        int rem = num % 10;
        med[in++] = (rem > 9)? (rem-10) + 'a' : rem + '0';
        num = num/10;
    }
    int thing = 8;
    while (in != 0) {
        in = in - 1;
        input[thing++] = med[in];
    }

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
    i++;
    for (; i % 64 != 0; i++) {
        output_buffer[i] = 0;
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
        acc[i] = bitswap(acc[i]);

    /* int idx = atom_inc(&index[0]); */
    /* output[idx] = get_global_id(0); */

    /* for (int i=0; i < 4; i++) */
    /*     output[i] = acc[i]; */

    if ((acc[0] | 0x00000fff) == 0x00000fff) {
        printf("%08lx%08lx%08lx%08lx\n",
                acc[0],
                acc[1],
                acc[2],
                acc[3]
              );
    }
}
