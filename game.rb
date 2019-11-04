class Game
  ROUNDS_NUMBER = 3

  def initialize
    @players = []
    @remaining_rounds = ROUNDS_NUMBER
    @winner = nil
  end

  def to_s
    "I'm a game object with #{@remaining_rounds} remaining rounds"
  end

end