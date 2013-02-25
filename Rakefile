require 'rake'
require 'rspec/core/rake_task'
require 'rake/clean'

desc "Run all unit tests"
RSpec::Core::RakeTask.new('test') { |t|
  t.rspec_opts = ["-c"]
  t.pattern = FileList['spec/**/test-parsing.rb'].sort
}
