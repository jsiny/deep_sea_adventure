class DeepSeaTest < Minitest::Test
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
end