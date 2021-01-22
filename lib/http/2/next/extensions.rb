# frozen_string_literal: true

module HTTP2Next
  module RegexpExtensions
    unless Regexp.method_defined?(:match?)
      refine Regexp do
        def match?(*args)
          !match(*args).nil?
        end
      end
    end
  end

  module StringExtensions
    refine String do
      def read(n)
        slice!(0, n)
      end

      def read_uint32
        read(4).unpack1("N")
      end

      def shift_byte
        slice!(0, 1).ord
      end

      unless String.method_defined?(:unpack1)
        def unpack1(format)
          unpack(format).first
        end
      end
    end
  end
end
