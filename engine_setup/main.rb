# frozen_string_literal: true

def run_template(file_name)
  location = "https://raw.githubusercontent.com/Grupo-AFAL/rails-templates/main/engine_setup/#{file_name}"
  run "rails app:app:template LOCATION='#{location}'"
end

puts "\n\n💎 Welcome to the Rails engine setup! 💎\n\n"

# Required
run_template('rspec.rb')
run_template('rubocop.rb')

# Optional
run_template('standardjs.rb') if yes?('Do you want to install StandardJS? [Y/n]')
