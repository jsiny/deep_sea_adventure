def session
  last_request.env["rack.session"]
end

def players
  { "player1" => "archer", "player2" => "Lana", "player3" => "Malory",
    "player4" => "", "player5" => "", "player6" => "" }
end

def create_game(players)
  get '/new'
  post '/create', players
end

def game
  session[:game]
end

def player_turn(round_id, player_id, treasure, keep_diving = true, back = false)
  post "/round/#{round_id}/player/#{player_id}",
    { 'keep_diving' => keep_diving.to_s, 
      'treasure'    => treasure, 
      'back'        => back.to_s }
end

def end_round_when_players_back(round_id)
  3.times do |id|
    player_turn(round_id, id, 'add')
    player_turn(round_id, id, 'add', false)
    player_turn(round_id, id, 'none', false, true)
  end
end

def end_round_when_no_oxygen(round_id)
  4.times { player_turn(round_id, 0, 'add') }
  7.times { player_turn(round_id, 2, 'none') }
  player_turn(round_id, 0, 'none')
end

def end_round_no_oxygen_some_players_back(round_id)
  4.times { player_turn(round_id, 0, 'add') }
  
  # Player 1 adds a treasure and goes back up
  player_turn(round_id, 1, 'add')
  player_turn(round_id, 1, 'none', false)
  player_turn(round_id, 1, 'none', false, true)
  
  # Tank runs out of oxygen, players 0 and 2 drowned
  7.times { player_turn(round_id, 2, 'none') }

  # Last player turn is redirected to score view
  player_turn(round_id, 0, 'none')
end
