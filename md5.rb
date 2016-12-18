@rotate_amounts = [[7, 12, 17, 22],
                   [5,  9, 14, 20],
                   [4, 11, 16, 23],
                   [6, 10, 15, 21]].map{|e|[e,e,e,e]}.flatten

@constants = (0.. 63).map { |i| (2**32 * Math.sin(i + 1).abs).floor }


def left_rotate(x, amount)
    x &= 0xffffffff
    ((x << amount) | (x >> (32 - amount))) & 0xffffffff
end

def msg_to_byte_array(message)
    message = message.bytes
    orig_len_in_bits = (8 * message.length) & 0xffffffffffffffff

    message << 0x80
    while message.length % 64 != 56
        message << 0
    end

    (message <<
        orig_len_in_bits
        .to_s(16)
        .rjust(16, '0')
        .scan(/../)
        .map{|e| e.hex}
        .reverse).flatten!
    message
end

def md5(message)
    message = msg_to_byte_array(message)
    @acc = [ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 ]

    (0...message.count / 64).each do |message_index_base|
        message_index = message_index_base * 64
        chunk = message[message_index..message_index + 63]

        a, b, c, d = @acc

        (0..63).each do |i|
            if i < 16
                f = (b & c) | (~b & d)
                g = i
            elsif i < 32
                f = (d & b) | (~d & c)
                g = (5 * i + 1) % 16
            elsif i < 48
                f = b ^ c ^ d
                g = (3 * i + 5) % 16
            elsif i < 64
                f = c ^ (b | ~d)
                g = (7 * i) % 16
            end
            to_rotate = a + f + @constants[i] + (chunk[4*g...4*g+4]
                                                 .each_with_index
                                                 .map{|e,i| e << (8 * i)}
                                                 .reduce{|acc, e| acc | e})

            new_b = b + left_rotate(to_rotate, @rotate_amounts[i])
            a, b, c, d = d, new_b, b, c
        end

        [a,b,c,d].each_with_index do |val, i|
            @acc[i] += val
            @acc[i] &= 0xffffffff
        end
    end
    @acc.each_with_index
        .map{|e,i| e << (32 * i)}
        .reduce{|acc, e| acc | e}
        .to_s(16)
        .rjust(32, '0')
        .scan(/../)
        .reverse.join
end

require "digest"
@door = "abbhdwsy"
# md5 (@door)
puts md5 (@door)
# puts Digest::MD5.hexdigest(@door)
