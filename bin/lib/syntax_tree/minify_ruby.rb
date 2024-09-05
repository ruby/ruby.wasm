require "syntax_tree"

module SyntaxTree
  module MinifyRuby

    # This is a required API for syntax tree which just delegates to SyntaxTree.parse.
    def self.parse(source)
      ::SyntaxTree.parse(source)
    end

    # This is the main entrypoint for the formatter. It parses the source,
    # builds a formatter, then prints the result.
    def self.format(source, _maxwidth = nil)
      formatter = Formatter.new(source)
      program = parse(source)
      CommentStrippingVisitor.new.visit(program)
      program.format(formatter)

      formatter.flush
      formatter.output.join
    end

    # This is a required API for syntax tree which just delegates to SyntaxTree.read.
    def self.read(filepath)
      ::SyntaxTree.read(filepath)
    end

    class CommentStrippingVisitor < SyntaxTree::Visitor
      def visit(node)
        if node and node.comments.any?
          node.comments.clear
        end
        super(node)
      end

      def visit_statements(node)
        node.body.delete_if { _1.is_a?(SyntaxTree::Comment) }
        super(node)
      end
    end

    class Formatter < SyntaxTree::Formatter
      def initialize(source)
        super(source, [], Float::INFINITY) do |n|
          # This block, called `genspace`, is used to generate indentation for `n` depth.
          ""
        end
      end

      def breakable(
        separator = " ",
        _width = separator.length,
        indent: nil,
        force: nil
      )
        # Don't break when already broken
        return if target.last.is_a?(PrettierPrint::BreakParent)
        return if not force and separator == ""
        super(separator, _width, indent: indent, force: force)
      end
    end
  end
end
