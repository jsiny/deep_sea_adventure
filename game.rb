class Game
  ROUNDS_NUMBER = 3

  def initialize
    @players = []
    @remaining_rounds = ROUNDS_NUMBER
    @winner = nil
  end

  def self.info
    "I'm a game class"
  end

  def add_player(name)
    @players << Player.new(name)
  end
end