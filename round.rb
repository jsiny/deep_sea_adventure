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
    ((consumed_oxygen.to_f / MAX_OXYGEN) * 100).to_i
  end

  def reduce_oxygen?(treasures)
    self.remaining_oxygen -= treasures unless treasures.zero?
  end

  def next_id(current_player_id)
    id = current_player_id

    loop do
      id += 1
      id %= 3
      next if @players[id].is_back

      break id
    end
  end
end
