ENV['RACK_ENV'] = 'test'
gem "minitest"


require 'minitest/autorun'
require '../thermoserver.rb'
require 'rack/test'
require 'fileutils'
require 'tempfile'
require 'debugger'

VALID_CONFIG_JSON_ORIG = 'valid-backbedroom.config.json.orig'

STATUS_JSON = 'backbedroom.status.json'
CONFIG_JSON = 'backbedroom.config.json'

class ThermoserverTest < Minitest::Test
  include Rack::Test::Methods
  
  # used as a signling function into server to indicate debugging
  # makes it easy to cause the debugger to break only when hitting a line of code
  # when a specific test method is running

  def setup
    FileUtils.cp(VALID_CONFIG_JSON_ORIG, CONFIG_JSON)
    @config = Thermoserver::Configuration.new
    @api_key = @config.api_key
  end
  
  def teardown
    FileUtils.safe_unlink(CONFIG_JSON)
    raise if File.exist?(CONFIG_JSON)
  end

  def app
    Sinatra::Application
  end

  def test_api_alignment
    assert_equal @api_key, 'abc123def'
  end

  def test_get_config_file
    get "/api/#{@api_key}/file/#{CONFIG_JSON}"
    assert_equal 200, last_response.status, last_response.body
    assert_equal last_response.body, File::read(CONFIG_JSON)
  end

  def test_post_config_file
    filedata = File::read(CONFIG_JSON)
    filename = CONFIG_JSON
    FileUtils.safe_unlink(CONFIG_JSON)
    tempfile = Tempfile.new('config_json')
    tempfile.write(filedata)
    assert !File::exists?(CONFIG_JSON)
    assert File::exists?(tempfile.path)
    tempfile.rewind
    assert_equal filedata.size, tempfile.read.size
    upload_file = Rack::Test::UploadedFile.new(tempfile.path, "text/json")    
    post "/api/#{@api_key}/file/#{CONFIG_JSON}", "file" => upload_file
    assert_equal 200, last_response.status, last_response.body
    assert_equal filedata, File::read(CONFIG_JSON)
    tempfile.unlink
  end
  
  def test_post_config_file_with_no_data
    filedata = File::read(CONFIG_JSON)
    filename = CONFIG_JSON
    FileUtils.safe_unlink(CONFIG_JSON)
    begin
      assert !File.exist?(CONFIG_JSON)
      post "/api/#{@api_key}/file/#{CONFIG_JSON}"      
      assert_equal 400, last_response.status, last_response.body
      assert !File::exists?(CONFIG_JSON)
    ensure
      # delete file but ignore exception if file doesn't exist
      begin FileUtils.safe_unlink(CONFIG_JSON) rescue NameError ; end
      File::write(CONFIG_JSON, filedata)
    end
  end  
  
  def test_functional_config_change
    
  end

end