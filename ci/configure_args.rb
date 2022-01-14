$ruby_wasm_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))

def configure_args(target, flavor, libs)
    ldflags = %w(-Xlinker -zstack-size=16777216)
    xldflags = []

    args = ["--host", target]
    args << "--with-static-linked-ext"

    case flavor
    when /^minimal/
        args << %Q(--with-ext="")
    when /^full/
        args << %Q(--with-ext="bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor")
    else
        raise "unknown flavor: #{flavor}"
    end

    case target
    when "wasm32-unknown-wasi"
    when "wasm32-unknown-emscripten"
        ldflags.concat(%w(-s MODULARIZE=1))
        args.concat(%w(CC=emcc LD=emcc AR=emar RANLIB=emranlib))
    else
        raise "unknown flavor: #{flavor}"
    end

    (libs || []).each do |lib|
        xldflags << "@#{$ruby_wasm_dir}/ext/#{lib}/link.filelist"
    end
    xldflags << "#{$ruby_wasm_dir}/ext/extinit.o"

    args << %Q(LDFLAGS="#{ldflags.join(" ")}")
    args << %Q(XLDFLAGS="#{xldflags.join(" ")}")
    args << %Q(debugflags="-g0")
    args
end

if $0 == __FILE__
    require "optparse"
    opt = OptionParser.new
    flavor = target = libs = nil
    opt.on("--flavor FLAVOR") { |v| flavor = v }
    opt.on("--target TARGET") { |v| target = v }
    opt.on("--libs LIBRARIES", Array) { |v| libs = v }
    
    opt.parse!(ARGV)
    raise "missing flavor" if flavor.nil?
    raise "missing target" if target.nil?
    libs ||= []

    print configure_args(target, flavor, libs).join(" ")
end
