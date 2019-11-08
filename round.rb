class Round
  MAX_OXYGEN = 25

  attr_reader :players, :next_player

  def initialize(players, index)
    @remaining_oxygen = MAX_OXYGEN
    @next_player = players[index]
    @players = players
    @index = index
    @treasures_taken = 0
  end

  def remaining_oxygen
    @remaining_oxygen < 0 ? 0 : @remaining_oxygen
  end

  def consumed_oxygen
    MAX_OXYGEN - remaining_oxygen
  end

  def percentage_oxygen
    ((consumed_oxygen.to_f / MAX_OXYGEN) * 100).to_i
  end

  def reduce_oxygen?(treasures)
    @remaining_oxygen -= treasures unless treasures.zero?
  end

  # Find next player during POST request (player turn)
  def next_id(current_player_id)
    id = current_player_id

    loop do
      id += 1
      id %= @players.size
      next if @players[id].is_back

      break id
    end
  end

  def over?
    remaining_oxygen.zero? || all_back?
  end

  def all_back?
    @players.all?(&:is_back)
  end

  def any_back?
    @players.any?(&:is_back)
  end

  def drowned_players    
    @players.each_with_object({}).with_index do |(player, hash), id|
      next if player.is_back
      hash[player] = id
    end
  end

  def players_back_on_submarine
    @players.each_with_object({}).with_index do |(player, hash), id|
      next unless player.is_back
      hash[player] = id
    end
  end
end
