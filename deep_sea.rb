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
  @players   = session[:game].players
end

before '/round/:round_id/player/:player_id' do
  @player_id = params[:player_id].to_i
  @player    = session[:game].players[@player_id]
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
    session[:game].next_round
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

def save_round_info(params)
  @players.each_with_index do |player, id|
    next unless player.is_back

    player_id = "player_#{id}".to_sym
    points = params[player_id].to_i
    player.new_score(points)
  end
end

def start_next_round(params)
  @players.each(&:reset)
  next_player = params[:next_player].to_i
  session[:game].next_round(next_player)
  next_round_id = @round_id + 1
  message("Round #{next_round_id} has started!")
  redirect "/round/#{next_round_id}/player/#{next_player}"
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
  redirect "/round/#{@round_id}/score" if @round.over?

  next_player = @round.next_id(@player_id)
  reduce_oxygen(@players[next_player])
  redirect "/round/#{@round_id}/player/#{next_player}"
end

# Display round score
get '/round/:round_id/score' do
  erb :score
end

# Save end of round info (score & next player)
post '/round/:round_id/save' do
  save_round_info(params)
  start_next_round(params) unless @round_id == 3
  redirect '/end'
end

# Access scoreboard and winner announcement
get '/end' do
  message("The 3 rounds are over!")
  session[:game].compute_scores
  erb :end
end
