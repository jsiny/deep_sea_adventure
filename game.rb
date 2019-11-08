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

  def next_round(next_player_id = 0)
    @round = Round.new(@players, next_player_id)
    @remaining_rounds -= 1
  end
end
