# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "yard"
require "open3"
require_relative "lib/tasks/generate_huffman_table"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = "./spec/hpack_test_spec.rb"
end

RUBY_MAJOR_MINOR = RUBY_VERSION.split(/\./).first(2).join(".")

desc "Run rubocop"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options += %W[-c.rubocop-#{RUBY_MAJOR_MINOR}.yml]
end

RSpec::Core::RakeTask.new(:hpack) do |t|
  t.pattern = "./spec/hpack_test_spec.rb"
end

task :h2spec_install do
  platform = case RUBY_PLATFORM
             when /darwin/
               "h2spec_darwin_amd64.tar.gz"
             when /cygwin|mswin|mingw|bccwin|wince|emx/
               "h2spec_windows_amd64.zip"
             else
               "h2spec_linux_amd64.tar.gz"
             end
  uri = "https://github.com/summerwind/h2spec/releases/download/v2.2.0/#{platform}"

  tar_location = File.join(__dir__, platform)
  require "net/http"
  File.open(tar_location, "wb") do |file|
    response = nil
    loop do
      uri = URI(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      # http.set_debug_output($stderr)
      response = http.get(uri.request_uri)
      break unless response.is_a?(Net::HTTPRedirection)
      uri = response["location"]
    end
    file.write(response.body)
  end

  case RUBY_PLATFORM
  when /cygwin|mswin|mingw|bccwin|wince|emx/
    puts "Hi, you're on Windows, please unzip this file: #{tar_location}"
  else
    system("tar -xvzf #{tar_location} h2spec")
  end
  FileUtils.rm(tar_location)
end

task :h2spec do
  h2spec = File.join(__dir__, "h2spec")
  unless File.exist?(h2spec)
    abort 'Please install h2spec first.\n'\
          'Run "rake h2spec_install",\n'\
          "Or Download the binary from https://github.com/summerwind/h2spec/releases"
  end

  server_pid = Process.spawn("ruby example/server.rb -p 9000", out: File::NULL)
  sleep 1
  h2spec_pid = fork do
    exec("#{h2spec} -p 9000 -o 1")
  end
  Process.waitpid(h2spec_pid)
  Process.kill("TERM", server_pid)
end

RuboCop::RakeTask.new
YARD::Rake::YardocTask.new

task default: %i[spec rubocop]
task all: %i[default hpack]
