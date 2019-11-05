class Round
  MAX_OXYGEN = 25

  def initialize(first_player)
    @remaining_oxygen = MAX_OXYGEN
    @next_player = first_player
    @treasures_taken = 0
  end
end