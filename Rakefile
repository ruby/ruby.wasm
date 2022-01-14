require "rake"
require_relative "ci/configure_args"

namespace :deps do
    task :check do
        check_executable("cargo")
        check_executable("wit-bindgen")
        check_envvar("WASI_SDK_PATH")
    end
end

BUILD_SOURCES = [
    {
        name: "pr-1726",
        type: "github",
        repo: "kateinoigakukun/ruby",
        rev:  "337b9df76e2850292c31983d2c992f768fc4cc5e",
    }
]

BUILD_PARAMS = [
    { target: "wasm32-unknown-wasi", flavor: "minimal", libs: [] },
    { target: "wasm32-unknown-wasi", flavor: "minimal-js", libs: ["js", "witapi"] },
    { target: "wasm32-unknown-wasi", flavor: "full", libs: [] },
    { target: "wasm32-unknown-wasi", flavor: "full-js", libs: ["js", "witapi"] },
    { target: "wasm32-unknown-emscripten", flavor: "minimal", libs: [] },
    { target: "wasm32-unknown-emscripten", flavor: "full", libs: [] },
]

class BuildPlan
    def initialize(source, params, base_dir)
        @source = source
        @params = params
        @base_dir = base_dir
    end

    def name
        "#{@source[:name]}-#{@params[:target]}-#{@params[:flavor]}"
    end

    def build_dir
        "#{@base_dir}/build/build/#{name}"
    end

    def dest_dir
        "#{@base_dir}/rubies/#{name}"
    end

    def build_libs_cmd(src_dir)
        build_libs_rb = "#{@base_dir}/ci/build-libs.rb"
        "ruby #{build_libs_rb} --ruby-src-dir=#{src_dir} --ruby-build-dir=#{build_dir} --target #{@params[:target]} --libs \"#{@params[:libs].join(" ")}\""
    end
end

namespace :build do
    BUILD_SOURCES.each do |source|
        base_dir = Dir.pwd
        src_dir = "#{base_dir}/build/src/#{source[:name]}"

        directory src_dir do
            case source[:type]
            when "github"
                tarball_url = "https://api.github.com/repos/#{source[:repo]}/tarball/#{source[:rev]}"
                mkdir_p src_dir
                sh "curl -L #{tarball_url} | tar xz --strip-components=1", chdir: src_dir
            else
                raise "unknown source type: #{source[:type]}"
            end
        end
        build_plans = BUILD_PARAMS.map do |params|
            build = BuildPlan.new(source, params, Dir.pwd)

            directory build.dest_dir
            desc "Build #{build.name}"
            task build.name => ["deps:check", src_dir, build.dest_dir] do
                sh "./autogen.sh", chdir: src_dir
                mkdir_p build.build_dir
                unless File.exist?("#{build.build_dir}/Makefile")
                    args = configure_args(params[:target], params[:flavor], params[:libs])
                    args << "--disable-install-doc"
                    sh "#{src_dir}/configure #{args.join(" ")}", chdir: build.build_dir
                end
                sh build.build_libs_cmd(src_dir), chdir: build.build_dir
                sh "make install DESTDIR=#{build.dest_dir}", chdir: build.build_dir
            end
            build
        end

        desc "Build #{source[:name]}"
        multitask source[:name] => build_plans.map { |build| build.name }
    end
end

def check_executable(command)
    (ENV["PATH"] || "").split(File::PATH_SEPARATOR).each do |path_dir|
        bin_path = File.join(path_dir, command)
        return bin_path if File.executable?(bin_path)
    end
    raise "missing executable: #{command}"
end

def check_envvar(name)
    if ENV[name].nil?
        raise "missing environment variable: #{name}"
    end
end
