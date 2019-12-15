class Player
  attr_accessor :going_up
  attr_reader   :treasures, :is_back, :score

  def initialize(name)
    @name  = name
    @score = 0
    reset
  end

  def reset
    @treasures = 0
    @going_up  = false
    @is_back   = false
  end

  def to_s
    @name
  end

  def save_info(keep_diving, back, treasure)
    @going_up = true if keep_diving == 'false'
    @is_back  = true if back        == 'true'
    save_treasure(treasure)
  end

  def new_score(points)
    @score = points
  end

  private

  def save_treasure(treasure)
    case treasure
    when 'add'    then @treasures += 1
    when 'remove' then remove_treasure
    end
  end

  def remove_treasure
    @treasures -= 1 unless @treasures.zero?
  end
end
