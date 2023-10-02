# frozen_string_literal: true

SimpleCov.start do
  command_name "Minitest"
  add_filter "/.bundle/"
  add_filter "/vendor/"
  add_filter "/spec/"
  add_filter "/lib/http/2/next/base64"
  coverage_dir "coverage"
  minimum_coverage 90
end
