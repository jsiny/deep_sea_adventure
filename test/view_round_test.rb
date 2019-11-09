class DeepSeaTest < Minitest::Test
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
end