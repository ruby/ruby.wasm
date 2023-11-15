require_relative "build/build_params"
require_relative "build/product"
require_relative "build/toolchain"

module RubyWasm
  # Build executor to run the actual build commands.
  class BuildExecutor
    def initialize(verbose: false)
      @verbose = verbose
    end

    def system(*args, chdir: nil, out: nil, env: nil)
      _print_command(args, env)

      if @verbose
        out ||= $stdout
      else
        # Capture stdout by default
        out_pipe = IO.pipe
        out = out_pipe[1]
      end
      # @type var kwargs: Hash[Symbol, untyped]
      kwargs = { exception: true, out: out }
      kwargs[:chdir] = chdir if chdir
      begin
        if env
          Kernel.system(env, *args.to_a.map(&:to_s), **kwargs)
        else
          Kernel.system(*args.to_a.map(&:to_s), **kwargs)
        end
      ensure
        out.close if out_pipe
      end
    rescue => e
      if out_pipe
        # Print the output of the failed command
        puts out_pipe[0].read
      end
      $stdout.flush
      raise e
    end

    def begin_section(klass, name, note)
      message = "\e[1;36m==>\e[0m \e[1m#{klass}(#{name}) -- #{note}\e[0m"
      if ENV["GITHUB_ACTIONS"]
        puts "::group::#{message}"
      else
        puts message
      end

      # Record the start time
      @start_times ||= Hash.new
      @start_times[[klass, name]] = Time.now

      $stdout.flush
    end

    def end_section(klass, name)
      took = Time.now - @start_times[[klass, name]]
      if ENV["GITHUB_ACTIONS"]
        puts "::endgroup::"
      end
      puts "\e[1;36m==>\e[0m \e[1m#{klass}(#{name}) -- done in #{took.round(2)}s\e[0m"
    end

    def rm_rf(list)
      FileUtils.rm_rf(list)
    end

    def rm_f(list)
      FileUtils.rm_f(list)
    end

    def cp_r(src, dest)
      FileUtils.cp_r(src, dest)
    end

    def mv(src, dest)
      FileUtils.mv(src, dest)
    end

    def mkdir_p(list)
      FileUtils.mkdir_p(list)
    end

    def write(path, data)
      File.write(path, data)
    end

    private

    def _print_command(args, env)
      require "shellwords"
      # Bold cyan
      print "\e[1;36m  ==>\e[0m "
      print "env " + env.map { |k, v| "#{k}=#{v}" }.join(" ") + " " if env
      print args.map { |arg| Shellwords.escape(arg.to_s) }.join(" ") + "\n"
    end
  end
end
