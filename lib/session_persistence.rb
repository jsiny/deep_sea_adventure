class SessionPersistence
  def initialize(session)
    @session = session
    @game = session[:game]
  end

  # Returns an array of all the Players objects
  def all_players
    @game.players
  end

  def round
    @game.round
  end

  # Returns a Player object
  def find_player(player_id)
    all_players[player_id]
  end

  def add_players(names)
    names.each { |name| add_player(name) }
  end

  def add_player(name)
    all_players << Player.new(name)
  end

  def new_player_score(player_id, points)
    find_player(player_id).score = points
  end


  def new_round(next_player_id = 0)
    all_players.each(&:reset)
    @game.next_round(next_player_id)
  end

  def save_player_info(player_id, keep_diving, back, treasure)
    player = find_player(player_id)

    player.keep_diving = true if keep_diving == 'false'
    player.is_back     = true if back        == 'true'

    player.save_treasure(treasure)
  end

  def compute_and_save_score
    @game.compute_scores
  end

  def reduce_oxygen?(treasures)
    round.remaining_oxygen -= treasures unless treasures.zero?
  end

  # def find_round(round_id)
  # end

  # def new_game
  # end
end