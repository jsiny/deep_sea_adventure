require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'securerandom'

require_relative 'game'
require_relative 'player'

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

before do
  @game ||= session[:game] #if session[:game]
end

helpers do

  def message(text, style = 'success')
    session[:message] = { text: text, style: style }
  end
end

get '/' do
  erb :home
end

post '/new' do
  session[:game] = Game.new
  message("Game successfully created!")
  redirect '/new'
end

get '/new' do
  erb :new
end

post '/create' do
  # @game = Game.new
  @game.add_player(params[:player1])

  redirect '/'
end