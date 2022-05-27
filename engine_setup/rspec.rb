# frozen_string_literal: true

def engine_name
  Dir.pwd.split('/').last
end

# --------------------------------------------------
#             RSpec github action setup
# --------------------------------------------------
def create_rspec_github_action
  file "#{Dir.pwd}/.github/workflows/rspec.yml", <<~'YML'
    name: RSpec Tests
    on:
      push:
        branches: [main]
      pull_request:
        branches: [main]
      workflow_call:
        secrets:
          CC_TEST_REPORTER_ID:
            description: 'Code Climate Reporter ID for current repo'
            required: false
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: amancevice/setup-code-climate@v0
            name: CodeClimate Install
            with:
              cc_test_reporter_id: ${{ secrets.CC_TEST_REPORTER_ID }}
          - name: Checkout code
            uses: actions/checkout@v3
          # Add or replace dependency steps here
          - name: Install Ruby and gems
            uses: ruby/setup-ruby@v1
            with:
              ruby-version: 3.1.2
              bundler-cache: true
          - name: CodeClimate Pre-build Notification
            run: cc-test-reporter before-build
          # Add or replace test runners here
          - name: Run RSpec
            run: bundle exec rspec spec/
          - name: CodeClimate Post-build Notification
            run: cc-test-reporter after-build -t simplecov -r ${{secrets.CC_TEST_REPORTER_ID}}
  YML
end

def add_simplecov
  append_file "#{Dir.pwd}/Gemfile", <<~'TEXT'
    gem 'simplecov', group: 'test'
  TEXT

  run 'bundle install'

  prepend_file "#{Dir.pwd}/spec/rails_helper.rb", <<~'RUBY'
    require 'simplecov'

    SimpleCov.start 'rails' do
      add_filter '/spec/'
    end
  RUBY
end

def git_ignore_rspec_coverage
  append_file "#{Dir.pwd}/.gitignore", <<~'TEXT'
    /coverage/
  TEXT
end

# --------------------------------------------------
#                 RSpec rails setup
# --------------------------------------------------

# rubocop:disable Metrics/MethodLength
def create_dummy_app
  # Create temporary engine to build the dummy app,
  # copy the dummy/spec/ directory to your current engine's root path
  # and remove the dummy engine
  run 'rails plugin new dummy --full --dummy-path=spec/dummy -T'
  run 'cp -r dummy/spec/. spec'
  run 'rm -rf dummy'

  append_file "#{Dir.pwd}/.gitignore", <<~'TEXT'
    /spec/dummy/db/*.sqlite3
    /spec/dummy/db/*.sqlite3-*
    /spec/dummy/log/*.log
    /spec/dummy/node_modules/
    /spec/dummy/storage/
    /spec/dummy/tmp/
    /spec/dummy/tmp/development_secret.txt
  TEXT

  gsub_file "#{Dir.pwd}/bin/rails", '../test/dummy/config/application', '../spec/dummy/config/application'
  gsub_file "#{Dir.pwd}/spec/dummy/config/application.rb", /require "dummy"/, "# require 'dummy'"
  gsub_file "#{Dir.pwd}/Rakefile", 'test/dummy/Rakefile', 'spec/dummy/Rakefile'
end
# rubocop:enable Metrics/MethodLength

def remove_test_dir
  run 'rm -rf test' if Dir.exist?('test')
  gsub_file "#{Dir.pwd}/.gitignore", %r{/test/dummy/.*}, ''
end

def add_dependencies_to_gemfile
  inject_into_file "#{Dir.pwd}/#{engine_name}.gemspec", after: "Gem::Specification.new do |spec|\n" do
    <<~'RUBY'
      spec.add_development_dependency 'rspec-rails'
    RUBY
  end
end

def add_rspec_rails_gem
  append_file "#{Dir.pwd}/Gemfile", <<~'TEXT'
    gem 'rspec-rails', '~> 5', group: [:development, :test]
  TEXT

  run 'bundle install'
end

# --------------------------------------------------
#                       MAIN
# --------------------------------------------------
puts "\n\nStarting RSpec setup..\n\n"

create_dummy_app
remove_test_dir
add_dependencies_to_gemfile
add_rspec_rails_gem
rails_command 'generate rspec:install'

puts('Creating Rspec Github Action...')
create_rspec_github_action
add_simplecov
git_ignore_rspec_coverage

puts "\n\nRSpec setup finished!\n\n"
