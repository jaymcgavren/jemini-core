require 'tangible'

class BasicPhysicsManager < Gemini::GameObject
  include_class 'net.phys2d.math.Vector2f'
  include_class 'net.phys2d.raw.World'
  include_class 'net.phys2d.raw.strategies.QuadSpaceStrategy'
  has_behavior :RecievesEvents
  
  def load
    @world = World.new(Vector2f.new(0, 0), 10, QuadSpaceStrategy.new(20, 5))
    @game_state.manager(:update).on_update {|delta| @world.step(delta) }
    
    @game_state.manager(:game_object).on_after_add_game_object do |game_object|
      if game_object.kind_of? Tangible
        game_object.add_to_world(@world) 
        game_object.set_tangible_debug_mode(true) if @debug_mode
      end
    end
    
    @game_state.manager(:game_object).on_after_remove_game_object do |game_object|
      game_object.remove_from_world(@world) if game_object.kind_of? Tangible
    end
    
    handle_event :toggle_debug_mode, :toggle_debug_mode
  end
  
  def toggle_debug_mode(message)
    @debug_mode = !@debug_mode
    @game_state.manager(:game_object).game_objects.each do |game_object|
      game_object.set_tangible_debug_mode(@debug_mode) if game_object.kind_of? Tangible
    end
  end
end