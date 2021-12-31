require "optparse"

opt = OptionParser.new
opt.on("--target TARGET") { |v| $target = v }
opt.on("--libs LIBRARIES", Array) { |v| $libs = v }
opt.on("--ruby-src-dir DIR") { |v| $ruby_src_dir = File.expand_path(v) }
opt.on("--ruby-build-dir DIR") { |v| $ruby_build_dir = File.expand_path(v) }

opt.parse!(ARGV)

$ruby_build_dir ||= $ruby_src_dir
$libs ||= []

$ruby_wasm_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))

make_args = []

case $target
when "wasm32-unknown-wasi"
    wasi_sdk_path = ENV['WASI_SDK_PATH']
    raise "missing WASI_SDK_PATH" unless wasi_sdk_path
    cc = "#{wasi_sdk_path}/bin/clang"
    make_args << "CC=#{cc}"
    make_args << "LD=#{wasi_sdk_path}/bin/wasm-ld"
    make_args << "AR=#{wasi_sdk_path}/bin/llvm-ar"
    make_args << "RANLIB=#{wasi_sdk_path}/bin/llvm-ranlib"
when "wasm32-unknown-emscripten"
    cc = "emcc"
    make_args << "CC=#{cc}"
    make_args << "LD=emcc"
    make_args << "AR=emar"
    make_args << "RANLIB=emranlib"
else
    raise "unknown target: #{$target}"
end

make_args << %Q(RUBY_INCLUDE_FLAGS="-I#{$ruby_src_dir}/include -I#{$ruby_build_dir}/.ext/include/wasm32-wasi")

$libs.each do |lib|
    make_cmd = %Q(make -C "#{$ruby_wasm_dir}/ext/#{lib}" obj link.filelist #{make_args.join(" ")})
    puts make_cmd
    `#{make_cmd}`
end

extinit_cmd = %Q(ruby #{$ruby_wasm_dir}/ext/extinit.rb #{$libs.join(" ")} | #{cc} -c -x c - -o #{$ruby_wasm_dir}/ext/extinit.o)
puts extinit_cmd
`#{extinit_cmd}`
