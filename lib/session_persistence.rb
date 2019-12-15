class SessionPersistence
  attr_reader :game

  def initialize(session)
    @session = session
    @game = session[:game]
  end
end