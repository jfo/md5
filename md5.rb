class Array
    def to_int(x = 8)
        self.each_with_index.map{|e,i| e << (x* i)}.reduce{|acc, e| acc | e}
    end
end
require 'digest'

@rotate_amounts = [ 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
                    5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
                    4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
                    6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 ]

@constants = (0.. 63).map { |i| (2**32 * Math.sin(i + 1).abs).floor }

@init_values = [ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 ]

one = ->(b,c,d){ (b & c) | (~b & d) }
two = ->(b,c,d){ (d & b) | (~d & c) }
three = ->(b,c,d){ b ^ c ^ d }
four = ->(b,c,d){ c ^ (b | ~d) }
@functions = [
    (0..15).map{ one },
    (16..31).map{ two },
    (32..47).map{ three },
    (48..63).map{ four }
].flatten

one = ->(i){ i }
two = ->(i){ (5 * i + 1) % 16 }
three = ->(i){ (3 * i + 5) % 16 }
four = ->(i){ (7 * i) % 16 }
@index_functions = [
    (0..15).map{ one },
    (16..31).map{ two },
    (32..47).map{ three },
    (48..63).map{ four }
].flatten

def left_rotate(x, amount)
    x &= 0xffffffff
    ((x << amount) | (x >> (32 - amount))) & 0xffffffff
end

def md5(message)
    message = message.bytes
    orig_len_in_bits = (8 * message.length) & 0xffffffffffffffff
    message << 0x80
    while message.length % 64 != 56
        message << 0
    end
    (message <<
        orig_len_in_bits
        .to_s(16)
        .rjust(32, '0')
        .scan(/../)
        .map{|e| e.hex}
        .reverse).flatten!

    hash_pieces = @init_values.clone
    a, b, c, d = hash_pieces
    chunk = message[0..64]

    (0..63).each do |i|
        f = @functions[i].call(b, c, d)
        g = @index_functions[i].call(i)
        to_rotate = a + f + @constants[i] + chunk[4*g...4*g+4].to_int
        new_b = (b + left_rotate(to_rotate, @rotate_amounts[i])) & 0xFFFFFFFF
        a, b, c, d = d, new_b, b, c
    end

    [a,b,c,d].each_with_index do |val, i|
        hash_pieces[i] += val
        hash_pieces[i] &= 0xFFFFFFFF
    end
    hash_pieces.to_int(32)
end

puts md5("This is my test string.").to_s(16).scan(/../).reverse.join

