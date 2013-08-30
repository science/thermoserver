ENV['RACK_ENV'] = 'test'
gem "minitest"


require 'minitest/autorun'
require '../thermoserver.rb'
require 'rack/test'
require 'fileutils'

VALID_CONFIG_JSON_ORIG = 'valid-backbedroom.config.json.orig'

STATUS_JSON = 'backbedroom.status.json'
CONFIG_JSON = 'backbedroom.config.json'


class ThermoserverTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.cp(VALID_CONFIG_JSON_ORIG, CONFIG_JSON)
  end
  
  def teardown
    FileUtils.safe_unlink(CONFIG_JSON)
    raise if File.exist?(CONFIG_JSON)
  end

  def app
    Sinatra::Application
  end

  def test_get_status_file
    api_key = Thermoserver::API_KEY
    assert_equal api_key, 'abc123'
    get "/api/#{api_key}/download/status/#{STATUS_JSON}"
    assert_equal last_response.body, ""
    assert last_response.ok?
  end
  
  def test_get_config_file
    api_key = Thermoserver::API_KEY
    assert_equal api_key, 'abc123'
    get "/api/#{api_key}/download/config/#{CONFIG_JSON}"
    assert last_response.ok?
    assert_equal last_response.body, File::read(CONFIG_JSON)
  end

  def test_put_status_file
    
  end

  def test_put_config_file
    
  end
  
  def test_functional_config_change
    
  end

  def test_it_says_hello_world
    get '/'
    assert last_response.ok?
    assert_equal 'Hello', last_response.body
  end

end