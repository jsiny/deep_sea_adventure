ENV["RACK_ENV"] = 'test'

require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'rack/test'

require_relative '../deep_sea.rb'
require_relative 'test_helper.rb'

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
    player_turn(1, 2, 'add')
    assert_includes last_response.headers['Location'], '/round/1/player/3'

    player_turn(1, 3, 'add')
    assert_includes last_response.headers['Location'], '/round/1/player/4'

    player_turn(1, 4, 'add')
    assert_includes last_response.headers['Location'], '/round/1/player/5'

    player_turn(1, 5, 'add')
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
    assert_equal 2, game.remaining_rounds
  end

  def test_send_first_player_turn
    create_game(players)

    player_turn(1, 0, 'add')
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[0].treasures
    assert_equal false, game.players[0].going_up

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "It's Lana's turn"
    assert_equal 2, game.remaining_rounds
  end

  def test_player_takes_no_treasure
    create_game(players)

    player_turn(1, 1, 'none')
    assert_equal 302,   last_response.status
    assert_equal 0,     game.players[1].treasures
    assert_equal false, game.players[1].going_up
  end

  def test_player_takes_and_leaves_treasures
    create_game(players)

    player_turn(1, 2, 'add')
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[2].treasures
    assert_equal false, game.players[2].going_up

    player_turn(1, 2, 'add', false)
    assert_equal 302,   last_response.status
    assert_equal 2,     game.players[2].treasures

    player_turn(1, 2, 'remove', false, false)
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[2].treasures
    assert_equal false, game.players[2].is_back

    player_turn(1, 2, 'none', false, true)
    assert_equal 302,   last_response.status
    assert_equal 1,     game.players[2].treasures
    assert_equal true,  game.players[2].is_back
  end

  def test_player_treasure_persists
    create_game(players)

    player_turn(1, 2, 'add')
    assert_equal 1,     game.players[2].treasures

    player_turn(1, 0, 'none')
    assert_equal 1,     game.players[2].treasures
    assert_equal 0,     game.players[0].treasures
  end

  def test_correct_redirection_player_turn
    create_game(players)

    player_turn(1, 1, 'add')
    assert_includes last_response.headers['Location'], '/round/1/player/2'

    get last_response.headers['Location']
    assert 200, last_response.status
    assert_includes last_response.body, "It's Malory's turn!"

    player_turn(1, 2, 'add')
    assert_includes last_response.headers['Location'], '/round/1/player/0'

    get last_response.headers['Location']
    assert 200, last_response.status
    assert_includes last_response.body, "It's Archer's turn!"
  end

  def test_redirection_when_player_back
    create_game(players)

    player_turn(1, 1, 'add')
    player_turn(1, 1, 'add', false)
    player_turn(1, 1, 'none', false, true)

    player_turn(1, 0, 'add')
    assert_includes last_response.headers['Location'], '/round/1/player/2'
  end

  def test_redirection_when_only_player_left
    create_game(players)

    player_turn(1, 1, 'add')
    player_turn(1, 1, 'add', false)
    player_turn(1, 1, 'none', false, true)

    player_turn(1, 2, 'add')
    player_turn(1, 2, 'add', false)
    player_turn(1, 2, 'none', false, true)

    player_turn(1, 0, 'add')
    assert_includes last_response.headers['Location'], '/round/1/player/0'
  end

  def test_display_oxygen_alert
    create_game(players)

    player_turn(1, 1, 'add')

    get '/round/1/player/2'
    refute_includes last_response.body, "Lana has reduced the oxygen by 1"

    player_turn(1, 0, 'none')
    get '/round/1/player/1'
    assert_includes last_response.body, "Lana has reduced the oxygen by 1"

    player_turn(1, 1, 'remove')
    player_turn(1, 0, 'none')

    get '/round/1/player/1'
    refute_includes last_response.body, "Lana has reduced the oxygen by 1"
  end

  def test_back_and_forth_browser_does_not_affect_oxygen
    create_game(players)

    player_turn(1, 1, 'add')
    player_turn(1, 0, 'none')
    get '/round/1/player/1'
    assert_includes last_response.body, "aria-valuenow=1"
    
    get '/round/1/player/0'
    get '/round/1/player/1'
    assert_includes last_response.body, "aria-valuenow=1"
  end

  def test_finish_round_players_back
    create_game(players)
    end_round_when_players_back(1)

    assert_includes last_response.headers['Location'], '/round/1/score'
    assert_equal 2, game.remaining_rounds
  end

  def test_finish_round_no_more_oxygen
    create_game(players)

    4.times { player_turn(1, 0, 'add') }
    6.times { player_turn(1, 2, 'none') }

    get '/round/1/player/0'
    assert_includes last_response.body, "1</strong> slots of oxygen left"

    player_turn(1, 2, 'none')
    get '/round/1/player/0'
    assert_includes last_response.body, "0</strong> slots of oxygen left"

    player_turn(1, 0, 'none')
    assert_includes last_response.headers['Location'], '/round/1/score'
  end

  def test_access_round_score_players_all_back
    create_game(players)
    end_round_when_players_back(1)
    
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/1/score'

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Round 1 - Score"
    refute_includes last_response.body, "Divers who drowned"
    assert_includes last_response.body, "Add score for the divers"
    assert_includes last_response.body, '<label for="player_2"'
    assert_includes last_response.body, '<option value="0">Archer'
    assert_includes last_response.body, "<button type='submit'"
  end

  def test_access_round_score_no_more_oxygen
    create_game(players)
    end_round_when_no_oxygen(1)

    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/1/score'

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Round 1 - Score"
    assert_includes last_response.body, "Divers who drowned"
    assert_includes last_response.body, "<td>Archer</td>"
    assert_includes last_response.body, "<td>0 points</td>"
    refute_includes last_response.body, "Add score for the divers"
    refute_includes last_response.body, '<label for="player_2"'
    assert_includes last_response.body, '<option value="0">Archer'
    assert_includes last_response.body, "<button type='submit'"
  end

  def test_access_round_score_no_more_oxygen_some_players_back
    create_game(players)
    end_round_no_oxygen_some_players_back(1)

    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/1/score'
    
    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Round 1 - Score"

    # Only Archer and Malory drowned
    assert_includes last_response.body, "Divers who drowned"
    assert_includes last_response.body, "<td>Archer</td>"
    assert_includes last_response.body, "<td>Malory</td>"
    refute_includes last_response.body, "<td>Lana</td>"
    assert_includes last_response.body, "<td>0 points</td>"

    # Score can only be added to Lana
    assert_includes last_response.body, "Add score for the divers"
    refute_includes last_response.body, '<label for="player_2"'
    refute_includes last_response.body, '<label for="player_0"'
    assert_includes last_response.body, '<label for="player_1"'

    # Only Archer and Malory can be selected for next player
    assert_includes last_response.body, '<option value="0">Archer'
    assert_includes last_response.body, '<option value="2">Malory'
    refute_includes last_response.body, '<option value="1">Lana'

    assert_includes last_response.body, "<button type='submit'"
  end

  def test_save_info_end_of_round_players_back
    create_game(players)
    end_round_when_players_back(1)

    post '/round/1/save', { 'next_player' => '1', 'player_0' => '3',
                            'player_1'    => '2', 'player_2' => '1' }

    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/2/player/1'

    assert_equal 3, game.players[0].score
    assert_equal 2, game.players[1].score
    assert_equal 1, game.players[2].score
    
    3.times do |id|
      assert_equal false, game.players[id].going_up
      assert_equal false, game.players[id].is_back
      assert_equal 0,     game.players[id].treasures
    end

    assert_equal game.players[1], game.round.next_player
    assert_equal 1, game.remaining_rounds
  end

  def test_save_info_end_of_round_no_oxygen
    create_game(players)
    end_round_when_no_oxygen(1)

    post '/round/1/save', { 'next_player' => '2' }
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/2/player/2'
    assert_equal "Round 2 has started!", session[:message][:text]

    3.times do |id|
      assert_equal false, game.players[id].going_up
      assert_equal false, game.players[id].is_back
      assert_equal 0,     game.players[id].treasures
      assert_equal 0,     game.players[id].score
    end

    assert_equal game.players[2], game.round.next_player
    assert_equal 1, game.remaining_rounds
  end

  def test_save_info_oxygen_left_some_players_back
    create_game(players)
    end_round_no_oxygen_some_players_back(1)
    post '/round/1/save', { 'next_player' => '2', 'player_1' => '4' }

    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/2/player/2'

    assert_equal 0, game.players[0].score
    assert_equal 4, game.players[1].score
    assert_equal 0, game.players[2].score

    3.times do |id|
      assert_equal false, game.players[id].going_up
      assert_equal false, game.players[id].is_back
      assert_equal 0,     game.players[id].treasures
    end
  end

  def test_no_next_player_form_round_3
    create_game(players)
    end_round_no_oxygen_some_players_back(3)
    assert_equal 302, last_response.status

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    refute_includes last_response.body, "Who's the next player?"
    refute_includes last_response.body, '<option value="0">Archer'
    refute_includes last_response.body, '<option value="1">Lana'
    refute_includes last_response.body, '<option value="2">Malory'
  end

  def test_next_button_all_drowned_round_3
    create_game(players)
    end_round_when_no_oxygen(3)
    assert_equal 302, last_response.status

    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'href="/end"'
    refute_includes last_response.body, "<button type='submit'"
  end

  def test_whole_game
    create_game(players)

    # ---- First round ----
    end_round_when_players_back(1)
    assert_equal 302, last_response.status

    get last_response.headers['Location']
    assert_equal 200, last_response.status

    post '/round/1/save', { 'next_player' => '2', 'player_0' => '4',
                            'player_1'    => '5', 'player_2' => '1' }
    
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/2/player/2'
    assert_equal game.players[2], game.round.next_player

    assert_equal 4, game.players[0].score
    assert_equal 5, game.players[1].score
    assert_equal 1, game.players[2].score
    
    3.times do |id|
      assert_equal false, game.players[id].going_up
      assert_equal false, game.players[id].is_back
      assert_equal 0,     game.players[id].treasures
    end

    assert_equal 1, game.remaining_rounds

    # ---- Second round ----
    end_round_when_players_back(2)
    assert_equal 302, last_response.status

    get last_response.headers['Location']
    assert_equal 200, last_response.status

    post '/round/2/save', { 'next_player' => '1', 'player_0' => '4',
                            'player_1'    => '5', 'player_2' => '1' }

    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/round/3/player/1'
    assert_equal game.players[1], game.round.next_player

    assert_equal 4, game.players[0].score
    assert_equal 5, game.players[1].score
    assert_equal 1, game.players[2].score
   
    3.times do |id|
      assert_equal false, game.players[id].going_up
      assert_equal false, game.players[id].is_back
      assert_equal 0,     game.players[id].treasures
    end

    assert_equal 0, game.remaining_rounds

    # ---- Third round ----
    end_round_no_oxygen_some_players_back(3)
    assert_equal 302, last_response.status

    get last_response.headers['Location']
    assert_equal 200, last_response.status

    post '/round/3/save', { 'next_player' => '0', 'player_0' => '4',
                            'player_1'    => '7', 'player_2' => '1' }
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/end'
    
    assert_equal 4, game.players[0].score
    assert_equal 7, game.players[1].score
    assert_equal 1, game.players[2].score

    # ---- End ----
    get last_response.headers['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "End of the Game"
    assert_includes last_response.body, "<p>Lana</p>"
    assert_includes last_response.body, "<td>Lana</td>\n          <td>7 points</td>"
    assert_includes last_response.body, "<td>Archer</td>\n          <td>4 points</td>"
    assert_includes last_response.body, "<td>Malory</td>\n          <td>1 points</td>"
    assert_includes last_response.body, 'href="/new">'
  end
end