# frozen_string_literal: true

require "mkmf"
require "rb_sys/mkmf"

create_rust_makefile("ruby_wasm/ruby_wasm") do |r|
  # We require head Ruby, so we need to fallback to compiled API
  r.use_stable_api_compiled_fallback = true
end
