class DeepSeaTest < Minitest::Test
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
end