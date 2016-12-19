#define bitswap(NUM) ((NUM>>24)&0xff) | ((NUM<<8)&0xff0000) | ((NUM>>8)&0xff00) | ((NUM<<24)&0xff000000)

const unsigned long constants[64] =
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

const unsigned long rotate_amounts[64] =
{ 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 };

struct Message {
    unsigned char* start;
    unsigned long size;
};

void print_bytes(struct Message *input) {
    for (int i = 0; i < input->size; i++){
        printf("%i ", input->start[i]);
    }
}

struct Message* md5padding(char* msg) {
    unsigned long orig_length_in_bytes = strlen(msg);
    unsigned long orig_length_in_bits = (orig_length_in_bytes * 8) & 0xffffffffffffffff;

    unsigned long padded_length = orig_length_in_bytes;

    padded_length += 4;
    while (padded_length % 64 != 0) {
        padded_length += 1;
    }

    unsigned char *output_buffer = malloc(padded_length + 1);
    memcpy(output_buffer, msg, orig_length_in_bytes);

    int i;
    output_buffer[orig_length_in_bytes] = 0x80;
    for (i = orig_length_in_bytes + 1; i % 64 != 56; i++) {
        output_buffer[i] = 0x0;
    }

// TODO: proper bit shifting here instead of this garbage <<<
// it won't work for anything longer than 32 bytes until this is fixed
    output_buffer[i] = orig_length_in_bits;
    for (++i; i % 64 != 0; i++) {
        output_buffer[i] = 0;
    }
// TODO: proper bit shifting here instead of this garbage ^^^

    struct Message* output_msg = malloc(sizeof(struct Message));
    output_msg->start = output_buffer;
    output_msg->size = padded_length;
    return output_msg;
}

unsigned long left_rotate(unsigned long x, int amount) {
    x = x & 0xffffffff;
    return ((x << amount) | (x >> (32 - amount))) & 0xffffffff;
}

char *md5(char* msg) {
    struct Message* padded_msg = md5padding(msg);

    unsigned long acc[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };

    for (int chunk_index = 0; chunk_index < padded_msg->size / 64; chunk_index += 64) {
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
               (padded_msg->start[g*4 + 0]       |
                padded_msg->start[g*4 + 1] << 8  |
                padded_msg->start[g*4 + 2] << 16 |
                padded_msg->start[g*4 + 3] << 24);

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
    free(padded_msg->start);
    free(padded_msg);

    char *outstr = malloc(128);

    sprintf(outstr, "%08lx%08lx%08lx%08lx",
            bitswap(acc[0]),
            bitswap(acc[1]),
            bitswap(acc[2]),
            bitswap(acc[3])
          );
    return outstr;
}

int main() {
    char *door = "abbhdwsy";
    char *buf = malloc(1048);
    char *this;
    for (int i = 0; i < 7777890; i++) {
        sprintf(buf, "%s%i", door, i);
        this = md5(buf);
        if (strncmp(this, "00000", 5) == 0) {
            puts(this);
        }
    }
    return 0;
}

__kernel void hello(__global char* string)
{
string[0] = 'H';
string[1] = 'e';
string[2] = 'l';
string[3] = 'l';
string[4] = 'o';
string[5] = ',';
string[6] = ' ';
string[7] = 'W';
string[8] = 'o';
string[9] = 'r';
string[10] = 'l';
string[11] = 'd';
string[12] = '!';
}
