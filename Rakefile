require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("README.rdoc", "lib/*.rb")
end

task :default => :spec


