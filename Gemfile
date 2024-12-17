# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "rake"
  gem "rake-compiler"
  gem "rb_sys", "0.9.97"
  # Use the latest version of webrick for URI change in Ruby 3.4
  gem "webrick", "~> 1.8.2"
end

group :check do
  gem "syntax_tree", "~> 3.5"
  gem "steep", "~> 1.9" if RUBY_VERSION >= "3.1.0"
end
