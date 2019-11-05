class Player
  attr_accessor :going_up

  def initialize(name)
    @name      = name
    @score     = 0
    @treasures = 0
    @going_up  = false
    @is_back   = false
  end

  def to_s
    @name
  end
end
