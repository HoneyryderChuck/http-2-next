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
    unless String.method_defined?(:unpack1)
      refine String do
        def unpack1(format)
          unpack(format).first
        end
      end
    end
  end
end
