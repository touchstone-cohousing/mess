# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!
require "pundit/rspec"
require "capybara-screenshot/rspec"
require "capybara/poltergeist"
require "vcr"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.include FactoryBot::Syntax::Methods
  config.include Warden::Test::Helpers
  config.include FeatureSpecHelpers, type: :feature
  config.include RequestSpecHelpers, type: :request
  config.include GeneralHelpers
  config.include ActionDispatch::TestProcess

  VCR.configure do |c|
    c.cassette_library_dir = 'spec/cassettes'
    c.hook_into :webmock
    c.ignore_localhost = true
    c.configure_rspec_metadata!
  end

  Capybara.configure do |config|
    config.always_include_port = true
    config.javascript_driver = :poltergeist
    config.app_host = "http://#{Settings.url.host}"
    config.server_port = Settings.url.port
  end

  # We use an around block here because we are using around blocks to set
  # subdomain and this needs to run first.
  config.around type: :request do |example|
    host!(Settings.url.host)
    example.run
  end

  # We have to set a default tenant to avoid NoTenantSet errors.
  # We also reset TZ to default in case previous spec changed it.
  Cluster.delete_all
  cluster = FactoryBot.create(:cluster, name: "Default")
  config.around do |example|
    Time.zone = "UTC"
    with_tenant(cluster) do
      example.run
    end
  end
end
