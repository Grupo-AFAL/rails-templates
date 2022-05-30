# frozen_string_literal: true

def git_ignore_cypress_directories
  append_file "#{Dir.pwd}/.gitignore", <<~'TEXT'
    /cypress/videos/
    /cypress/screenshots/
    /cypress/fixtures/example.json
  TEXT

  say_status :info, '✅ Cypress directories ignored'
end

def add_cypress_scripts
  gsub_file "#{Dir.pwd}/package.json", /"devDependencies": {\n/, <<~'JSON'
    "scripts": {
      "build": "yarn --cwd spec/dummy/ install && yarn --cwd spec/dummy/ build",
      "cy:open": "yarn build && cypress open",
      "cy:run": "yarn build && cypress run"
    },
    "devDependencies": {
  JSON

  say_status :info, '✅ Created cypress scripts to run tests'
end

def add_cypress_dependency
  run 'yarn add cypress -D'
  say_status :info, '✅ Cypress dependency added'
end

def add_esbuild_to_dummy
  run 'cd spec/dummy/ && rails javascript:install:esbuild && cd ../..'

  say_status :info, '✅ Esbuild installed'
end

def add_js_bundling_rails_gem
  append_file "#{Dir.pwd}/Gemfile", <<~'RUBY'
    gem 'jsbundling-rails', group: :development
  RUBY

  run 'bundle install'

  say_status :info, '✅ JS bundling Rails gem added'
end

def set_cypress_base_url
  file "#{Dir.pwd}/cypress.js", <<~'JSON'
    // TODO: Remove if not needed
    {
      "baseUrl": "http://localhost:3000/rails/view_components"
    }
  JSON

  say_status :info, '✅ Cypress Base URL set'
end

def git_ignore_dummy_node_modules_and_assets
  append_file "#{Dir.pwd}/.gitignore", <<~'TEXT'
    /spec/dummy/app/assets/builds/
    /spec/dummy/node_modules/
  TEXT

  say_status :info, '✅ Spec dummy files ignored'
end

def create_cypress_github_action
  file "#{Dir.pwd}/Procfile.dev", <<~'TEXT'
    web: bin/rails server -p 3000
    js: yarn cypress run
  TEXT

  file "#{Dir.pwd}/.github/workflows/cypress.yml", <<~'YML'
    name: Cypress Tests
    on: push

    jobs:
      cypress:
        runs-on: ubuntu-latest
        steps:
          - name: Checkout
            uses: actions/checkout@v3

          - name: Install ruby
            uses: ruby/setup-ruby@v1
            with:
              bundler-cache: true

          - name: Install foreman gem
            run: gem install foreman

          - name: Install yarn and build
            run: |
              npm install -g yarn
              yarn install
              yarn build
          - name: Start server and run tests
            run: foreman start -f Procfile.dev
  YML

  say_status :info, '✅ Cypress Github Action created'
end

def create_cypress_documentation
  file "#{Dir.pwd}/CYPRESS.md", <<~'TEXT'
    ## Cypress

    To run JavaScript tests:

    - Run `rails server`. The `http://localhost:3000/rails/view_components` has been configured as the baseUrl, and tests will fail if the server is not running
    - Run `yarn run cy:run` to run tests in the terminal
    - Or run `yarn run cy:open` to open the tests in the browser
  TEXT
end

# --------------------------------------------------
#                       MAIN
# --------------------------------------------------
say_status :info, '💎 Starting Cypress setup..'

add_cypress_dependency
add_esbuild_to_dummy
add_cypress_scripts
git_ignore_cypress_directories

add_js_bundling_rails_gem
set_cypress_base_url
git_ignore_dummy_node_modules_and_assets

create_cypress_github_action
create_cypress_documentation

say_status :info, '💎 Cypress setup finished!'
