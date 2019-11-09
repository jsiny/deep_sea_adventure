class DeepSeaTest < Minitest::Test
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
end