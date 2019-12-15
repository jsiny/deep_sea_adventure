class SessionPersistence
  attr_reader :game

  def initialize(session)
    @session = session
    @game = session[:game]
  end

  def all_players
    @game.players
  end

  def round
    @game.round
  end

  def find_player(player_id)
    all_players[player_id]
  end

  def add_new_player
  end

  def find_round(round_id)
  end

  def reduce_oxygen
  end

  def save_round_info
  end

  def new_game
  end

  def new_round
  end

  def save_player_info
  end
end