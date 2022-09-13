module RubyWasm
  BuildParams =
    Struct.new(
      :name,
      :target,
      :debug,
      :default_exts,
      :wasmoptflags,
      keyword_init: true
    )
end
