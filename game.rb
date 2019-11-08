class Game
  ROUNDS_NUMBER = 3

  attr_accessor :players, :round

  def initialize
    @players = []
    @remaining_rounds = ROUNDS_NUMBER
    @winner = nil
  end

  def add_player(name)
    players << Player.new(name)
  end

  def start
    @round = Round.new(players, 0)
    @remaining_rounds -= 1
  end

  def new_round(players, next_player_id)
    @round = Round.new(players, next_player_id)
    @remaining_rounds -= 1
  end
end
