require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'securerandom'

require_relative 'game'
require_relative 'player'
require_relative 'round'

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
  set :erb,            escape_html: true
end

before '/round/:round_id/*' do
  @round_id  = params[:round_id].to_i
  @round     = session[:game].round
end

before '/round/:round_id/player/:player_id' do
  @player_id = params[:player_id].to_i
  @player    = session[:game].players[@player_id]
  @players   = session[:game].players
end

helpers do
  def message(text, style = 'success')
    session[:message] = { text: text, style: style }
  end
end

def add_players(params)
  players = params.values.reject(&:empty?).map(&:capitalize)

  if (3..6).cover?(players.size)
    players.each { |name| session[:game].add_player(name) }
    message("The following players will dive: #{players.join(', ')}")
    session[:game].start
    redirect '/round/1/player/0'
  else
    message('You need 3 to 6 divers', 'danger')
    erb :new
  end
end

def reduce_oxygen(player)
  treasures = player.treasures
  alert = "#{player} has reduced the oxygen by #{treasures}"
  message(alert, 'warning') if @round.reduce_oxygen?(treasures)
end

# Homepage
get '/' do
  erb :home
end

# Enter players' name
get '/new' do
  session[:game] = Game.new
  message('Game successfully created!')
  erb :new
end

# Create new game
post '/create' do
  add_players(params)
end

# One player plays
get '/round/:round_id/player/:player_id' do
  erb :round
end

# Player submits form (diving/surface, treasure) &
# oxygen is reduced for next player
post '/round/:round_id/player/:player_id' do
  keep_diving = params[:dive]     # true / false (str)
  back        = params[:back]     # true / false (str)
  treasure    = params[:treasure] # add, remove, none

  @player.save_info(keep_diving, back, treasure)
  redirect '/round/1/score' if @round.over?

  next_player = @round.next_id(@player_id)
  reduce_oxygen(@players[next_player])
  redirect "/round/#{@round_id}/player/#{next_player}"
end

# Display round score
get '/round/:round_id/score' do
  erb :score
end
