require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'securerandom'

require_relative 'game'

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

get '/' do
  erb :home
end

get '/new' do
  session[:game] = Game.new
  session[:message] = "Game successfully created!"
  erb :new
end