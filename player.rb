class Player
  attr_accessor :going_up
  attr_reader   :treasures, :is_back

  def initialize(name)
    @name  = name
    @score = 0
    reset
  end

  def reset
    @treasures = 2
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

  private

  def save_treasure(treasure)
    case treasure
    when 'none'   then return
    when 'add'    then @treasures += 1
    when 'remove' then @treasures -= 1
    end
  end
end
