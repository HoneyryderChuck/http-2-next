# frozen_string_literal: true

require "forwardable"

module HTTP2Next
  # Binary buffer wraps String.
  #
  class Buffer
    extend Forwardable

    using StringExtensions

    def_delegators :@buffer, :ord, :encoding, :setbyte, :unpack,
                   :size, :each_byte, :to_str, :to_s, :length, :inspect,
                   :[], :[]=, :empty?, :bytesize, :include?

    UINT32 = "N"
    private_constant :UINT32

    # Forces binary encoding on the string
    def initialize(str = "".b)
      str = str.dup if str.frozen?
      @buffer = str.force_encoding(Encoding::BINARY)
    end

    # Emulate StringIO#read: slice first n bytes from the buffer.
    #
    # @param n [Integer] number of bytes to slice from the buffer
    def read(n)
      Buffer.new(@buffer.slice!(0, n))
    end

    def unpack1(*arg)
      @buffer.unpack1(*arg)
    end

    # Emulate StringIO#getbyte: slice first byte from buffer.
    def getbyte
      read(1).ord
    end

    def slice!(*args)
      Buffer.new(@buffer.slice!(*args))
    end

    def slice(*args)
      Buffer.new(@buffer.slice(*args))
    end

    def force_encoding(*args)
      @buffer = @buffer.force_encoding(*args)
    end

    def ==(other)
      @buffer == other
    end

    def +(other)
      @buffer += other
    end

    # Emulate String#getbyte: return nth byte from buffer.
    def readbyte(n)
      @buffer[n].ord
    end

    # Slice unsigned 32-bit integer from buffer.
    # @return [Integer]
    def read_uint32
      read(4).unpack1(UINT32)
    end

    # Ensures that data that is added is binary encoded as well,
    # otherwise this could lead to the Buffer instance changing its encoding.
    %i[<< prepend].each do |mutating_method|
      class_eval(<<-METH, __FILE__, __LINE__ + 1)
      def #{mutating_method}(string)
        string = string.dup if string.frozen?
        @buffer.send __method__, string.force_encoding(Encoding::BINARY)

        self
      end
      METH
    end
  end
end
