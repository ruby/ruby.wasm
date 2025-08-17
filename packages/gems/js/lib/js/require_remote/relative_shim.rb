require 'js/require_remote'

module Kernel
  alias original_require_relative require_relative
                                                                   
  def require_relative(path)
    caller_path = caller_locations(1, 1).first.absolute_path || ''
    dir = File.dirname(caller_path)
    file = File.absolute_path(path, dir)
                                                                   
    original_require_relative(file)
  rescue LoadError
    JS::RequireRemote.instance.load(path)
  end
end
