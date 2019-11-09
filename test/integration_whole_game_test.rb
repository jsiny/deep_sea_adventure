class DeepSeaTest < Minitest::Test
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