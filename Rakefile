require 'rake'
require 'rspec/core/rake_task'
require 'rake/clean'

desc "Run all unit tests"
RSpec::Core::RakeTask.new('specs') { |t|
  t.rspec_opts = ["-cfs"]
  t.pattern = FileList['spec/**/*.rb'].sort
}
