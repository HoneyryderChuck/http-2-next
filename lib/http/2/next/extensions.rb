# frozen_string_literal: true

module HTTP2Next
  module Extensions
    unless Regexp.method_defined?(:match?)
      refine Regexp do
        def match?(*args)
          !match(*args).nil?
        end
      end
    end
  end
end
