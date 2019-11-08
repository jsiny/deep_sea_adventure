class Game
  ROUNDS_NUMBER = 3

  attr_accessor :players, :round, :remaining_rounds
  attr_reader   :winner,  :scoreboard

  def initialize
    @players          = []
    @remaining_rounds = ROUNDS_NUMBER
    @winner           = nil
    @scoreboard       = nil
  end

  def add_player(name)
    players << Player.new(name)
  end

  def next_round(next_player_id = 0)
    @round = Round.new(@players, next_player_id)
    @remaining_rounds -= 1
  end

  def compute_scores
    @scoreboard = compute_scoreboard
    @winner     = compute_winner
  end

  private

  def compute_scoreboard
    @players.each_with_object({}) do |player, hash|
      hash[player] = player.score
    end
      .sort_by { |player, score| -score }
  end

  def compute_winner
    scoreboard[0][0]
  end
end
