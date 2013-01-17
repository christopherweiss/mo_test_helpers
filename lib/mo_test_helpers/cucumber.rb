require 'rspec/expectations'
require "watir-webdriver"
require 'capybara'
require "selenium-webdriver"
require 'pp'
require 'mo_test_helpers/selenium_helper'

puts "Running with engine: #{MoTestHelpers.cucumber_engine}"
puts "Running in CI: #{ENV['CI']}"
puts "Running Headless: #{ENV['HEADLESS']}"

# should we run headless? Careful, CI does this alone!
if ENV['HEADLESS'] and not ENV['CI']
  require 'headless'
  
  headless = Headless.new
  headless.start
  at_exit do
    headless.destroy
  end
end

# Validate the browser
MoTestHelpers::SeleniumHelper.validate_browser!

# see if we are running on MO CI Server
if ENV['CI'] and not ENV['SELENIUM_GRID_URL']
  puts "Running Cucumber in CI Mode."

  if MoTestHelpers.cucumber_engine == :capybara
    Capybara.app_host = @base_url
    Capybara.register_driver :selenium do |app|
      MoTestHelpers::SeleniumHelper.grid_capybara_browser(app)
    end
  else
    browser = MoTestHelpers::SeleniumHelper.grid_watir_browser
  end
else
  if MoTestHelpers.cucumber_engine == :capybara
    Capybara.register_driver :selenium do |app|
      MoTestHelpers::SeleniumHelper.capybara_browser(app)
    end
  else
    browser = MoTestHelpers::SeleniumHelper.watir_browser
  end
end

if MoTestHelpers.cucumber_engine == :capybara
  Capybara.server_port = ENV['SERVER_PORT'] || 3001
end  

# "before all"
Before do
  @base_url = if ENV['URL'] then ENV['URL'] else 'http://localhost:3000/' end
  if MoTestHelpers.cucumber_engine == :watir
    @browser = browser
    @browser.goto @base_url
  end
end

# "after all"
at_exit do
  if @browser
     unless ENV['STAY_OPEN']
       @browser.close
     end
  end
end
