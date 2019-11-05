class Round
  MAX_OXYGEN = 25

  attr_accessor :remaining_oxygen

  def initialize(players, index)
    @remaining_oxygen = MAX_OXYGEN
    @next_player = players[index]
    @players = players
    @index = index
    @treasures_taken = 0
  end

  def consumed_oxygen
    MAX_OXYGEN - remaining_oxygen
  end

  def percentage_oxygen
    (( consumed_oxygen.to_f / MAX_OXYGEN ) * 100).to_i
  end

  def reduce_oxygen(player)
    self.remaining_oxygen -= player.treasures
  end
end