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
