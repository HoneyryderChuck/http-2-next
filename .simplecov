SimpleCov.start do
  command_name "Minitest"
  add_filter "/.bundle/"
  add_filter "/vendor/"
  add_filter "/spec/"
  coverage_dir "www/coverage"
  minimum_coverage 90
end
