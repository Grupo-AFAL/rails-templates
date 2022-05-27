# frozen_string_literal: true

def engine_name
  Dir.pwd.split('/').last
end

def engine_name_path
  engine_name.gsub('-', '/')
end

def application
  "#{Dir.pwd}/spec/dummy/config/application.rb"
end

def add_view_component_gem
  append_file "#{Dir.pwd}/Gemfile", <<~'RUBY'
    gem 'view_component'
    gem 'view_component-contrib'
  RUBY

  inject_into_file application, before: 'Bundler.require(*Rails.groups)' do
    <<~'RUBY'
      require 'view_component'
    RUBY
  end

  say_status :info, '✅ ViewComponent gems added'
end

def configure_view_component_paths
  inject_into_file application, after: "config.generators.system_tests = nil\n" do
    <<~'RUBY'
      config.autoload_paths << Rails.root.parent.parent.join('app', 'components')
      config.view_component.preview_paths << Rails.root.parent.parent.join('app', 'components')
    RUBY
  end

  say_status :info, '✅ ViewComponent paths configured'
end

def add_application_view_component_class
  file "#{Dir.pwd}/app/components/#{engine_name_path}/application_view_component.rb", <<~'RUBY'
    # frozen_string_literal: true

    # TODO:
    # - Move this file to your correct namespace directory if necessary
    # - Add module according to your engine isolated namespace
    class ApplicationViewComponent < ViewComponentContrib::Base
      include HtmlElementHelper

      private

      def identifier
        @identifier ||= self.class.name.sub('::Component', '').underscore.split('/').join('--')
      end
    end
  RUBY

  say_status :info, '✅ ApplicationViewComponent class created'
end

def add_application_view_component_preview_class
  file "#{Dir.pwd}/app/components/#{engine_name_path}/application_view_component_preview.rb", <<~'RUBY'
    # frozen_string_literal: true

    # TODO:
    # - Move this file to your correct namespace directory if necessary
    # - Add module according to your engine isolated namespace
    class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
      self.abstract_class = true
    end
  RUBY

  say_status :info, '✅ ApplicationViewComponentPreview class created'
end

def add_view_component_initializer
  prepend_file "#{Dir.pwd}/lib/#{engine_name_path}/engine.rb", <<~'RUBY'
    # TODO: Make sure this file is inside your engine isolated namespace directory

    require 'view_component-contrib'
  RUBY

  inject_into_file "#{Dir.pwd}/lib/#{engine_name_path}/engine.rb",
                   after: "class Engine < ::Rails::Engine\n" do
    <<~'RUBY'
      config.eager_load_paths = %W[
        #{root}/app/components
        #{root}/app/lib
      ]

      config.generators do |g|
        g.test_framework :rspec, fixture: true
        g.view_specs      false
        g.routing_specs   false
        g.helper          false
      end

      ActiveSupport.on_load(:view_component) do
        ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
        ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract
      end

      initializer 'Add app/components to assets paths' do |app|
        app.config.assets.paths << "#{root}/app/components"
      end
    RUBY
  end

  say_status :info, '✅ ViewComponent initializer configured'
end

def configure_rspec
  append_file "#{Dir.pwd}/Gemfile", <<~'RUBY'
    gem 'capybara', group: :test
  RUBY

  gsub_file "#{Dir.pwd}/spec/rails_helper.rb",
            "require_relative '../config/environment'",
            "require File.expand_path('./dummy/config/environment', __dir__)"

  inject_into_file "#{Dir.pwd}/spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
    <<~'RUBY'
      config.include ViewComponent::TestHelpers, type: :component
      config.include Capybara::RSpecMatchers, type: :component
    RUBY
  end

  say_status :info, '✅ RSpec configured for ViewComponent tests'
end

def create_component_html_template
  file "#{Dir.pwd}/lib/generators/view_component/templates/component.html.erb.tt", <<~'TEXT'
    <%%= tag.div(**options) do %>
      <%%= content %>
    <%% end %>
  TEXT
end

