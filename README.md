# rails-templates

## Engine setup
This setup template includes: 
- RSpec
- Rubocop

> **_NOTE:_** Github actions are included, remove them if not required.

### Steps
1. Create a new Rails Engine `rails plugin new my-engine-name --mountable`
2. Resolve TODO's from your `gemspec` file
3. Make sure the rake tasks from the engine’s dummy app are available under the app: namespace (Required for step 4)
4. Run main template for engine set up `rails app:app:template LOCATION='https://raw.githubusercontent.com/Grupo-AFAL/rails-templates/main/engine_setup/main.rb'`
