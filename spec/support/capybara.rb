# frozen_string_literal: true
# Setup chrome headless driver
Capybara.server = :puma, { Silent: true }

Capybara.register_driver :chrome_headless do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :smoke_tests do |app|
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 120
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(accept_insecure_certs: true)
  options = ::Selenium::WebDriver::Chrome::Options.new
  # options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: client, desired_capabilities: capabilities)
end

Capybara.javascript_driver = :chrome_headless

# NOTE: This is probably break the other system specs. Figure out how to apply it selectively. 
Capybara.configure do |config|
    config.run_server = false
    config.default_driver = :smoke_tests
end

# Setup rspec
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :chrome_headless
  end
end
