require "bundler/gem_tasks"
require "fileutils"

include FileUtils

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rdoc/task"
RDoc::Task.new do |rdoc|
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("README.rdoc", "lib/*.rb")
end

def sh!(command)
  sh command do |ok,res|
    fail "Problem running '#{command}'" unless ok
  end
end

task :publish_rdoc do
  rm_rf "tmp"
  mkdir_p "tmp"
  chdir "tmp" do
    sh! "git clone git@github.com:stitchfix/immutable-struct.git"
    chdir "immutable-struct" do
      sh! "git checkout gh-pages"
      `rm -rf *`
    end
  end
  Rake::Task["rdoc"].invoke
  `cp -R html/* tmp/immutable-struct`
  chdir "tmp/immutable-struct" do
    sh! "git add -A ."
    sh! "git commit -m 'updated rdoc'"
    sh! "git push origin gh-pages"
  end
end

task :default => :spec


