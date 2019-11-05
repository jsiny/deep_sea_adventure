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
  set :erb, :escape_html => true
end

before do
  @game ||= session[:game]
end

helpers do
  def message(text, style = 'success')
    session[:message] = { text: text, style: style }
  end
end

def add_players(params)
  players = params.values.reject(&:empty?)

  if (3..6).cover?(players.size)
    players.each { |name| @game.add_player(name) }
    message("The following players will dive: #{players.join(', ')}")
    redirect '/'
  else
    message('You need 3 to 6 divers', 'danger')
    erb :new
  end
end

get '/' do
  erb :home
end

get '/new' do
  session[:game] = Game.new
  message('Game successfully created!')
  erb :new
end

post '/create' do
  add_players(params)
end

get '/oxygen' do
  erb :oxygen
end

get '/round' do
  @player = Player.new("test")
  # @player.going_up=(true)
  erb :round
end