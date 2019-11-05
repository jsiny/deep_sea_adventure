ENV["RACK_ENV"] = 'test'

require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'rack/test'

require_relative '../deep_sea.rb'

class DeepSeaTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def game_session
    { "rack.session" => { game: Game.new } }
  end

  def players
    { "player1" => "archer", "player2" => "Lana", "player3" => "Malory",
      "player4" => "", "player5" => "", "player6" => "" }
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
    post '/create', players, game_session
    assert_equal 302, last_response.status
    assert_equal "The following players will dive: Archer, Lana, Malory",
                  session[:message][:text]

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "It's Archer's turn"
  end

  def test_start_new_game_with_too_few_players
    players = { "player1" => "Archer", "player2" => "Lana" }

    post '/create', players, game_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "3 to 6 divers"
    assert_includes last_response.body, "class='alert alert-danger"
  end

  def test_start_new_game_with_too_many_players
    players = { "player1" => "Archer", "player2" => "Lana",
                "player3" => "Malory", "player4" => "Cheryl", 
                "player5" => "Pam", "player6" => "Dr. Krieger",
                "player7" => "Cyril" }

    post '/create', players, game_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "3 to 6 divers"
    assert_includes last_response.body, "class='alert alert-danger"
  end

  def test_access_first_round_page
    post '/create', players, game_session
    get '/round/1/player/0'
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<div class="progress"'
    assert_includes last_response.body, '<input type="radio" name="diving"'
    assert_includes last_response.body, '<input type="radio" name="treasure"'
    assert_includes last_response.body, 
                    "There are <strong>25</strong> slots of oxygen left"
    assert_includes last_response.body, 'aria-valuenow=0'
  end
end