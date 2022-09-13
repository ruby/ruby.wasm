begin
    require "syntax_tree/rake_tasks"
    SyntaxTree::Rake::WriteTask.new(:format)
rescue LoadError
end
