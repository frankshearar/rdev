require 'rake'
require 'spec/rake/spectask'
require 'rake/clean'

desc "Run all unit tests"
Spec::Rake::specTask.new('tests') { |t|
  t.spec_opts = ["-cfs"]
  t.spec_files = FileList['spec/**/*.rb'].sort
}
