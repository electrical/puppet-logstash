require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'rubocop/rake_task'
require 'puppet-doc-lint/rake_task'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

exclude_paths = %w(
  pkg/**/*
  vendor/**/*
  .vendor/**/*
  spec/**/*
)

PuppetDocLint.configuration.ignore_paths = exclude_paths

PuppetSyntax.exclude_paths = exclude_paths
PuppetSyntax.future_parser = true if ENV['FUTURE_PARSER'] == 'yes'

[
  '80chars',
  'class_inherits_from_params_class',
  'class_parameter_defaults',
  'documentation',
  'single_quote_string_with_variables',
  'resource_reference_without_whitespace',
  '140chars'
].each do |check|
  PuppetLint.configuration.send("disable_#{check}")
end

PuppetLint.configuration.ignore_paths = exclude_paths
PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"

desc 'Run integration tests'
RSpec::Core::RakeTask.new('beaker:integration') do |c|
  c.pattern = 'spec/integration/integration*.rb'
end

RuboCop::RakeTask.new(:rubocop) do |task|
  # These make the rubocop experience maybe slightly less terrible
  task.options = ['-D', '-S', '-E']
end

desc 'Run metadata_lint, lint, syntax, and spec tests.'
task test: [
  :metadata_lint,
  :lint,
  :syntax,
  :spec,
]

