# This script checks the max number of call frames under WebAssembly restriction
#
# Example runs
# $ ruby vm_deep_call.rb
# $ RUBY_EXE="wasmtime run --mapdir /::/ head-wasm32-unknown-wasi-minimal/usr/local/bin/ruby --" ruby vm_deep_call.rb
# $ RUBY_EXE="wasmtime run --env RUBY_FIBER_MACHINE_STACK_SIZE=20971520 --mapdir /::/ head-wasm32-unknown-wasi-minimal/usr/local/bin/ruby --" ruby vm_deep_call.rb

def vm_rec n
  vm_rec n - 1 if n > 0
end

def vm_c_rec n
  1.times do
    vm_c_rec n - 1 if n > 0
  end
end

def vm_rec_fiber n
  Fiber.new { vm_rec n }.resume
end

def vm_c_rec_fiber n
  Fiber.new { vm_c_rec n }.resume
end

def check(ruby_exe, target, n)
  cmd = %Q(#{ruby_exe} -r #{File.expand_path(__FILE__)} -e "#{target}(#{n})")
  Kernel.system(cmd, err: File::NULL)
end

def bisect(ruby_exe, target)
  min = 0
  max = 15000
  while min < max
    mid = (min + max) / 2
    ok = check(ruby_exe, target, mid)
    if ok
      min = mid + 1
    else
      max = mid
    end
  end
  min
end

def main
  ruby_exe = ENV['RUBY_EXE'] || 'ruby'
  puts "How deep the call stack can be"
  puts "  with only VM calls:           " + bisect(ruby_exe, "vm_rec").to_s
  puts "  with only VM calls in Fiber:  " + bisect(ruby_exe, "vm_rec_fiber").to_s
  puts "  with VM and C calls:          " + bisect(ruby_exe, "vm_c_rec").to_s
  puts "  with VM and C calls in Fiber: " + bisect(ruby_exe, "vm_c_rec_fiber").to_s
end

main if $0 == __FILE__