def create_component_spec_template
  file "#{Dir.pwd}/lib/generators/view_component/templates/component_spec.rb.tt", <<~'TEXT'
    # frozen_string_literal: true

    require 'rails_helper'

    RSpec.describe <%= class_name %>::Component, type: :component do
      before do
        @options = { <%= attr_reader_test_parameters %> }
      end

      let(:component) { <%= class_name %>::Component.new(**@options) }

      subject { rendered_component }

      it 'renders <%= class_name.downcase %> component' do
        render_inline(component)

        expect(subject).to have_css 'div.<%= default_css_class %>'
      end
    end
  TEXT
end

def create_component_template
  file "#{Dir.pwd}/lib/generators/view_component/templates/component.rb.tt", <<~'TEXT'
    # frozen_string_literal: true

    module <%= class_name %>
      class Component < <%= parent_class %>
        <%- if initialize_instance_variables -%>
        attr_reader <%= attr_reader_parameters %>, :options
        <%- end -%>

        def initialize(<%= initialize_parameters %>, **options)
        <%- if initialize_instance_variables -%>
          <%= initialize_instance_variables %>
        <%- end -%>
          @options = prepend_class_name(options, '<%= default_css_class %>')
        end
      end
    end
  TEXT
end

def create_index_js_template
  file "#{Dir.pwd}/lib/generators/view_component/templates/index.js.tt", <<~'TEXT'
    import { Controller } from '@hotwired/stimulus'

    /**
    * <%= class_name %> Controller
    * Controller description goes here!
    *
    * How to use
    *
    * <div class="<%= default_css_class %>" data-controller="<%= class_name.downcase %>">
    *   <%= class_name %> template goes here
    * </div>
    */

    export class <%= class_name %>Controller extends Controller {
      connect() {
      }

      disconnect() {
      }
    }
  TEXT
end

def create_index_scss_template
  file "#{Dir.pwd}/lib/generators/view_component/templates/index.scss.tt", <<~'TEXT'
    .<%= default_css_class %> {
      // CSS goes here
    }
  TEXT
end

def create_preview_template
  file "#{Dir.pwd}/lib/generators/view_component/templates/preview.rb.tt", <<~'TEXT'
    # frozen_string_literal: true

    module <%= class_name %>
      class Preview < <%= preview_parent_class %>
        def default
          # Default preview goes here
        end
      end
    end
  TEXT
end

def create_stories_template
  file "#{Dir.pwd}/lib/generators/view_component/templates/stories.rb.tt", <<~'TEXT'
    # frozen_string_literal: true

    module <%= class_name %>
      class Stories < <%= stories_parent_class %>
        story :default do
          constructor
        end
      end
    end
  TEXT
end

def create_generator
  file "#{Dir.pwd}/lib/generators/view_component/view_component_generator.rb", <<~'RUBY'
    # frozen_string_literal: true

    # TODO: 
    # - Check all your templates lib/generators/view_component/templates
    # - Add module according to your engine isolated namespace where needed


    # Based on https://github.com/github/view_component/blob/master/lib/rails/generators/component/component_generator.rb
    class ViewComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      class_option :skip_test, type: :boolean, default: false
      class_option :skip_preview, type: :boolean, default: false
      class_option :skip_js, type: :boolean, default: false
      class_option :skip_scss, type: :boolean, default: false
      class_option :skip_stories, type: :boolean, default: false

      argument :attributes, type: :array, default: [], banner: 'attribute'

      def create_component_file
        template 'component.rb', File.join('app/components', class_path, file_name, 'component.rb')
      end

      def create_template_file
        template 'component.html.erb',
                File.join('app/components', class_path, file_name, 'component.html.erb')
      end

      def create_test_file
        return if options[:skip_test]

        template 'component_spec.rb', File.join('spec/components', class_path, "#{file_name}_spec.rb")
      end

      def create_preview_file
        return if options[:skip_preview]

        template 'preview.rb', File.join('app/components', class_path, file_name, 'preview.rb')
      end

      def create_scss_file
        return if options[:skip_scss] || options[:skip_js]

        template 'index.scss', File.join('app/components', class_path, file_name, 'index.scss')
      end

      def create_js_file
        return if options[:skip_js]

        template 'index.js', File.join('app/components', class_path, file_name, 'index.js')
      end

      def create_stories_file
        return if options[:skip_stories]

        template 'stories.rb', File.join('app/components', class_path, file_name, 'stories.rb')
      end

      private

      def parent_class
        'ApplicationViewComponent'
      end

      def preview_parent_class
        'ApplicationViewComponentPreview'
      end

      def stories_parent_class
        'ViewComponent::Storybook::Stories'
      end

      def default_css_class
        "#{file_name}-component"
      end

      def initialize_parameters
        return if attributes.blank?

        attributes.map { |attr| "#{attr.name}:" }.join(', ')
      end

      def initialize_instance_variables
        return if attributes.blank?

        attributes.map { |attr| "@#{attr.name} = #{attr.name}" }.join("\n      ")
      end

      def attr_reader_parameters
        attributes.map { |attr| ":#{attr.name}" }.join(', ')
      end

      def attr_reader_test_parameters
        attributes.map { |attr| "#{attr.name}: nil" }.join(', ')
      end
    end
  RUBY
