ENV["RACK_ENV"] = 'test'

require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'rack/test'

require_relative '../deep_sea.rb'
require_relative 'test_helper.rb'

require 'pry'

class DeepSeaTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_access_homepage
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "Deep Sea Adventure"
    assert_includes last_response.body, '<a class="btn btn-outline-primary"'
  end

  def test_access_new_game
    get '/new'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Set Up New Game"
    assert_includes last_response.body, "<form action='/create' method='post'"
  end

  def test_start_successful_new_game
    create_game(players)
    assert_equal 302, last_response.status
    assert_equal "The following players will dive: Archer, Lana, Malory",
                  session[:message][:text]

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "It's Archer's turn"
  end

  def test_start_new_game_with_too_few_players
    players = { "player1" => "Archer", "player2" => "Lana" }
    create_game(players)
    assert_equal 200, last_response.status
    assert_includes last_response.body, "3 to 6 divers"
    assert_includes last_response.body, "class='alert alert-danger"
  end

  def test_start_new_game_with_too_many_players
    players = { "player1" => "Archer", "player2" => "Lana",
                "player3" => "Malory", "player4" => "Cheryl", 
                "player5" => "Pam", "player6" => "Dr. Krieger",
                "player7" => "Cyril" }

    create_game(players)
    assert_equal 200, last_response.status
    assert_includes last_response.body, "3 to 6 divers"
    assert_includes last_response.body, "class='alert alert-danger"
  end

  def test_game_with_six_players
    players = { "player1" => "Archer", "player2" => "Lana",
                "player3" => "Malory", "player4" => "Cheryl", 
                "player5" => "Pam", "player6" => "Krieger" }

    create_game(players)
    post '/round/1/player/2', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/3'

    post '/round/1/player/3', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/4'

    post '/round/1/player/4', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/5'

    post '/round/1/player/5', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/0'

    players.values.each do |name|
      assert_includes game.players.join("\n"), name
    end
  end

  def test_access_first_round_page
    create_game(players)
    assert_equal 302, last_response.status

    get last_response.headers['Location']
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<div class="progress"'
    assert_includes last_response.body, '<input type="radio" name="dive"'
    assert_includes last_response.body, '<input type="radio" name="treasure"'
    assert_includes last_response.body, 
                    "There are <strong>25</strong> slots of oxygen left"
    assert_includes last_response.body, 'aria-valuenow=0'
  end

  def test_send_first_player_turn
    create_game(players)
    post '/round/1/player/0', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[0].treasures
    assert_equal false, game.players[0].going_up

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "It's Lana's turn"
  end

  def test_player_takes_no_treasure
    create_game(players)

    post '/round/1/player/1', { 'keep_diving' => 'true', 'treasure' => 'none' }
    assert_equal 302,   last_response.status
    assert_equal 0,     game.players[1].treasures
    assert_equal false, game.players[1].going_up
  end

  def test_player_takes_and_leaves_treasures
    create_game(players)

    post '/round/1/player/2', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[2].treasures
    assert_equal false, game.players[2].going_up

    post '/round/1/player/2', { 'keep_diving' => 'false', 'treasure' => 'add' }
    assert_equal 302,   last_response.status
    assert_equal 2,     game.players[2].treasures

    post '/round/1/player/2', { 'back' => 'false', 'treasure' => 'remove' }
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[2].treasures
    assert_equal false, game.players[2].is_back

    post '/round/1/player/2', { 'back' => 'true', 'treasure' => 'none' }
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[2].treasures
    assert_equal true,  game.players[2].is_back
  end

  def test_player_treasure_persists
    create_game(players)

    post '/round/1/player/2', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_equal 1,     game.players[2].treasures

    post '/round/1/player/0', { 'keep_diving' => 'true', 'treasure' => 'none' }
    assert_equal 1,     game.players[2].treasures
    assert_equal 0,     game.players[0].treasures
  end

  def test_correct_redirection_player_turn
    create_game(players)

    post '/round/1/player/1', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/2'

    get last_response.headers['Location']
    assert 200, last_response.status
    assert_includes last_response.body, "It's Malory's turn!"

    post '/round/1/player/2', { 'keep_diving' => 'true', 'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/0'

    get last_response.headers['Location']
    assert 200, last_response.status
    assert_includes last_response.body, "It's Archer's turn!"
  end

  def test_redirection_when_player_back
    create_game(players)

    post '/round/1/player/1', { 'keep_diving' => 'true',  'treasure' => 'add' }
    post '/round/1/player/1', { 'keep_diving' => 'false', 'treasure' => 'add' }
    post '/round/1/player/1', { 'back'        => 'true',  'treasure' => 'none' }

    post '/round/1/player/0', { 'keep_diving' => 'true',  'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/2'
  end

  def test_redirection_when_only_player_left
    create_game(players)

    post '/round/1/player/1', { 'keep_diving' => 'true',  'treasure' => 'add' }
    post '/round/1/player/1', { 'keep_diving' => 'false', 'treasure' => 'add' }
    post '/round/1/player/1', { 'back'        => 'true',  'treasure' => 'none' }

    post '/round/1/player/2', { 'keep_diving' => 'true',  'treasure' => 'add' }
    post '/round/1/player/2', { 'keep_diving' => 'false', 'treasure' => 'add' }
    post '/round/1/player/2', { 'back'        => 'true',  'treasure' => 'none' }

    post '/round/1/player/0', { 'keep_diving' => 'true',  'treasure' => 'add' }
    assert_includes last_response.headers['Location'], '/round/1/player/0'
  end

  def test_display_oxygen_alert
    create_game(players)

    post '/round/1/player/1', { 'keep_diving' => 'true', 'treasure' => 'add' }

    get '/round/1/player/2'
    refute_includes last_response.body, "Lana has reduced the oxygen by 1"

    post '/round/1/player/0', { 'keep_diving' => 'true', 'treasure' => 'none' }
    get '/round/1/player/1'
    assert_includes last_response.body, "Lana has reduced the oxygen by 1"

    post '/round/1/player/1', { 'keep_diving' => 'true', 'treasure' => 'remove' }
    post '/round/1/player/0', { 'keep_diving' => 'true', 'treasure' => 'none' }
    get '/round/1/player/1'
    refute_includes last_response.body, "Lana has reduced the oxygen by 1"
  end

  def test_finish_round_players_back
    create_game(players)

    3.times do |id|
      post "/round/1/player/#{id}", { 'keep_diving' => 'true',  'treasure' => 'add' }
      post "/round/1/player/#{id}", { 'keep_diving' => 'false', 'treasure' => 'add' }
      post "/round/1/player/#{id}", { 'back'        => 'true',  'treasure' => 'none' }
    end

    assert_includes last_response.headers['Location'], '/round/1/score'
  end

  def test_finish_round_no_more_oxygen
    create_game(players)

    4.times do
      post '/round/1/player/0', { 'keep_diving' => 'true',  'treasure' => 'add' }
    end

    6.times do
      post '/round/1/player/2', { 'keep_diving' => 'true',  'treasure' => 'none' }
    end

    get '/round/1/player/0'
    assert_includes last_response.body, "1</strong> slots of oxygen left"

    post '/round/1/player/2', { 'keep_diving' => 'true',  'treasure' => 'none' }
    get '/round/1/player/0'
    assert_includes last_response.body, "0</strong> slots of oxygen left"

    post '/round/1/player/0', { 'keep_diving' => 'true',  'treasure' => 'none' }
    assert_includes last_response.headers['Location'], '/round/1/score'
  end

  def test_back_and_forth_browser_does_not_affect_oxygen
    create_game(players)

    post '/round/1/player/1', { 'keep_diving' => 'true', 'treasure' => 'add' }

    post '/round/1/player/0', { 'keep_diving' => 'true', 'treasure' => 'none' }
    get '/round/1/player/1'
    assert_includes last_response.body, "aria-valuenow=1"
    
    get '/round/1/player/0'
    get '/round/1/player/1'
    assert_includes last_response.body, "aria-valuenow=1"
  end
end