namespace :format do
  begin
    require "syntax_tree/rake_tasks"
    SyntaxTree::Rake::WriteTask.new(:ruby)
  rescue LoadError
  end

  task :js do
    sh "npm run format", chdir: "packages/npm-packages/ruby-wasm-wasi"
  end

  task :c do
    sh "find ./ext -iname *.h -o -iname *.c | xargs clang-format -i"
  end
end

task :format do
  if Rake::Task.task_defined?("format:ruby")
    Rake::Task["format:ruby"].invoke
  else
    puts "\e[33mSyntaxTree not installed, skipping format:ruby\e[0m"
  end
  Rake::Task["format:js"].invoke
  Rake::Task["format:c"].invoke
end
