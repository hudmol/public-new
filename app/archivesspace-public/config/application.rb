require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

require_relative 'initializers/plugins'

# Maybe we won't need these?

# DISABLED BY MST # require 'active_record/railtie'
# DISABLED BY MST # require 'action_mailer/railtie'
# DISABLED BY MST # require 'active_job/railtie'
# DISABLED BY MST # require 'action_cable/engine'
# DISABLED BY MST # require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ArchivesspacePublic
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # we require the app_config module in order to access the directory value from the :custom key
    require "#{Rails.root}/app/lib/app_config.rb"
    config.i18n.load_path += Dir[File.join(Rails.root, AppConfig[:custom], 'locales', '**' , '*.{rb,yml}')]
  end
end

Plugins::init