end

def create_html_element_helper
  file "#{Dir.pwd}/app/lib/#{engine_name_path}/html_element_helper.rb", <<~'RUBY'
    # frozen_string_literal: true

    # TODO:
    # - Move this file to your correct namespace directory if necessary
    # - Add module according to your engine isolated namespace
    module HtmlElementHelper
      def prepend_action(options, action)
        prepend_data_attribute(options, :action, action)
      end

      def prepend_controller(options, controller_name)
        prepend_data_attribute(options, :controller, controller_name)
      end

      def prepend_class_name(options, class_name)
        options[:class] = "#{class_name} #{options[:class]}".strip
        options
      end

      def hyphenize_keys(options)
        options.transform_keys { |k| k.to_s.gsub('_', '-') }
      end

      private

      def prepend_data_attribute(options, attr_name, attr_value)
        options[:data] ||= {}
        options[:data][attr_name] = "#{attr_value} #{options[:data][attr_name]}".strip
        options
      end
    end
  RUBY
end

def create_view_component_generator
  create_component_html_template
  create_component_spec_template
  create_component_template
  create_index_js_template
  create_index_scss_template
  create_preview_template
  create_stories_template
  create_generator
  create_html_element_helper

  say_status :info, '✅ ViewComponent generator created'
end

def create_documentation
  file "#{Dir.pwd}/VIEW_COMPONENTS.md", <<~'TEXT'
    # View Components
    **GitHub repository:** https://github.com/github/view_component

    View Component library enables the creation of view_components and the integration with Rails

    ## View Component contrib
    **GitHub repository:** https://github.com/palkan/view_component-contrib

    View Component: extensions, examples and development tools

    This library provides us with several best practices, mainly organizing all component related files
    in a single folder to keep things organized.

    ## Workflow for generating new components

    ### Generate a new component
    `rails generate view_component Button label`

    This command will generate a `app/components/button` folder with the following files

    - component.html.erb
    - component.rb
    - index.scss
    - index.js
    - preview.rb
    - stories.rb

    > **_NOTE:_**  If you want to skip for example the index.js file, you can run `rails generate view_component Button label --skip_js` to skip it. Other options:  `--skip_test`, `--skip_preview`, `--skip_stories`, `--skip_scss`
    ## Best Practices

    - Every component should have a root CSS class of `[component-name]-component`
  TEXT
end

# --------------------------------------------------
#                       MAIN
# --------------------------------------------------

say_status :info, '💎 Starting ViewComponent setup..'

add_view_component_gem
configure_view_component_paths
add_application_view_component_class
add_application_view_component_preview_class
add_view_component_initializer
configure_rspec
create_view_component_generator
create_documentation

run 'bundle install'

say_status :info, '💎 ViewComponent setup finished. Solve TODOs to finish the setup successfully.'
