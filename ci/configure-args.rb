require "optparse"

opt = OptionParser.new
opt.on("--flavor FLAVOR") { |v| $flavor = v }
opt.on("--target TARGET") { |v| $target = v }
opt.on("--libs LIBRARIES", Array) { |v| $libs = v }
opt.on("--ruby-wasm-dir DIR") { |v| $ruby_wasm_dir = v }

opt.parse!(ARGV)

ldflags = %w(-Xlinker -zstack-size=16777216)
xldflags = []

configure_args = ["--host", $target]
configure_args << "--with-static-linked-ext"

case $flavor
when "minimal"
    configure_args << %Q(--with-ext="")
when "full"
    configure_args << %Q(--with-ext="bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor")
else
    raise "unknown flavor: #{$flavor}"
end

case $target
when "wasm32-unknown-wasi"
when "wasm32-unknown-emscripten"
    ldflags.concat(%w(-s MODULARIZE=1))
    configure_args.concat(%w(CC=emcc LD=emcc AR=emar RANLIB=emranlib))
else
    raise "unknown flavor: #{$flavor}"
end

($libs || []).each do |lib|
    xldflags << "#{$ruby_wasm_dir}/ext/#{lib}/#{lib}.o"
end
xldflags << "#{$ruby_wasm_dir}/ext/extinit.o"

configure_args << %Q(LDFLAGS="#{ldflags.join(" ")}")
configure_args << %Q(XLDFLAGS="#{xldflags.join(" ")}")

print configure_args.join(" ")
