def session
  last_request.env["rack.session"]
end

# def create_game
#   Game.new
# end

def game_session
  { "rack.session" => { game: Game.new } }
end



def players
  { "player1" => "archer", "player2" => "Lana", "player3" => "Malory",
    "player4" => "", "player5" => "", "player6" => "" }
end