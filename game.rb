class Game
  ROUNDS_NUMBER = 3

  attr_accessor :players, :round

  def initialize
    @players = []
    @remaining_rounds = ROUNDS_NUMBER
    @winner = nil
  end

  def add_player(name)
    self.players << Player.new(name)
  end

  def start
    @round = Round.new(players, 0)
  end
end
