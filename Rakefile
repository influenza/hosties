require 'rake/testtask'
require 'rspec/core/rake_task'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

RSpec::Core::RakeTask.new('spec') do |t|
  t.fail_on_error = false
end

desc "Run tests"
task :default => :spec
