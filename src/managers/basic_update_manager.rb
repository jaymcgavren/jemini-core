#Updates all game objects.
class BasicUpdateManager < Jemini::GameObject
  def load
    enable_listeners_for :update, :before_update, :after_update
  end
  
  #Call update method on all game objects that support it.
  #Triggers :before_update, :after_update callbacks.
  def update(delta)
#    delta = 20.0
    return if paused?
    
    notify :before_update, delta
    game_state.manager(:game_object).game_objects.each { |game_object| game_object.update(delta) if game_object.respond_to? :update}
    notify :update, delta
    notify :after_update, delta
  end
  
  def pause
    @paused = true
  end

  def resume
    @paused = false
  end

  def paused?
    @paused
  end
end