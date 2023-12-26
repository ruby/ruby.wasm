module JS
  class RequireRemote
    # Execute the body of the response and record the URL.
    class Evaluator
      def evaluate(code, filename, final_url)
        Kernel.eval(code, ::Object::TOPLEVEL_BINDING, filename)
        $LOADED_FEATURES << final_url
      end

      def evaluated?(url)
        $LOADED_FEATURES.include?(url)
      end
    end
  end
end
