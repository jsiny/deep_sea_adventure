class DeepSeaTest < Minitest::Test
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
end