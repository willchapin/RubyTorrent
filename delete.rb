class Crap
  
  attr_accessor :state
  
  def set_state(state = nil)
    @state = state || { am_chocking: 1, am_interested: 0, }
  end

  
end