require 'rubygems'
require 'sinatra'

set :server, 'thin'
set :port, 8080

module Thermoserver
  # TODO Load these values from a config file
  API_KEY = 'abc123'
end

get "/api/#{Thermoserver::API_KEY}/download/status/:thermoname" do

  ""
end

get "/api/#{Thermoserver::API_KEY}/download/config/:thermoname" do
  filename = params[:thermoname]
  retval = ""
  if File::exists?(filename) && filename.match(/^[a-zA-Z0-9.]+$/)
    File::open(filename) do |config_file|
      retval = config_file.read
    end
  else
    status 404
    if File::exists?(filename)
      retval = "File specified #{filename} does not exist."
    elsif filename.match(/^[a-zA-Z0-9.]+$/)
      retval = "File specified #{filename} contains invalid characters."
    else
      retval = "File specified #{filename} cannot be obtained for unknown reasons."
    end
  end
  retval
end

get '/' do
  "Hello"
end
