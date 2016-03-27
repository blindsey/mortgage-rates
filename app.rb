require 'sinatra'
require './rates'

get '/' do
  content_type 'text/plain'
  Rates.fetch(params['year']).join("\n")
end

get '/favicon.ico' do
  send_file 'favicon.ico'
end
