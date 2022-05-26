# frozen_string_literal: true

def create_standard_js_github_action
  run 'touch .github/workflows/standardjs.yml'

  append_file "#{Dir.pwd}/.github/workflows/standardjs.yml", <<~'YML'
    name: StandardJS
    on: push

    jobs:
      standardjs:
        name: StandardJS
        runs-on: ubuntu-latest

        steps:
          - uses: actions/checkout@v2
          - uses: actions/setup-node@v1
            with:
              node-version: 16.x

          - run: npm install
          - run: npm exec standard
  YML
end

def create_babel_config_json
  run 'touch .babel.config.json' unless File.exist?('.babel.config.json')
  append_file "#{Dir.pwd}/.babel.config.json", <<~'JSON'
    {
      "presets": [
        [
          "@babel/preset-env"
        ]
      ],
      "plugins": [
        "@babel/plugin-proposal-class-properties"
      ]
    }
  JSON
end

def add_standard_and_babel_dependencies
  run 'yarn add @babel/core -D'
  run 'yarn add @babel/eslint-parser -D'
  run 'yarn add @babel/plugin-proposal-class-properties -D'
  run 'yarn add @babel/preset-env -D'
  run 'yarn add standard -D'
end

def set_stantard_parser_and_globals
  gsub_file "#{Dir.pwd}/package.json", /"devDependencies": {/, <<~'JSON'
    "standard": {
      "parser": "@babel/eslint-parser",
      "globals": [
        "cy",
        "it",
        "context",
        "describe",
        "beforeEach",
        "Cypress",
        "fetch",
        "history",
        "FormData",
        "CustomEvent"
      ]
    },
    "devDependencies": {
  JSON
end

def git_ignore_node_modules
  append_file "#{Dir.pwd}/.gitignore", <<~'TEXT'
    /node_modules
  TEXT
end

# --------------------------------------------------
#                       MAIN
# --------------------------------------------------
puts "\n\nStarting Standard JS setup..\n\n"

add_standard_and_babel_dependencies
set_stantard_parser_and_globals
create_babel_config_json
git_ignore_node_modules

puts('Creating Standard JS Github Action...')
create_standard_js_github_action

puts "\n\nStandard JS setup finished!\n\n"
