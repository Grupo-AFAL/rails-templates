# frozen_string_literal: true

def create_rubocop_yml_configuration
  file "#{Dir.pwd}/.rubocop.yml", <<~'YML'
    require: rubocop-rails

    AllCops:
      TargetRubyVersion: 3.1.2
      NewCops: enable
      SuggestExtensions: false
      Exclude:
        - 'coverage/**/*'
        - 'log/*'
        - 'config/**/*'
        - 'public/**/*'
        - 'storage/**/*'
        - 'tmp/**/*'
        - 'script/**/*'
        - 'node_modules/**/*'
        - 'lib/tasks/bali_tasks.rake'
        - 'bin/**/*'
        - 'vendor/**/*'
        - 'spec/spec_helper.rb'
        - 'spec/dummy/bin/*'
        - 'spec/dummy/config/**/*'
        - 'spec/dummy/db/**/*'
        - !ruby/regexp /old_and_unused\.rb$/

    Gemspec/RequiredRubyVersion:
      Enabled: false

    Layout/LineLength:
      Max: 100

    Layout/SpaceBeforeBrackets:
      Enabled: false

    Metrics/ClassLength:
      Max: 150

    Metrics/CyclomaticComplexity:
      Max: 8

    Metrics/MethodLength:
      Max: 30

    Metrics/ParameterLists:
      Max: 6

    Metrics/PerceivedComplexity:
      Max: 10

    Style/Documentation:
      Enabled: false

    Style/HashEachMethods:
      Enabled: true

    Style/HashTransformKeys:
      Enabled: true

    Style/HashTransformValues:
      Enabled: true

    Style/Lambda:
      Enabled: false

    Rails:
      Enabled: true

    Rails/OutputSafety:
      Enabled: false

    Rails/SkipsModelValidations:
      Enabled: false

    Rails/HasAndBelongsToMany:
      Enabled: false

    Metrics/BlockLength:
      IgnoredMethods: ['describe', 'context', 'it', 'before', 'included']
      Exclude:
        - spec/*
        - lib/tasks/*

    Naming/VariableNumber:
      Enabled: false

    Naming/RescuedExceptionsVariableName:
      Enabled: false

    Lint/EmptyBlock:
      Exclude:
        - spec/**/*

    Lint/MissingSuper:
      Exclude:
        - app/components/**/*

    Style/RedundantBegin:
      Enabled: false
  YML
end

def add_rubocop_gems
  append_file "#{Dir.pwd}/Gemfile", <<~'TEXT'
    gem 'rubocop', '~> 1', require: false , group: :development
    gem 'rubocop-rails', '~> 2', group: :development
  TEXT

  run 'bundle install'
end

def create_rubocop_github_action
  file "#{Dir.pwd}/.github/workflows/rubocop.yml", <<~'YML'
    name: Rubocop
    on: push

    jobs:
      rubocop:
        name: Rubocop
        runs-on: ubuntu-latest

        steps:
          - uses: actions/checkout@v3
          - uses: ruby/setup-ruby@v1
            with:
              ruby-version: 3.1.2
              bundler-cache: true
          - run: bundle install
          - name: Rubocop
            run: bundle exec rubocop
  YML
end

# --------------------------------------------------
#                       MAIN
# --------------------------------------------------
puts "\n\nStarting Rubocop setup..\n\n"
add_rubocop_gems
create_rubocop_yml_configuration

puts('Creating Rubocop Github Action...')
create_rubocop_github_action

puts "\n\nRubocop setup finished!\n\n"
