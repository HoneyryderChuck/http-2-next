# frozen_string_literal: true

module HTTP2Next
  module Header
    # Responsible for encoding header key-value pairs using HPACK algorithm.
    class Compressor
      # @param options [Hash] encoding options
      def initialize(options = {})
        @cc = EncodingContext.new(options)
      end

      # Set dynamic table size in EncodingContext
      # @param size [Integer] new dynamic table size
      def table_size=(size)
        @cc.table_size = size
      end

      # Encodes provided value via integer representation.
      # - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#section-5.1
      #
      #  If I < 2^N - 1, encode I on N bits
      #  Else
      #      encode 2^N - 1 on N bits
      #      I = I - (2^N - 1)
      #      While I >= 128
      #           Encode (I % 128 + 128) on 8 bits
      #           I = I / 128
      #      encode (I) on 8 bits
      #
      # @param i [Integer] value to encode
      # @param n [Integer] number of available bits
      # @return [String] binary string
      def integer(i, n)
        limit = (2**n) - 1
        return [i].pack("C") if i < limit

        bytes = []
        bytes.push limit unless n.zero?

        i -= limit
        while i >= 128
          bytes.push((i % 128) + 128)
          i /= 128
        end

        bytes.push i
        bytes.pack("C*")
      end

      # Encodes provided value via string literal representation.
      # - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#section-5.2
      #
      # * The string length, defined as the number of bytes needed to store
      #   its UTF-8 representation, is represented as an integer with a seven
      #   bits prefix. If the string length is strictly less than 127, it is
      #   represented as one byte.
      # * If the bit 7 of the first byte is 1, the string value is represented
      #   as a list of Huffman encoded octets
      #   (padded with bit 1's until next octet boundary).
      # * If the bit 7 of the first byte is 0, the string value is
      #   represented as a list of UTF-8 encoded octets.
      #
      # +@options [:huffman]+ controls whether to use Huffman encoding:
      #  :never   Do not use Huffman encoding
      #  :always  Always use Huffman encoding
      #  :shorter Use Huffman when the result is strictly shorter
      #
      # @param str [String]
      # @return [String] binary string
      def string(str)
        plain = nil
        huffman = nil
        plain = integer(str.bytesize, 7) << str.dup.force_encoding(Encoding::BINARY) unless @cc.options[:huffman] == :always
        unless @cc.options[:huffman] == :never
          huffman = Huffman.new.encode(str)
          huffman = integer(huffman.bytesize, 7) << huffman
          huffman.setbyte(0, huffman.ord | 0x80)
        end
        case @cc.options[:huffman]
        when :always
          huffman
        when :never
          plain
        else
          huffman.bytesize < plain.bytesize ? huffman : plain
        end
      end

      # Encodes header command with appropriate header representation.
      #
      # @param h [Hash] header command
      # @param buffer [String]
      # @return [Buffer]
      def header(h, buffer = "".b)
        rep = HEADREP[h[:type]]

        case h[:type]
        when :indexed
          buffer << integer(h[:name] + 1, rep[:prefix])
        when :changetablesize
          buffer << integer(h[:value], rep[:prefix])
        else
          if h[:name].is_a? Integer
            buffer << integer(h[:name] + 1, rep[:prefix])
          else
            buffer << integer(0, rep[:prefix])
            buffer << string(h[:name])
          end

          buffer << string(h[:value])
        end

        # set header representation pattern on first byte
        fb = buffer.ord | rep[:pattern]
        buffer.setbyte(0, fb)

        buffer
      end

      # Encodes provided list of HTTP headers.
      #
      # @param headers [Array] +[[name, value], ...]+
      # @return [Buffer]
      def encode(headers)
        buffer = "".b
        pseudo_headers, regular_headers = headers.partition { |f, _| f.start_with? ":" }
        headers = [*pseudo_headers, *regular_headers]
        commands = @cc.encode(headers)
        commands.each do |cmd|
          buffer << header(cmd)
        end

        buffer
      end
    end
  end
end
