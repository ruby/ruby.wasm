D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"
  # RBS's stdlib signatures don't have rake signatures yet.
  ignore "lib/ruby_wasm/rake_task.rb"

  library "digest"
  library "tmpdir"
  library "fileutils"
  library "open-uri"
  library "uri"
  library "shellwords"

  configure_code_diagnostics(D::Ruby.default)
end