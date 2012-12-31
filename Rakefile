require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |task|
  task.libs << 'lib'
  task.pattern = 'test/**/*_test.rb'
  task.verbose = false
end

desc "Run tests"
task :default => :test