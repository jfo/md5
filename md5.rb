require 'digest'
@input = "This is my test string."
# @input = "The quick brown fox jumps over the lazy dog."
Digest::MD5.hexdigest(@input) # "d4108e090956a15e38e1b15151004086"

@input.bytesize * 8

@input.bytes.map {|b| "%08d" % b.to_s(2)}.join.length
@arr = @input.bytes
length = @arr.length
@arr << 0b10000000
@arr << 0b00000000 until @arr.length % 64  == 56

# loooool
@arr  << ("%064d" % (length * 8).to_s(2)).split('').each_slice(8).to_a.map {|e| e.join.to_i(2)}.reverse
@arr.flatten!

k = []
(0.. 63).each do |i|
    k[i] = (2**32 * Math.sin(i + 1).abs).floor
end

s = []
s[ 0..15] = [ 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22 ]
s[16..31] = [ 5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20 ]
s[32..47] = [ 4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23 ]
s[48..63] = [ 6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 ]

def bitize(input)
    input[0..3].reduce {|acc, e| acc << 32 | e}
end
def bitize_print(input)
   (input[0..3].reduce {|acc, e| acc << 32 | e} % 2 ** 128 ).to_s(16)
end

def leftrotate(x, c)
    ((x << c) | (x >> (32 - c))) & 0xffffffff 
end

# p "%032d" % [1,1,1,1].reduce {|acc, e| acc << 8 | e}.to_s(2)
# p  "%032d" % ((1 << 8) | 1).to_s(2)

table = [
    0x67452301,
    0xefcdab89,
    0x98badcfe,
    0x10325476
]

def F(x,y,z)    (x & y) | (~x & z) end
def G(x,y,z)    (x & z) | (y & ~z) end
def H(x,y,z)    x ^ y ^ z          end
def I(x,y,z)    y ^ (x | ~z)       end

a, b, c, d = table
(0...64).each do |i|
    if 0 <= i && i <= 15
        f = F(b,c,d)
        g = i
    elsif 16 <= i && i <= 31
        f = G(b,c,d)
        g = (5 * i + 1) % 16
    elsif 32 <= i && i <= 47
        f = H(b,c,d)
        g = (3 * i + 5) % 16
    elsif 48 <= i && i <= 63
        f = I(b,c,d)
        g = (7 * i) % 16
    end
    dTemp = d & 0xffffffff
    d = c & 0xffffffff
    c = b & 0xffffffff
    b = (b + leftrotate(a + f + k[i] + @arr[g], s[i])) & 0xffffffff
    a = dTemp
end


table[0] += a
table[1] += b
table[2] += c
table[3] += d

p bitize_print table
p Digest::MD5.hexdigest(@input) # "d4108e090956a15e38e1b15151004086"
