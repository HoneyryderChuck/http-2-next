# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"
gem "simplecov", require: false
gem "yard"

gem "pry"
gem "pry-byebug", platform: :mri
gem "rspec", "~> 3.4.0"

rubocop_version = if RUBY_VERSION.start_with?("2.1")
                    "0.57.2"
                  elsif RUBY_VERSION.start_with?("2.2")
                    "0.68.1"
                  else
                    "0.80.0"
                  end

gem "rubocop", rubocop_version, require: false
