module RubyWasm
  # Build executor to run the actual build commands.
  class BuildExecutor
    attr_reader :process_count

    def initialize(verbose: false, process_count: nil)
      @verbose = verbose
      @github_actions_markup = ENV["ENABLE_GITHUB_ACTIONS_MARKUP"] != nil
      __skip__ =
        begin
          require "etc"
          @process_count = process_count || Etc.nprocessors
        rescue LoadError
          @process_count = process_count || 1
        end
    end

    def system(*args, chdir: nil, env: nil)
      require "open3"

      _print_command(args, env)

      # @type var kwargs: Hash[Symbol, untyped]
      kwargs = {}
      kwargs[:chdir] = chdir if chdir

      args = args.to_a.map(&:to_s)
      # TODO: Remove __skip__ once we have open3 RBS definitions.
      __skip__ =
        if @verbose || !$stdout.tty?
          kwargs[:exception] = true
          if env
            Kernel.system(env, *args, **kwargs)
          else
            Kernel.system(*args, **kwargs)
          end
        else
          printer = StatusPrinter.new
          block =
            proc do |stdin, stdout, stderr, wait_thr|
              mux = Mutex.new
              out = String.new
              err = String.new
              readers =
                [
                  [stdout, :stdout, out],
                  [stderr, :stderr, err]
                ].map do |io, name, str|
                  reader =
                    Thread.new do
                      while (line = io.gets)
                        mux.synchronize do
                          printer.send(name, line)
                          str << line
                        end
                      end
                    end
                  reader.report_on_exception = false
                  reader
                end

              readers.each(&:join)

              [out, err, wait_thr.value]
            end
          begin
            stdout, stderr, status =
              if env
                Open3.popen3(env, *args, **kwargs, &block)
              else
                Open3.popen3(*args, **kwargs, &block)
              end
            unless status.success?
              $stderr.puts stdout
              $stderr.puts stderr
              cmd_to_print = args.map { |a| "'#{a}'" }.join(" ")
              raise "Command failed with status (#{status.exitstatus}): #{cmd_to_print}"
            end
          ensure
            printer.done
          end
        end
      return
    rescue => e
      $stdout.flush
      $stderr.puts "Try running with `rake --verbose` for more complete output."
      raise e
    end

    def begin_section(klass, name, note)
      message = "\e[1;36m==>\e[0m \e[1m#{klass}(#{name}) -- #{note}\e[0m"
      if @github_actions_markup
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
      puts "::endgroup::" if @github_actions_markup
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

    def ln_s(src, dest)
      FileUtils.ln_s(src, dest)
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

  # Human readable status printer for the build.
  class StatusPrinter
    def initialize
      @mutex = Mutex.new
      @counter = 0
      @indicators = "|/-\\"
    end

    def stdout(message)
      require "io/console"
      @mutex.synchronize do
        $stdout.print "\e[K"
        first_line = message.lines(chomp: true).first || ""

        # Make sure we don't line-wrap the output
        size =
          __skip__ =
            IO.respond_to?(:console_size) ? IO.console_size : IO.console.winsize
        terminal_width = size[1].to_i.nonzero? || 80
        width_limit = terminal_width / 2 - 3

        if first_line.length > width_limit
          first_line = (first_line[0..width_limit - 5] || "") + "..."
        end
        indicator = @indicators[@counter] || " "
        to_print = "  " + indicator + " " + first_line
        $stdout.print to_print
        $stdout.print "\e[1A\n"
        @counter += 1
        @counter = 0 if @counter >= @indicators.length
      end
    end

    def stderr(message)
      @mutex.synchronize { $stdout.print message }
    end

    def done
      @mutex.synchronize { $stdout.print "\e[K" }
    end
  end
end
