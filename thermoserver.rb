require 'rubygems'
require 'sinatra'
require 'json'
require 'fileutils'
#if ENV['RACK_ENV'] == 'testing'
  require 'debugger'
#end

module Thermoserver
  class Error < RuntimeError; end
  # set to true during debugging/testing for breakpoints etc
  @@dbg = false
  def self.debug?
    @@dbg
  end
  def self.debug(val)
    @@dbg=val
  end

  def self.dbg(msg)
    puts msg if Thermoserver::Debug.debug
  end
  SERVER_BOOT_FILE = 'boot-server.json'
  # TODO Load these values from a config file
  # class instance provides access to config data required to run server
  class Configuration
    attr_reader :port, :base_folder, :api_key
    
    def initialize(options = {})
      boot_file = options[:boot_file] || SERVER_BOOT_FILE
      @config = JSON.parse(IO.read(boot_file))
      @base_folder = @config["config"]["base_folder"] || raise(Thermoserver::Error.new("base_folder not found in server boot file"))
      @api_key = @config["config"]["api_key"] || raise(Thermoserver::Error.new("api_key not found in server boot file"))
      @port = @config["config"]["port"] || raise(Thermoserver::Error.new("port not found in server boot file"))
    end
  end

  def self.filename_is_safe?(filename)
    #checks on filename:
    #  there should be no path - just a filename
    #  filename should have no complex characters in it
    File::basename(filename)==filename && filename.match(/^[a-zA-Z0-9.]+$/)
  end

  # gets filename specified if it exists and the file requested
  # passes filename simplification rules
  # also filename is stripped of path information
  # returns hash structure with instructions and data
  # returns
  #   status => int (http response code)
  #   file => contents of file requested in string or nil if not authorized
  #   authorized? => true/false - must not proceed if false - return status code and status message to user
  #   status_message => string - error message to return to user explaining why no access
  def self.get_file(options)
    filename = options[:filename]
    base_folder = options[:base_folder] || raise(Thermoserver::Error.new("Base folder required in get_file"))
    rooted_filename = File::join(base_folder, filename)
    html_filename = URI::escape(filename)
    retval = {:authorized => false, :status => 500}
    # file must not contain path information, must exist and must have a simplified character set
    if filename_is_safe?(filename) && File::exists?(rooted_filename)
      File::open(rooted_filename) do |file|
        retval[:file] = file.read
        retval[:status] = 200
        retval[:authorized?] = true
      end
    else
      if File::basename(filename)!=filename
        retval[:status] = 403 # not authorized (re-auth won't help)
        retval[:status_message] = "File specified #{html_filename} contains impermissible path."
      elsif !File::exists?(rooted_filename)
        retval[:status] = 404 # not found
        retval[:status_message] = "File specified #{html_filename} does not exist."
      elsif !filename.match(/^[a-zA-Z0-9.]+$/)
        retval[:status] = 403
        retval[:status_message] = "File specified #{html_filename} contains invalid characters."
      else
        retval[:status] = 400 # Bad request / General denial
        retval[:status_message] = "File specified #{html_filename} cannot be obtained for unknown reasons."
      end
    end
    retval
  end

  def self.post_file(options)
    file = options[:file]
    filename = options[:filename]
    base_folder = options[:base_folder] || raise(Thermoserver::Error.new("Base folder required in post_file"))
    rooted_filename = File::join(base_folder, filename)
    html_filename = URI::escape(filename)
    retval = {:status_message => "Unknown error", :status => 500}
    if !file || file.size < 1
      retval[:status] = 400
      retval[:status_message] = "File data for file #{html_filename} provided is empty"
    elsif filename_is_safe?(filename)
      FileUtils.copy_file(file.path, rooted_filename)
      if File::exists?(rooted_filename)
        retval[:status] = 200
        retval[:status_message] = "File #{html_filename} uploaded successfully"
      else
        retval[:status] = 500
        retval[:status_message] = "Error writing file #{html_filename}"
      end
    else
      retval[:status] = 500
      retval[:status_message] = "Unknown error occurred when uploading file #{html_filename}"
    end
    retval
  end
end # Thermoserver

config = Thermoserver::Configuration.new
# used in testing
def debug!
  debugger if Thermoserver::debug?
end 
def debug(val)
  Thermoserver::debug(val)
end

# setup server
set :server, 'thin'
set :port, config.port

get "/api/#{config.api_key}/file/:thermoname" do
  filename = params[:thermoname]
  file_hash = Thermoserver::get_file(:filename=>filename, :base_folder => config.base_folder)
  retval = ""
  if file_hash[:authorized?]
    retval = file_hash[:file]
  else # not authorized
    retval = file_hash[:status_message]
    response.status = file_hash[:status]
  end
  retval
end

# expects a file uploaded under params key "file"
post "/api/#{config.api_key}/file/:thermoname" do
  filename = params[:thermoname]
  file = params[:file][:tempfile] if params[:file]
  file_hash = Thermoserver::post_file(:file=>file, :filename=>filename, :base_folder => config.base_folder)
  response.status = file_hash[:status]
  file_hash[:status_message] || ""
end

