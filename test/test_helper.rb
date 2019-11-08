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

def end_round_when_players_back(round_id)
  3.times do |id|
    post "/round/#{round_id}/player/#{id}", { 'keep_diving' => 'true', 
                                              'treasure'    => 'add' }
    post "/round/#{round_id}/player/#{id}", { 'keep_diving' => 'false',
                                              'treasure'    => 'add' }
    post "/round/#{round_id}/player/#{id}", { 'back'        => 'true',
                                              'treasure'    => 'none' }
  end
end

def end_round_when_no_oxygen(round_id)
  4.times do
    post "/round/#{round_id}/player/0", { 'keep_diving' => 'true', 
                                          'treasure'    => 'add' }
  end

  7.times do
    post "/round/#{round_id}/player/2", { 'keep_diving' => 'true',
                                          'treasure'    => 'none' }
  end

  post "/round/#{round_id}/player/0", { 'keep_diving' => 'true',
                                        'treasure'    => 'none' }
end
