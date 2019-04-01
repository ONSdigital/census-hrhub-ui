require 'sinatra'
require 'sinatra/content_for2'
require 'sinatra/flash'
require 'syslog/logger'
require 'will_paginate'
require 'will_paginate/array'
require 'rest_client'
require 'json'
require 'yaml'
require 'open-uri'
require 'sinatra/formkeeper'
require 'csv'

require_relative '../lib/authentication'
require_relative '../lib/core_ext/object'

PROGRAM = 'fsdr'.freeze

CENSUS_FSDR_HOST = ENV['CENSUS_FSDR_SERVICE_HOST'] || 'localhost'
CENSUS_FSDR_PORT = ENV['CENSUS_FSDR_SERVICE_PORT'] || '5678'

# Set global pagination options.
WillPaginate.per_page = 20

enable :sessions

# View helper for defining blocks inside views for rendering in templates.
helpers Sinatra::ContentFor2
helpers do

  # View helper for parsing and displaying JSON error responses.
  def error_flash(message, response)
    error = JSON.parse(response)
    if error['error']['timestamp']
      flash[:error] = "#{message}: #{error['error']['message']}<br>Please quote reference #{error['error']['timestamp']} when contacting support."
    elsif error['timestamp']
      flash[:error] = "#{message}: #{error['message']}<br>Please quote reference #{error['timestamp']} when contacting support."
    end
  end

  def error_flash_text(message, response)
    flash[:error] = "#{message}: #{response}"
  end

  # View helper for escaping HTML output.
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

SESSION_EXPIRATION_PERIOD = 60 * 1

# Expire sessions after SESSION_EXPIRATION_PERIOD of inactivity
use Rack::Session::Cookie, key: 'rack.session', path: '/',
                           secret: 'eb46fa947d8411e5996329c9ef0ba35d',
                           expire_after: SESSION_EXPIRATION_PERIOD

helpers Authentication

# Home page.
get '/' do
  authenticate!
  erb :index, locals: { title: 'Home' }
  fieldforce = []
  viewtype = session[:role]
  RestClient::Request.execute(method: :get,
                              url: 'http://' + CENSUS_FSDR_HOST + ':' + CENSUS_FSDR_PORT + "/fieldforce/#{viewtype}") do |fieldforce_response, _request, _result, &_block|
    unless fieldforce_response.empty?
      fieldforce = JSON.parse(fieldforce_response) unless fieldforce_response.code == 404
    end

    erb :field_force, locals: { title: 'Field Force view for: ' + viewtype.upcase,
                                fieldforce: fieldforce,
                                viewtype: viewtype }
  end
end

# Download file
get '/download' do
  authenticate!
  filetype_array = %w[fwmt lws]
  erb :download, layout: :layout, locals: { title: 'File Download',
                           filetype_array: filetype_array,
                           url: 'http://' + CENSUS_FSDR_HOST + ':' + CENSUS_FSDR_PORT }
end

# Search
get '/search' do
  authenticate!
  erb :search, locals: { title: 'Search' }
end

# Search Results
post '/searchresults' do
  authenticate!
  results = []
  RestClient::Request.execute(method: :get,
                               url: 'http://' + CENSUS_FSDR_HOST + ':' + CENSUS_FSDR_PORT + "/fieldforce/surname/#{params[:surname]}") do |fieldforce_response, _request, _result, &_block|
    results = JSON.parse(fieldforce_response) unless fieldforce_response.code == 404
    erb :searchresults, locals: { title: 'Search Results',
                                  results: results}
  end
end
