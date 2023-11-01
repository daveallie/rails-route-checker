# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require "bundler/setup"
require "rake/testtask"

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = FileList["test/**/*_test.rb"]
  test.warning = true
end

RuboCop::RakeTask.new(:rubocop)
task default: :rubocop
