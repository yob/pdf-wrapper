require "rubygems"
require "bundler"
Bundler.setup
Bundler.require

require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'roodi'
require 'roodi_task'

desc "Default Task"
task :default => [ :spec ]

# run all rspecs
desc "Run all rspec files"
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_files = Dir.glob("specs/**/*_spec.rb")
  t.spec_opts = ['-c']
  t.libs << File.dirname(__FILE__) + "/specs"
end

# Genereate the RDoc documentation
desc "Create documentation"
Rake::RDocTask.new("doc") do |rdoc|
  rdoc.title = "pdf-wrapper"
  rdoc.rdoc_dir = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + '/rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('TODO')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << "--inline-source"
end

RoodiTask.new 'roodi', ['lib/**/*.rb']
