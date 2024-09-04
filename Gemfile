# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "rake"
  gem "rake-compiler"
  gem "rb_sys", "0.9.97"
end

group :check do
  # Use the latest version of webrick for URI change in Ruby 3.4
  gem "webrick", github: "ruby/webrick", ref: "0c600e169bd4ae267cb5eeb6197277c848323bbe"
  gem "syntax_tree", "~> 3.5"
  gem "steep"
end
