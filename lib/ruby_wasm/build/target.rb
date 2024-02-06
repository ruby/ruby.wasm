module RubyWasm
  # A build target representation
  class Target
    attr_reader :triple

    def initialize(triple, pic: false)
      @triple = triple
      @pic = pic
    end

    def pic?
      @pic
    end

    def to_s
      "#{@triple}#{@pic ? "-pic" : ""}"
    end

    def cache_key(digest)
      digest << @triple
      digest << "pic" if @pic
    end
  end
end
