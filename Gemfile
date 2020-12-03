# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"
gem "simplecov", require: false
gem "yard"

gem "pry"
gem "pry-byebug", platform: :mri
gem "rspec", "~> 3.4.0"

if RUBY_VERSION.start_with?("2.1")
  gem "rubocop", "0.57.2"
elsif RUBY_VERSION.start_with?("2.2")
  gem "rubocop", "0.68.1"
elsif RUBY_VERSION.start_with?("2.3")
  gem "rubocop", "~> 0.81.0"
  gem "rubocop-performance", "~> 1.5.2"
else
  gem "rubocop", "~> 1.0.0"
  gem "rubocop-performance", "~> 1.5.2"
end
