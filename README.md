# rails-templates

## Engine setup

This setup template includes:

- [RSpec](https://rspec.info/)
- [Rubocop](https://rubocop.org/)
- [StandardJS](https://standardjs.com/)
- [ViewComponent](https://viewcomponent.org/)
- [Cypress](https://docs.cypress.io/)

> **_NOTE:_** Review the code before running this template on your machine.

### Usage

1. Create a new Rails Engine
   ```
   rails plugin new my-engine-name --mountable
   ```
2. Resolve TODO's from your `gemspec` file
3. Make sure the rake tasks from the engine’s dummy app are available under the app: namespace (Required for step 4)
4. Run this command in your Rails engine directory
   ```
   rails app:app:template LOCATION='https://raw.githubusercontent.com/Grupo-AFAL/rails-templates/main/engine_setup/main.rb'
   ```
